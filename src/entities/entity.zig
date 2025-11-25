const std = @import("std");
const HexCoord = @import("../world/hex_grid.zig").HexCoord;

/// Unique identifier for entities
pub const EntityId = u32;

/// Entity roles define the primary function/specialization of an entity
pub const EntityRole = enum {
    worker,   // Basic harvesting and building
    combat,   // Fighting and defense
    scout,    // Exploration and reconnaissance
    engineer, // Advanced construction and research
};

/// Core entity structure
pub const Entity = struct {
    id: EntityId,
    position: HexCoord,
    role: EntityRole,
    energy: f32,      // Current energy level (0.0 to max_energy)
    max_energy: f32,  // Maximum energy capacity
    alive: bool,      // Is entity active (for soft deletion)
    script: ?[]const u8, // Optional Lua script code for this entity

    /// Create a new entity with default values
    pub fn init(id: EntityId, position: HexCoord, role: EntityRole) Entity {
        return Entity{
            .id = id,
            .position = position,
            .role = role,
            .energy = getRoleMaxEnergy(role),
            .max_energy = getRoleMaxEnergy(role),
            .alive = true,
            .script = null,
        };
    }

    /// Get the maximum energy for a given role
    fn getRoleMaxEnergy(role: EntityRole) f32 {
        return switch (role) {
            .worker => 100.0,
            .combat => 150.0,
            .scout => 80.0,
            .engineer => 120.0,
        };
    }

    /// Check if entity is alive and has energy
    pub fn isActive(self: *const Entity) bool {
        return self.alive and self.energy > 0.0;
    }

    /// Consume energy (returns true if successful, false if insufficient)
    pub fn consumeEnergy(self: *Entity, amount: f32) bool {
        if (self.energy >= amount) {
            self.energy -= amount;
            return true;
        }
        return false;
    }

    /// Restore energy (capped at max_energy)
    pub fn restoreEnergy(self: *Entity, amount: f32) void {
        self.energy = @min(self.energy + amount, self.max_energy);
    }

    /// Mark entity as dead (soft delete)
    pub fn kill(self: *Entity) void {
        self.alive = false;
        self.energy = 0.0;
    }

    /// Set the Lua script for this entity
    pub fn setScript(self: *Entity, script: ?[]const u8) void {
        self.script = script;
    }

    /// Check if entity has a script
    pub fn hasScript(self: *const Entity) bool {
        return self.script != null;
    }
};

// ============================================================================
// Tests
// ============================================================================

test "Entity.init creates entity with correct defaults" {
    const entity = Entity.init(1, HexCoord{ .q = 0, .r = 0 }, .worker);

    try std.testing.expectEqual(@as(EntityId, 1), entity.id);
    try std.testing.expectEqual(@as(i32, 0), entity.position.q);
    try std.testing.expectEqual(@as(i32, 0), entity.position.r);
    try std.testing.expectEqual(EntityRole.worker, entity.role);
    try std.testing.expectEqual(@as(f32, 100.0), entity.energy);
    try std.testing.expectEqual(@as(f32, 100.0), entity.max_energy);
    try std.testing.expect(entity.alive);
}

test "Entity.init sets different max energy for different roles" {
    const worker = Entity.init(1, HexCoord{ .q = 0, .r = 0 }, .worker);
    const combat = Entity.init(2, HexCoord{ .q = 1, .r = 0 }, .combat);
    const scout = Entity.init(3, HexCoord{ .q = 2, .r = 0 }, .scout);
    const engineer = Entity.init(4, HexCoord{ .q = 3, .r = 0 }, .engineer);

    try std.testing.expectEqual(@as(f32, 100.0), worker.max_energy);
    try std.testing.expectEqual(@as(f32, 150.0), combat.max_energy);
    try std.testing.expectEqual(@as(f32, 80.0), scout.max_energy);
    try std.testing.expectEqual(@as(f32, 120.0), engineer.max_energy);
}

test "Entity.isActive returns true for alive entity with energy" {
    var entity = Entity.init(1, HexCoord{ .q = 0, .r = 0 }, .worker);
    try std.testing.expect(entity.isActive());

    entity.energy = 0.0;
    try std.testing.expect(!entity.isActive());

    entity.energy = 50.0;
    entity.alive = false;
    try std.testing.expect(!entity.isActive());
}

test "Entity.consumeEnergy reduces energy correctly" {
    var entity = Entity.init(1, HexCoord{ .q = 0, .r = 0 }, .worker);

    const success = entity.consumeEnergy(30.0);
    try std.testing.expect(success);
    try std.testing.expectEqual(@as(f32, 70.0), entity.energy);

    const failure = entity.consumeEnergy(100.0);
    try std.testing.expect(!failure);
    try std.testing.expectEqual(@as(f32, 70.0), entity.energy); // Energy unchanged
}

test "Entity.restoreEnergy increases energy correctly" {
    var entity = Entity.init(1, HexCoord{ .q = 0, .r = 0 }, .worker);
    entity.energy = 50.0;

    entity.restoreEnergy(30.0);
    try std.testing.expectEqual(@as(f32, 80.0), entity.energy);

    entity.restoreEnergy(50.0);
    try std.testing.expectEqual(@as(f32, 100.0), entity.energy); // Capped at max
}

test "Entity.kill marks entity as dead and drains energy" {
    var entity = Entity.init(1, HexCoord{ .q = 0, .r = 0 }, .worker);

    entity.kill();
    try std.testing.expect(!entity.alive);
    try std.testing.expectEqual(@as(f32, 0.0), entity.energy);
    try std.testing.expect(!entity.isActive());
}
