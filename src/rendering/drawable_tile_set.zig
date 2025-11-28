const std = @import("std");
const HexCoord = @import("../world/hex_grid.zig").HexCoord;

/// Set of hex coordinates that should have their edges rendered.
/// Used for fog of war, partial map loading, and debug visualization.
pub const DrawableTileSet = struct {
    tiles: std.AutoHashMap(HexCoord, void),
    allocator: std.mem.Allocator,

    /// Initialize an empty drawable tile set
    pub fn init(allocator: std.mem.Allocator) DrawableTileSet {
        return DrawableTileSet{
            .tiles = std.AutoHashMap(HexCoord, void).init(allocator),
            .allocator = allocator,
        };
    }

    /// Cleanup and free all resources
    pub fn deinit(self: *DrawableTileSet) void {
        self.tiles.deinit();
    }

    /// Add a tile coordinate to the drawable set
    /// Adding the same coordinate multiple times is idempotent
    pub fn add(self: *DrawableTileSet, coord: HexCoord) !void {
        try self.tiles.put(coord, {});
    }

    /// Remove a tile coordinate from the drawable set
    /// Removing a non-existent coordinate is a no-op
    pub fn remove(self: *DrawableTileSet, coord: HexCoord) void {
        _ = self.tiles.remove(coord);
    }

    /// Check if a tile coordinate is in the drawable set
    pub fn contains(self: *const DrawableTileSet, coord: HexCoord) bool {
        return self.tiles.contains(coord);
    }

    /// Remove all tiles from the set
    pub fn clear(self: *DrawableTileSet) void {
        self.tiles.clearRetainingCapacity();
    }

    /// Get the number of tiles in the drawable set
    pub fn count(self: *const DrawableTileSet) usize {
        return self.tiles.count();
    }

    /// Get an iterator over the drawable tiles
    pub fn iterator(self: *const DrawableTileSet) std.AutoHashMap(HexCoord, void).KeyIterator {
        return self.tiles.keyIterator();
    }
};

// ============================================================================
// Tests
// ============================================================================

test "DrawableTileSet.init creates empty set" {
    var set = DrawableTileSet.init(std.testing.allocator);
    defer set.deinit();

    try std.testing.expectEqual(@as(usize, 0), set.count());
}

test "DrawableTileSet.add and contains works" {
    var set = DrawableTileSet.init(std.testing.allocator);
    defer set.deinit();

    const coord = HexCoord{ .q = 5, .r = 3 };

    try std.testing.expect(!set.contains(coord));

    try set.add(coord);

    try std.testing.expect(set.contains(coord));
    try std.testing.expectEqual(@as(usize, 1), set.count());
}

test "DrawableTileSet.remove works" {
    var set = DrawableTileSet.init(std.testing.allocator);
    defer set.deinit();

    const coord1 = HexCoord{ .q = 1, .r = 2 };
    const coord2 = HexCoord{ .q = 3, .r = 4 };

    try set.add(coord1);
    try set.add(coord2);
    try std.testing.expectEqual(@as(usize, 2), set.count());

    set.remove(coord1);
    try std.testing.expect(!set.contains(coord1));
    try std.testing.expect(set.contains(coord2));
    try std.testing.expectEqual(@as(usize, 1), set.count());
}

test "DrawableTileSet.clear works" {
    var set = DrawableTileSet.init(std.testing.allocator);
    defer set.deinit();

    try set.add(HexCoord{ .q = 0, .r = 0 });
    try set.add(HexCoord{ .q = 1, .r = 1 });
    try set.add(HexCoord{ .q = 2, .r = 2 });

    try std.testing.expectEqual(@as(usize, 3), set.count());

    set.clear();

    try std.testing.expectEqual(@as(usize, 0), set.count());
    try std.testing.expect(!set.contains(HexCoord{ .q = 0, .r = 0 }));
}

test "DrawableTileSet.count accurate" {
    var set = DrawableTileSet.init(std.testing.allocator);
    defer set.deinit();

    try std.testing.expectEqual(@as(usize, 0), set.count());

    try set.add(HexCoord{ .q = 0, .r = 0 });
    try std.testing.expectEqual(@as(usize, 1), set.count());

    try set.add(HexCoord{ .q = 1, .r = 0 });
    try std.testing.expectEqual(@as(usize, 2), set.count());

    try set.add(HexCoord{ .q = 0, .r = 1 });
    try std.testing.expectEqual(@as(usize, 3), set.count());
}

test "DrawableTileSet.duplicate adds idempotent" {
    var set = DrawableTileSet.init(std.testing.allocator);
    defer set.deinit();

    const coord = HexCoord{ .q = 10, .r = 20 };

    try set.add(coord);
    try std.testing.expectEqual(@as(usize, 1), set.count());

    // Adding the same coordinate again should not increase count
    try set.add(coord);
    try std.testing.expectEqual(@as(usize, 1), set.count());

    try set.add(coord);
    try std.testing.expectEqual(@as(usize, 1), set.count());
}

test "DrawableTileSet.deinit cleanup" {
    // Use testing allocator to detect memory leaks
    var set = DrawableTileSet.init(std.testing.allocator);

    try set.add(HexCoord{ .q = 1, .r = 1 });
    try set.add(HexCoord{ .q = 2, .r = 2 });
    try set.add(HexCoord{ .q = 3, .r = 3 });

    set.deinit();
    // If there's a memory leak, testing allocator will catch it
}

test "DrawableTileSet.large set performance" {
    var set = DrawableTileSet.init(std.testing.allocator);
    defer set.deinit();

    // Add 1000 tiles
    var q: i32 = 0;
    while (q < 100) : (q += 1) {
        var r: i32 = 0;
        while (r < 10) : (r += 1) {
            try set.add(HexCoord{ .q = q, .r = r });
        }
    }

    try std.testing.expectEqual(@as(usize, 1000), set.count());

    // Verify containment
    try std.testing.expect(set.contains(HexCoord{ .q = 50, .r = 5 }));
    try std.testing.expect(!set.contains(HexCoord{ .q = 200, .r = 200 }));
}
