const std = @import("std");
const Entity = @import("entity.zig").Entity;
const EntityId = @import("entity.zig").EntityId;
const EntityRole = @import("entity.zig").EntityRole;
const HexCoord = @import("../world/hex_grid.zig").HexCoord;

/// Manages entity lifecycle and provides query interface
pub const EntityManager = struct {
    allocator: std.mem.Allocator,
    entities: std.ArrayList(Entity),
    next_id: EntityId,
    alive_count: usize,

    /// Initialize the entity manager
    pub fn init(allocator: std.mem.Allocator) EntityManager {
        return EntityManager{
            .allocator = allocator,
            .entities = std.ArrayList(Entity){
                .items = &[_]Entity{},
                .capacity = 0,
            },
            .next_id = 1,
            .alive_count = 0,
        };
    }

    /// Clean up resources
    pub fn deinit(self: *EntityManager) void {
        self.entities.deinit(self.allocator);
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
    }
};

// ============================================================================
// Tests
// ============================================================================

test "EntityManager.init and deinit" {
    const allocator = std.testing.allocator;
    var manager = EntityManager.init(allocator);
    defer manager.deinit();

    try std.testing.expectEqual(@as(EntityId, 1), manager.next_id);
    try std.testing.expectEqual(@as(usize, 0), manager.getAliveCount());
}

test "EntityManager.spawn creates entities with unique IDs" {
    const allocator = std.testing.allocator;
    var manager = EntityManager.init(allocator);
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
    var manager = EntityManager.init(allocator);
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
    var manager = EntityManager.init(allocator);
    defer manager.deinit();

    _ = try manager.spawn(HexCoord{ .q = 0, .r = 0 }, .worker);
    const entity = manager.getEntity(999);

    try std.testing.expect(entity == null);
}

test "EntityManager.destroy marks entity as dead" {
    const allocator = std.testing.allocator;
    var manager = EntityManager.init(allocator);
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
    var manager = EntityManager.init(allocator);
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
    var manager = EntityManager.init(allocator);
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
    var manager = EntityManager.init(allocator);
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
    var manager = EntityManager.init(allocator);
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
