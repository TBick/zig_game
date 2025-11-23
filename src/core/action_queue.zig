/// Action Queue System - Commands entities can issue from Lua scripts
/// Actions are queued during script execution, then processed by the engine

const std = @import("std");
const HexCoord = @import("../world/hex_grid.zig").HexCoord;

/// Actions that entities can perform
pub const EntityAction = union(enum) {
    /// Move toward target position
    move: struct {
        target: HexCoord,
    },

    /// Harvest resource at target position (Phase 3 - stub for now)
    harvest: struct {
        target: HexCoord,
    },

    /// Consume resource from inventory to gain energy (Phase 3 - stub for now)
    consume: struct {
        resource_type: []const u8,
        amount: u32,
    },

    // Future actions (Phase 3+):
    // build: struct { structure_type: []const u8, position: HexCoord },
    // attack: struct { target_entity_id: u32 },
    // transfer: struct { target_entity_id: u32, resource: []const u8, amount: u32 },
    // repair: struct { target_entity_id: u32 },
};

/// Queue of actions for a single entity
/// Each entity can queue multiple actions per tick, but typically only one executes
pub const ActionQueue = struct {
    items: std.ArrayList(EntityAction),
    allocator: std.mem.Allocator,

    /// Create a new action queue
    pub fn init(allocator: std.mem.Allocator) ActionQueue {
        return ActionQueue{
            .items = std.ArrayList(EntityAction).init(allocator),
            .allocator = allocator,
        };
    }

    /// Clean up action queue
    pub fn deinit(self: *ActionQueue) void {
        // Free any string allocations in consume actions
        for (self.items.items) |action| {
            switch (action) {
                .consume => |consume_data| {
                    self.allocator.free(consume_data.resource_type);
                },
                else => {},
            }
        }
        self.items.deinit();
    }

    /// Add an action to the queue
    pub fn add(self: *ActionQueue, action: EntityAction) !void {
        try self.items.append(action);
    }

    /// Clear all queued actions
    pub fn clear(self: *ActionQueue) void {
        // Free any string allocations before clearing
        for (self.items.items) |action| {
            switch (action) {
                .consume => |consume_data| {
                    self.allocator.free(consume_data.resource_type);
                },
                else => {},
            }
        }
        self.items.clearRetainingCapacity();
    }

    /// Check if queue is empty
    pub fn isEmpty(self: *const ActionQueue) bool {
        return self.items.items.len == 0;
    }

    /// Get all queued actions (read-only)
    pub fn getActions(self: *const ActionQueue) []const EntityAction {
        return self.items.items;
    }

    /// Get the number of queued actions
    pub fn count(self: *const ActionQueue) usize {
        return self.items.items.len;
    }
};

// ============================================================================
// Tests
// ============================================================================

test "ActionQueue: init and deinit" {
    var queue = ActionQueue.init(std.testing.allocator);
    defer queue.deinit();

    try std.testing.expect(queue.isEmpty());
    try std.testing.expectEqual(@as(usize, 0), queue.count());
}

test "ActionQueue: add move action" {
    var queue = ActionQueue.init(std.testing.allocator);
    defer queue.deinit();

    const move_action = EntityAction{
        .move = .{ .target = HexCoord{ .q = 5, .r = 3 } },
    };

    try queue.add(move_action);

    try std.testing.expect(!queue.isEmpty());
    try std.testing.expectEqual(@as(usize, 1), queue.count());

    const actions = queue.getActions();
    try std.testing.expectEqual(@as(i32, 5), actions[0].move.target.q);
    try std.testing.expectEqual(@as(i32, 3), actions[0].move.target.r);
}

test "ActionQueue: add harvest action" {
    var queue = ActionQueue.init(std.testing.allocator);
    defer queue.deinit();

    const harvest_action = EntityAction{
        .harvest = .{ .target = HexCoord{ .q = 2, .r = -1 } },
    };

    try queue.add(harvest_action);

    const actions = queue.getActions();
    try std.testing.expectEqual(@as(i32, 2), actions[0].harvest.target.q);
    try std.testing.expectEqual(@as(i32, -1), actions[0].harvest.target.r);
}

test "ActionQueue: add consume action" {
    var queue = ActionQueue.init(std.testing.allocator);
    defer queue.deinit();

    const resource_name = try std.testing.allocator.dupe(u8, "energy_cell");

    const consume_action = EntityAction{
        .consume = .{
            .resource_type = resource_name,
            .amount = 5,
        },
    };

    try queue.add(consume_action);

    const actions = queue.getActions();
    try std.testing.expectEqualStrings("energy_cell", actions[0].consume.resource_type);
    try std.testing.expectEqual(@as(u32, 5), actions[0].consume.amount);
}

test "ActionQueue: add multiple actions" {
    var queue = ActionQueue.init(std.testing.allocator);
    defer queue.deinit();

    try queue.add(EntityAction{ .move = .{ .target = HexCoord{ .q = 1, .r = 0 } } });
    try queue.add(EntityAction{ .harvest = .{ .target = HexCoord{ .q = 2, .r = 0 } } });

    try std.testing.expectEqual(@as(usize, 2), queue.count());

    const actions = queue.getActions();
    try std.testing.expectEqual(@as(i32, 1), actions[0].move.target.q);
    try std.testing.expectEqual(@as(i32, 2), actions[1].harvest.target.q);
}

test "ActionQueue: clear actions" {
    var queue = ActionQueue.init(std.testing.allocator);
    defer queue.deinit();

    try queue.add(EntityAction{ .move = .{ .target = HexCoord{ .q = 1, .r = 0 } } });
    try queue.add(EntityAction{ .harvest = .{ .target = HexCoord{ .q = 2, .r = 0 } } });

    try std.testing.expectEqual(@as(usize, 2), queue.count());

    queue.clear();

    try std.testing.expect(queue.isEmpty());
    try std.testing.expectEqual(@as(usize, 0), queue.count());
}

test "ActionQueue: clear with consume action frees memory" {
    var queue = ActionQueue.init(std.testing.allocator);
    defer queue.deinit();

    const resource_name = try std.testing.allocator.dupe(u8, "minerals");
    try queue.add(EntityAction{ .consume = .{ .resource_type = resource_name, .amount = 10 } });

    try std.testing.expectEqual(@as(usize, 1), queue.count());

    queue.clear(); // Should free the resource_type string

    try std.testing.expect(queue.isEmpty());
}
