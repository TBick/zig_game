const std = @import("std");
const Entity = @import("entity.zig").Entity;
const EntityId = @import("entity.zig").EntityId;
const EntityRole = @import("entity.zig").EntityRole;
const HexCoord = @import("../world/hex_grid.zig").HexCoord;
const LuaVM = @import("../scripting/lua_vm.zig").LuaVM;
const ActionQueue = @import("../core/action_queue.zig").ActionQueue;
const EntityAction = @import("../core/action_queue.zig").EntityAction;
const entity_api = @import("../scripting/entity_api.zig");
const world_api = @import("../scripting/world_api.zig");

/// Manages entity lifecycle and provides query interface
pub const EntityManager = struct {
    allocator: std.mem.Allocator,
    entities: std.ArrayList(Entity),
    next_id: EntityId,
    alive_count: usize,
    lua_vm: LuaVM,
    // Maps entity ID to Lua registry reference for memory table persistence
    memory_refs: std.AutoHashMap(EntityId, i32),

    /// Initialize the entity manager
    pub fn init(allocator: std.mem.Allocator) !EntityManager {
        var lua_vm = try LuaVM.init(allocator);
        errdefer lua_vm.deinit();

        return EntityManager{
            .allocator = allocator,
            .entities = std.ArrayList(Entity){
                .items = &[_]Entity{},
                .capacity = 0,
            },
            .next_id = 1,
            .alive_count = 0,
            .lua_vm = lua_vm,
            .memory_refs = std.AutoHashMap(EntityId, i32).init(allocator),
        };
    }

    /// Clean up resources
    pub fn deinit(self: *EntityManager) void {
        self.entities.deinit(self.allocator);
        self.lua_vm.deinit();
        self.memory_refs.deinit();
    }

    /// Spawn a new entity at the given position with the given role
    pub fn spawn(self: *EntityManager, position: HexCoord, role: EntityRole) !EntityId {
        const id = self.next_id;
        self.next_id += 1;

        const entity = Entity.init(id, position, role);
        try self.entities.append(self.allocator, entity);
        self.alive_count += 1;

        return id;
    }

    /// Get an entity by ID (returns null if not found or dead)
    pub fn getEntity(self: *EntityManager, id: EntityId) ?*Entity {
        for (self.entities.items) |*entity| {
            if (entity.id == id and entity.alive) {
                return entity;
            }
        }
        return null;
    }

    /// Get an entity by ID (including dead entities)
    pub fn getEntityIncludingDead(self: *EntityManager, id: EntityId) ?*Entity {
        for (self.entities.items) |*entity| {
            if (entity.id == id) {
                return entity;
            }
        }
        return null;
    }

    /// Destroy an entity by ID (soft delete - marks as not alive)
    pub fn destroy(self: *EntityManager, id: EntityId) bool {
        if (self.getEntity(id)) |entity| {
            entity.kill();
            self.alive_count -= 1;
            return true;
        }
        return false;
    }

    /// Get all alive entities
    pub fn getAliveEntities(self: *EntityManager) []Entity {
        // Note: Returns slice containing both alive and dead entities
        // Caller should check entity.alive or use iterator
        return self.entities.items;
    }

    /// Get count of alive entities
    pub fn getAliveCount(self: *const EntityManager) usize {
        return self.alive_count;
    }

    /// Get total entity count (including dead)
    pub fn getTotalCount(self: *const EntityManager) usize {
        return self.entities.items.len;
    }

    /// Get all entities at a specific position
    pub fn getEntitiesAt(self: *EntityManager, position: HexCoord, buffer: []EntityId) usize {
        var count: usize = 0;
        for (self.entities.items) |*entity| {
            if (entity.alive and entity.position.eq(position)) {
                if (count < buffer.len) {
                    buffer[count] = entity.id;
                    count += 1;
                }
            }
        }
        return count;
    }

    /// Get all entities of a specific role
    pub fn getEntitiesByRole(self: *EntityManager, role: EntityRole, buffer: []EntityId) usize {
        var count: usize = 0;
        for (self.entities.items) |*entity| {
            if (entity.alive and entity.role == role) {
                if (count < buffer.len) {
                    buffer[count] = entity.id;
                    count += 1;
                }
            }
        }
        return count;
    }

    /// Compact the entity list by removing dead entities (garbage collection)
    pub fn compact(self: *EntityManager) void {
        var write_index: usize = 0;
        var read_index: usize = 0;

        while (read_index < self.entities.items.len) {
            if (self.entities.items[read_index].alive) {
                if (write_index != read_index) {
                    self.entities.items[write_index] = self.entities.items[read_index];
                }
                write_index += 1;
            }
            read_index += 1;
        }

        self.entities.shrinkRetainingCapacity(write_index);
    }

    /// Clear all entities
    pub fn clear(self: *EntityManager) void {
        self.entities.clearRetainingCapacity();
        self.next_id = 1;
        self.alive_count = 0;
        self.memory_refs.clearRetainingCapacity();
    }

    /// Process a game tick - execute all entity scripts and process actions
    /// Requires a HexGrid pointer for world API context
    pub fn processTick(self: *EntityManager, grid: anytype) !void {
        // Execute all entity scripts
        for (self.entities.items) |*entity| {
            if (entity.alive and entity.hasScript()) {
                try self.executeEntityScript(entity, grid);
            }
        }
    }

    /// Execute a single entity's Lua script
    /// Sets up contexts (entity, action queue, world), runs script, processes actions
    fn executeEntityScript(self: *EntityManager, entity: *Entity, grid: anytype) !void {
        if (entity.script == null) return;

        // Create action queue for this entity
        var action_queue = ActionQueue.init(self.allocator);
        defer action_queue.deinit();

        // Set up Lua contexts
        entity_api.setEntityContext(self.lua_vm.L.?, entity);
        entity_api.setActionQueueContext(self.lua_vm.L.?, &action_queue);
        world_api.setGridContext(self.lua_vm.L.?, grid);
        world_api.setEntityManagerContext(self.lua_vm.L.?, self);

        // Register APIs (safe to call multiple times)
        entity_api.registerEntityAPI(self.lua_vm.L.?);
        world_api.registerWorldAPI(self.lua_vm.L.?);

        // Restore memory table for this entity
        self.restoreMemoryTable(entity.id);

        // Execute the script
        self.lua_vm.doString(entity.script.?) catch |err| {
            // Log error but don't crash - continue processing other entities
            std.debug.print("Entity {d} script error: {any}\n", .{ entity.id, err });
            return;
        };

        // Save memory table for next tick
        try self.saveMemoryTable(entity.id);

        // Process queued actions
        self.processEntityActions(entity, action_queue.getActions());
    }

    /// Restore the memory table for an entity from Lua registry
    fn restoreMemoryTable(self: *EntityManager, entity_id: EntityId) void {
        const L = self.lua_vm.L.?;
        const lua_c = @import("../scripting/lua_c.zig");

        if (self.memory_refs.get(entity_id)) |registry_ref| {
            // Get the table from registry and set as global 'memory'
            _ = lua_c.rawGetI(L, lua_c.LUA_REGISTRYINDEX, registry_ref);
            lua_c.setGlobal(L, "memory");
        } else {
            // First time - create empty memory table
            lua_c.createTable(L, 0, 0);
            lua_c.setGlobal(L, "memory");
        }
    }

    /// Save the memory table for an entity to Lua registry
    fn saveMemoryTable(self: *EntityManager, entity_id: EntityId) !void {
        const L = self.lua_vm.L.?;
        const lua_c = @import("../scripting/lua_c.zig");

        // Get the 'memory' global
        _ = lua_c.getGlobal(L, "memory");

        // If this entity already has a ref, unreference the old table
        if (self.memory_refs.get(entity_id)) |old_ref| {
            lua_c.unref(L, lua_c.LUA_REGISTRYINDEX, old_ref);
        }

        // Store the new memory table in registry and save the reference
        const registry_ref = lua_c.ref(L, lua_c.LUA_REGISTRYINDEX);
        try self.memory_refs.put(entity_id, registry_ref);
    }

    /// Process queued actions for an entity
    fn processEntityActions(self: *EntityManager, entity: *Entity, actions: []const EntityAction) void {
        _ = self;
        for (actions) |action| {
            switch (action) {
                .move => |move_data| {
                    // Simple move: jump directly to target (Phase 3 will add pathfinding)
                    entity.position = move_data.target;
                    // Moving costs energy
                    _ = entity.consumeEnergy(5.0);
                },
                .harvest => {
                    // Phase 3: Implement resource harvesting
                    // For now, just consume energy
                    _ = entity.consumeEnergy(10.0);
                },
                .consume => {
                    // Phase 3: Implement resource consumption
                    // For now, do nothing (resource system doesn't exist yet)
                },
            }
        }
    }
};

// ============================================================================
// Tests
// ============================================================================

test "EntityManager.init and deinit" {
    const allocator = std.testing.allocator;
    var manager = try EntityManager.init(allocator);
    defer manager.deinit();

    try std.testing.expectEqual(@as(EntityId, 1), manager.next_id);
    try std.testing.expectEqual(@as(usize, 0), manager.getAliveCount());
}

test "EntityManager.spawn creates entities with unique IDs" {
    const allocator = std.testing.allocator;
    var manager = try EntityManager.init(allocator);
    defer manager.deinit();

    const id1 = try manager.spawn(HexCoord{ .q = 0, .r = 0 }, .worker);
    const id2 = try manager.spawn(HexCoord{ .q = 1, .r = 0 }, .combat);
    const id3 = try manager.spawn(HexCoord{ .q = 2, .r = 0 }, .scout);

    try std.testing.expectEqual(@as(EntityId, 1), id1);
    try std.testing.expectEqual(@as(EntityId, 2), id2);
    try std.testing.expectEqual(@as(EntityId, 3), id3);
    try std.testing.expectEqual(@as(usize, 3), manager.getAliveCount());
}

test "EntityManager.getEntity retrieves correct entity" {
    const allocator = std.testing.allocator;
    var manager = try EntityManager.init(allocator);
    defer manager.deinit();

    const id = try manager.spawn(HexCoord{ .q = 5, .r = 7 }, .engineer);
    const entity = manager.getEntity(id);

    try std.testing.expect(entity != null);
    try std.testing.expectEqual(id, entity.?.id);
    try std.testing.expectEqual(@as(i32, 5), entity.?.position.q);
    try std.testing.expectEqual(@as(i32, 7), entity.?.position.r);
    try std.testing.expectEqual(EntityRole.engineer, entity.?.role);
}

test "EntityManager.getEntity returns null for non-existent ID" {
    const allocator = std.testing.allocator;
    var manager = try EntityManager.init(allocator);
    defer manager.deinit();

    _ = try manager.spawn(HexCoord{ .q = 0, .r = 0 }, .worker);
    const entity = manager.getEntity(999);

    try std.testing.expect(entity == null);
}

test "EntityManager.destroy marks entity as dead" {
    const allocator = std.testing.allocator;
    var manager = try EntityManager.init(allocator);
    defer manager.deinit();

    const id = try manager.spawn(HexCoord{ .q = 0, .r = 0 }, .worker);
    try std.testing.expectEqual(@as(usize, 1), manager.getAliveCount());

    const destroyed = manager.destroy(id);
    try std.testing.expect(destroyed);
    try std.testing.expectEqual(@as(usize, 0), manager.getAliveCount());

    const entity = manager.getEntity(id);
    try std.testing.expect(entity == null); // Dead entities not returned by getEntity

    const dead_entity = manager.getEntityIncludingDead(id);
    try std.testing.expect(dead_entity != null);
    try std.testing.expect(!dead_entity.?.alive);
}

test "EntityManager.getEntitiesAt finds entities at position" {
    const allocator = std.testing.allocator;
    var manager = try EntityManager.init(allocator);
    defer manager.deinit();

    const pos = HexCoord{ .q = 5, .r = 5 };
    const id1 = try manager.spawn(pos, .worker);
    const id2 = try manager.spawn(pos, .combat);
    _ = try manager.spawn(HexCoord{ .q = 6, .r = 5 }, .scout);

    var buffer: [10]EntityId = undefined;
    const count = manager.getEntitiesAt(pos, &buffer);

    try std.testing.expectEqual(@as(usize, 2), count);
    try std.testing.expect((buffer[0] == id1 and buffer[1] == id2) or
        (buffer[0] == id2 and buffer[1] == id1));
}

test "EntityManager.getEntitiesByRole finds entities by role" {
    const allocator = std.testing.allocator;
    var manager = try EntityManager.init(allocator);
    defer manager.deinit();

    const id1 = try manager.spawn(HexCoord{ .q = 0, .r = 0 }, .worker);
    const id2 = try manager.spawn(HexCoord{ .q = 1, .r = 0 }, .worker);
    _ = try manager.spawn(HexCoord{ .q = 2, .r = 0 }, .combat);
    _ = try manager.spawn(HexCoord{ .q = 3, .r = 0 }, .scout);

    var buffer: [10]EntityId = undefined;
    const count = manager.getEntitiesByRole(.worker, &buffer);

    try std.testing.expectEqual(@as(usize, 2), count);
    try std.testing.expect((buffer[0] == id1 and buffer[1] == id2) or
        (buffer[0] == id2 and buffer[1] == id1));
}

test "EntityManager.compact removes dead entities" {
    const allocator = std.testing.allocator;
    var manager = try EntityManager.init(allocator);
    defer manager.deinit();

    const id1 = try manager.spawn(HexCoord{ .q = 0, .r = 0 }, .worker);
    const id2 = try manager.spawn(HexCoord{ .q = 1, .r = 0 }, .combat);
    const id3 = try manager.spawn(HexCoord{ .q = 2, .r = 0 }, .scout);

    _ = manager.destroy(id2);

    try std.testing.expectEqual(@as(usize, 3), manager.getTotalCount());
    try std.testing.expectEqual(@as(usize, 2), manager.getAliveCount());

    manager.compact();

    try std.testing.expectEqual(@as(usize, 2), manager.getTotalCount());
    try std.testing.expectEqual(@as(usize, 2), manager.getAliveCount());

    try std.testing.expect(manager.getEntity(id1) != null);
    try std.testing.expect(manager.getEntity(id2) == null);
    try std.testing.expect(manager.getEntity(id3) != null);
}

test "EntityManager.clear removes all entities" {
    const allocator = std.testing.allocator;
    var manager = try EntityManager.init(allocator);
    defer manager.deinit();

    _ = try manager.spawn(HexCoord{ .q = 0, .r = 0 }, .worker);
    _ = try manager.spawn(HexCoord{ .q = 1, .r = 0 }, .combat);
    _ = try manager.spawn(HexCoord{ .q = 2, .r = 0 }, .scout);

    try std.testing.expectEqual(@as(usize, 3), manager.getAliveCount());

    manager.clear();

    try std.testing.expectEqual(@as(usize, 0), manager.getAliveCount());
    try std.testing.expectEqual(@as(usize, 0), manager.getTotalCount());
    try std.testing.expectEqual(@as(EntityId, 1), manager.next_id);
}

test "EntityManager.processTick executes entity scripts" {
    const allocator = std.testing.allocator;
    const HexGrid = @import("../world/hex_grid.zig").HexGrid;

    var manager = try EntityManager.init(allocator);
    defer manager.deinit();

    var grid = HexGrid.init(allocator);
    defer grid.deinit();

    // Spawn entity with a simple script that sets a global
    const id = try manager.spawn(HexCoord{ .q = 0, .r = 0 }, .worker);
    const entity = manager.getEntity(id).?;
    entity.setScript("test_value = 42");

    // Process tick - should execute script
    try manager.processTick(&grid);

    // Verify script executed by checking global
    const result = try manager.lua_vm.getGlobalNumber("test_value");
    try std.testing.expectEqual(@as(f64, 42.0), result);
}

test "EntityManager.processTick handles move actions" {
    const allocator = std.testing.allocator;
    const HexGrid = @import("../world/hex_grid.zig").HexGrid;

    var manager = try EntityManager.init(allocator);
    defer manager.deinit();

    var grid = HexGrid.init(allocator);
    defer grid.deinit();

    // Spawn entity with movement script
    const id = try manager.spawn(HexCoord{ .q = 0, .r = 0 }, .worker);
    const entity = manager.getEntity(id).?;
    entity.setScript("entity.moveTo({q=5, r=3})");

    const initial_energy = entity.energy;

    // Process tick - should move entity
    try manager.processTick(&grid);

    // Verify entity moved and energy consumed
    try std.testing.expectEqual(@as(i32, 5), entity.position.q);
    try std.testing.expectEqual(@as(i32, 3), entity.position.r);
    try std.testing.expect(entity.energy < initial_energy);
}

test "EntityManager.processTick memory persistence" {
    const allocator = std.testing.allocator;
    const HexGrid = @import("../world/hex_grid.zig").HexGrid;

    var manager = try EntityManager.init(allocator);
    defer manager.deinit();

    var grid = HexGrid.init(allocator);
    defer grid.deinit();

    // Spawn entity with script that uses memory
    const id = try manager.spawn(HexCoord{ .q = 0, .r = 0 }, .worker);
    const entity = manager.getEntity(id).?;
    entity.setScript(
        \\if memory.count == nil then
        \\  memory.count = 1
        \\else
        \\  memory.count = memory.count + 1
        \\end
        \\tick_count = memory.count
    );

    // First tick - should set memory.count = 1
    try manager.processTick(&grid);
    var result = try manager.lua_vm.getGlobalNumber("tick_count");
    try std.testing.expectEqual(@as(f64, 1.0), result);

    // Second tick - should increment to 2
    try manager.processTick(&grid);
    result = try manager.lua_vm.getGlobalNumber("tick_count");
    try std.testing.expectEqual(@as(f64, 2.0), result);

    // Third tick - should increment to 3
    try manager.processTick(&grid);
    result = try manager.lua_vm.getGlobalNumber("tick_count");
    try std.testing.expectEqual(@as(f64, 3.0), result);
}

test "EntityManager.processTick handles script errors gracefully" {
    const allocator = std.testing.allocator;
    const HexGrid = @import("../world/hex_grid.zig").HexGrid;

    var manager = try EntityManager.init(allocator);
    defer manager.deinit();

    var grid = HexGrid.init(allocator);
    defer grid.deinit();

    // Spawn two entities - one with broken script, one with working script
    const id1 = try manager.spawn(HexCoord{ .q = 0, .r = 0 }, .worker);
    const entity1 = manager.getEntity(id1).?;
    entity1.setScript("this is invalid lua syntax!");

    const id2 = try manager.spawn(HexCoord{ .q = 1, .r = 0 }, .combat);
    const entity2 = manager.getEntity(id2).?;
    entity2.setScript("success = 1.0");

    // Process tick - should continue despite error in entity1's script
    try manager.processTick(&grid);

    // Verify entity2's script executed successfully
    const result = try manager.lua_vm.getGlobalNumber("success");
    try std.testing.expectEqual(@as(f64, 1.0), result);
}

test "EntityManager.processTick processes multiple entities" {
    const allocator = std.testing.allocator;
    const HexGrid = @import("../world/hex_grid.zig").HexGrid;

    var manager = try EntityManager.init(allocator);
    defer manager.deinit();

    var grid = HexGrid.init(allocator);
    defer grid.deinit();

    // Spawn 3 entities with different scripts
    const id1 = try manager.spawn(HexCoord{ .q = 0, .r = 0 }, .worker);
    manager.getEntity(id1).?.setScript("entity.moveTo({q=1, r=0})");

    const id2 = try manager.spawn(HexCoord{ .q = 5, .r = 5 }, .combat);
    manager.getEntity(id2).?.setScript("entity.moveTo({q=10, r=10})");

    const id3 = try manager.spawn(HexCoord{ .q = -3, .r = 2 }, .scout);
    manager.getEntity(id3).?.setScript("entity.moveTo({q=0, r=0})");

    // Process tick - all should execute
    try manager.processTick(&grid);

    // Verify all entities moved
    const entity1 = manager.getEntity(id1).?;
    try std.testing.expectEqual(@as(i32, 1), entity1.position.q);
    try std.testing.expectEqual(@as(i32, 0), entity1.position.r);

    const entity2 = manager.getEntity(id2).?;
    try std.testing.expectEqual(@as(i32, 10), entity2.position.q);
    try std.testing.expectEqual(@as(i32, 10), entity2.position.r);

    const entity3 = manager.getEntity(id3).?;
    try std.testing.expectEqual(@as(i32, 0), entity3.position.q);
    try std.testing.expectEqual(@as(i32, 0), entity3.position.r);
}
