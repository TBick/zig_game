const std = @import("std");

/// Axial coordinate system for hexagons
/// Uses q (column) and r (row) coordinates
/// See: https://www.redblobgames.com/grids/hexagons/
pub const HexCoord = struct {
    q: i32, // Column (along the horizontal axis)
    r: i32, // Row (along the diagonal axis)

    pub fn init(q: i32, r: i32) HexCoord {
        return HexCoord{ .q = q, .r = r };
    }

    /// Get the s coordinate (derived from q and r)
    /// In cube coordinates: q + r + s = 0
    pub fn s(self: HexCoord) i32 {
        return -self.q - self.r;
    }

    /// Check if two coordinates are equal
    pub fn eql(self: HexCoord, other: HexCoord) bool {
        return self.q == other.q and self.r == other.r;
    }

    /// Add two hex coordinates
    pub fn add(self: HexCoord, other: HexCoord) HexCoord {
        return HexCoord{
            .q = self.q + other.q,
            .r = self.r + other.r,
        };
    }

    /// Subtract two hex coordinates
    pub fn sub(self: HexCoord, other: HexCoord) HexCoord {
        return HexCoord{
            .q = self.q - other.q,
            .r = self.r - other.r,
        };
    }

    /// Multiply hex coordinate by a scalar
    pub fn scale(self: HexCoord, k: i32) HexCoord {
        return HexCoord{
            .q = self.q * k,
            .r = self.r * k,
        };
    }

    /// Get Manhattan distance between two hex coordinates
    pub fn distance(self: HexCoord, other: HexCoord) u32 {
        const diff = self.sub(other);
        const sum: u32 = @intCast(@abs(diff.q) + @abs(diff.r) + @abs(diff.s()));
        return @divTrunc(sum, 2);
    }

    /// Check if two hex coordinates are equal
    pub fn eq(self: HexCoord, other: HexCoord) bool {
        return self.q == other.q and self.r == other.r;
    }

    /// Create HexCoord from floating point coordinates using cube rounding
    /// This is needed for converting pixel positions back to hex coordinates
    /// Uses the cube coordinate rounding algorithm from redblobgames
    pub fn fromFloat(q_float: f32, r_float: f32) HexCoord {
        const s_float = -q_float - r_float;

        var q_round = @round(q_float);
        var r_round = @round(r_float);
        const s_round = @round(s_float);

        const q_diff = @abs(q_round - q_float);
        const r_diff = @abs(r_round - r_float);
        const s_diff = @abs(s_round - s_float);

        // Reset the component with the largest difference
        if (q_diff > r_diff and q_diff > s_diff) {
            q_round = -r_round - s_round;
        } else if (r_diff > s_diff) {
            r_round = -q_round - s_round;
        }
        // else: s_round had largest diff, but we don't store s, so q and r are correct

        return HexCoord{
            .q = @intFromFloat(q_round),
            .r = @intFromFloat(r_round),
        };
    }

    /// Direction vectors for the 6 neighbors (flat-top hexagons)
    const directions = [6]HexCoord{
        HexCoord{ .q = 1, .r = 0 },  // East
        HexCoord{ .q = 1, .r = -1 }, // Northeast
        HexCoord{ .q = 0, .r = -1 }, // Northwest
        HexCoord{ .q = -1, .r = 0 }, // West
        HexCoord{ .q = -1, .r = 1 }, // Southwest
        HexCoord{ .q = 0, .r = 1 },  // Southeast
    };

    /// Get neighbor in a given direction (0-5)
    pub fn neighbor(self: HexCoord, direction: u3) HexCoord {
        return self.add(directions[direction]);
    }

    /// Get all 6 neighbors
    pub fn neighbors(self: HexCoord) [6]HexCoord {
        var result: [6]HexCoord = undefined;
        for (0..6) |i| {
            result[i] = self.neighbor(@intCast(i));
        }
        return result;
    }
};

/// A single hex tile in the world
pub const Tile = struct {
    coord: HexCoord,
    // Future: terrain type, resources, structures, etc.
};

/// The hex grid world
pub const HexGrid = struct {
    tiles: std.AutoHashMap(HexCoord, Tile),
    allocator: std.mem.Allocator,

    /// Initialize an empty hex grid
    pub fn init(allocator: std.mem.Allocator) HexGrid {
        return HexGrid{
            .tiles = std.AutoHashMap(HexCoord, Tile).init(allocator),
            .allocator = allocator,
        };
    }

    /// Clean up the grid
    pub fn deinit(self: *HexGrid) void {
        self.tiles.deinit();
    }

    /// Add a tile to the grid
    pub fn setTile(self: *HexGrid, coord: HexCoord) !void {
        const tile = Tile{ .coord = coord };
        try self.tiles.put(coord, tile);
    }

    /// Get a tile from the grid (returns null if not found)
    pub fn getTile(self: *HexGrid, coord: HexCoord) ?Tile {
        return self.tiles.get(coord);
    }

    /// Check if a tile exists at the given coordinate
    pub fn hasTile(self: *HexGrid, coord: HexCoord) bool {
        return self.tiles.contains(coord);
    }

    /// Remove a tile from the grid
    pub fn removeTile(self: *HexGrid, coord: HexCoord) void {
        _ = self.tiles.remove(coord);
    }

    /// Get the number of tiles in the grid
    pub fn count(self: *HexGrid) usize {
        return self.tiles.count();
    }

    /// Create a rectangular region of hex tiles
    pub fn createRect(self: *HexGrid, width: i32, height: i32) !void {
        var q: i32 = 0;
        while (q < width) : (q += 1) {
            var r: i32 = 0;
            while (r < height) : (r += 1) {
                const coord = HexCoord.init(q, r);
                try self.setTile(coord);
            }
        }
    }
};

// ============================================================================
// Tests
// ============================================================================

test "HexCoord initialization" {
    const coord = HexCoord.init(3, 4);
    try std.testing.expectEqual(@as(i32, 3), coord.q);
    try std.testing.expectEqual(@as(i32, 4), coord.r);
    try std.testing.expectEqual(@as(i32, -7), coord.s());
}

test "HexCoord equality" {
    const a = HexCoord.init(1, 2);
    const b = HexCoord.init(1, 2);
    const c = HexCoord.init(2, 1);
    try std.testing.expect(a.eql(b));
    try std.testing.expect(!a.eql(c));
}

test "HexCoord arithmetic" {
    const a = HexCoord.init(3, 4);
    const b = HexCoord.init(1, 2);

    const sum = a.add(b);
    try std.testing.expectEqual(@as(i32, 4), sum.q);
    try std.testing.expectEqual(@as(i32, 6), sum.r);

    const diff = a.sub(b);
    try std.testing.expectEqual(@as(i32, 2), diff.q);
    try std.testing.expectEqual(@as(i32, 2), diff.r);

    const scaled = a.scale(2);
    try std.testing.expectEqual(@as(i32, 6), scaled.q);
    try std.testing.expectEqual(@as(i32, 8), scaled.r);
}

test "HexCoord distance" {
    const a = HexCoord.init(0, 0);
    const b = HexCoord.init(3, 0);
    const c = HexCoord.init(0, 3);
    const d = HexCoord.init(1, 1);

    try std.testing.expectEqual(@as(u32, 0), a.distance(a));
    try std.testing.expectEqual(@as(u32, 3), a.distance(b));
    try std.testing.expectEqual(@as(u32, 3), a.distance(c));
    try std.testing.expectEqual(@as(u32, 2), a.distance(d));
}

test "HexCoord neighbors" {
    const center = HexCoord.init(5, 7);

    // Test individual neighbors
    try std.testing.expect(center.neighbor(0).eql(HexCoord.init(6, 7)));
    try std.testing.expect(center.neighbor(1).eql(HexCoord.init(6, 6)));
    try std.testing.expect(center.neighbor(2).eql(HexCoord.init(5, 6)));
    try std.testing.expect(center.neighbor(3).eql(HexCoord.init(4, 7)));
    try std.testing.expect(center.neighbor(4).eql(HexCoord.init(4, 8)));
    try std.testing.expect(center.neighbor(5).eql(HexCoord.init(5, 8)));

    // Test all neighbors at once
    const all_neighbors = center.neighbors();
    try std.testing.expectEqual(@as(usize, 6), all_neighbors.len);
}

test "HexGrid basic operations" {
    const allocator = std.testing.allocator;
    var grid = HexGrid.init(allocator);
    defer grid.deinit();

    // Grid starts empty
    try std.testing.expectEqual(@as(usize, 0), grid.count());

    // Add a tile
    const coord = HexCoord.init(0, 0);
    try grid.setTile(coord);
    try std.testing.expectEqual(@as(usize, 1), grid.count());
    try std.testing.expect(grid.hasTile(coord));

    // Get the tile
    const tile = grid.getTile(coord);
    try std.testing.expect(tile != null);
    try std.testing.expect(tile.?.coord.eql(coord));

    // Remove the tile
    grid.removeTile(coord);
    try std.testing.expectEqual(@as(usize, 0), grid.count());
    try std.testing.expect(!grid.hasTile(coord));
}

test "HexGrid rectangular region" {
    const allocator = std.testing.allocator;
    var grid = HexGrid.init(allocator);
    defer grid.deinit();

    // Create 5x3 rect
    try grid.createRect(5, 3);
    try std.testing.expectEqual(@as(usize, 15), grid.count());

    // Verify corners exist
    try std.testing.expect(grid.hasTile(HexCoord.init(0, 0)));
    try std.testing.expect(grid.hasTile(HexCoord.init(4, 0)));
    try std.testing.expect(grid.hasTile(HexCoord.init(0, 2)));
    try std.testing.expect(grid.hasTile(HexCoord.init(4, 2)));

    // Verify outside doesn't exist
    try std.testing.expect(!grid.hasTile(HexCoord.init(5, 0)));
    try std.testing.expect(!grid.hasTile(HexCoord.init(0, 3)));
}

test "HexCoord.s() calculates cube coordinate correctly" {
    const coord1 = HexCoord.init(2, 3);
    try std.testing.expectEqual(@as(i32, -5), coord1.s());

    const coord2 = HexCoord.init(-2, -3);
    try std.testing.expectEqual(@as(i32, 5), coord2.s());

    const coord3 = HexCoord.init(0, 0);
    try std.testing.expectEqual(@as(i32, 0), coord3.s());

    // Verify cube coordinate invariant: q + r + s = 0
    try std.testing.expectEqual(@as(i32, 0), coord1.q + coord1.r + coord1.s());
    try std.testing.expectEqual(@as(i32, 0), coord2.q + coord2.r + coord2.s());
}

test "HexCoord.eq() is equivalent to eql()" {
    const a = HexCoord.init(5, 7);
    const b = HexCoord.init(5, 7);
    const c = HexCoord.init(5, 8);

    try std.testing.expect(a.eq(b));
    try std.testing.expect(a.eql(b));
    try std.testing.expect(!a.eq(c));
    try std.testing.expect(!a.eql(c));
}

test "HexCoord with negative coordinates" {
    const neg_coord = HexCoord.init(-5, -3);
    try std.testing.expectEqual(@as(i32, -5), neg_coord.q);
    try std.testing.expectEqual(@as(i32, -3), neg_coord.r);
    try std.testing.expectEqual(@as(i32, 8), neg_coord.s());

    const mixed = HexCoord.init(-2, 5);
    try std.testing.expectEqual(@as(i32, -2), mixed.q);
    try std.testing.expectEqual(@as(i32, 5), mixed.r);
    try std.testing.expectEqual(@as(i32, -3), mixed.s());
}

test "HexCoord arithmetic with negative values" {
    const a = HexCoord.init(-3, 2);
    const b = HexCoord.init(5, -1);

    const sum = a.add(b);
    try std.testing.expectEqual(@as(i32, 2), sum.q);
    try std.testing.expectEqual(@as(i32, 1), sum.r);

    const diff = a.sub(b);
    try std.testing.expectEqual(@as(i32, -8), diff.q);
    try std.testing.expectEqual(@as(i32, 3), diff.r);

    const scaled = a.scale(-2);
    try std.testing.expectEqual(@as(i32, 6), scaled.q);
    try std.testing.expectEqual(@as(i32, -4), scaled.r);
}

test "HexCoord distance with negative coordinates" {
    const origin = HexCoord.init(0, 0);
    const neg1 = HexCoord.init(-3, 0);
    const neg2 = HexCoord.init(0, -3);
    const neg3 = HexCoord.init(-2, -2);

    try std.testing.expectEqual(@as(u32, 3), origin.distance(neg1));
    try std.testing.expectEqual(@as(u32, 3), origin.distance(neg2));
    try std.testing.expectEqual(@as(u32, 4), origin.distance(neg3));

    // Distance should be symmetric
    try std.testing.expectEqual(origin.distance(neg1), neg1.distance(origin));
}

test "HexCoord scale with zero" {
    const coord = HexCoord.init(5, 7);
    const scaled = coord.scale(0);
    try std.testing.expectEqual(@as(i32, 0), scaled.q);
    try std.testing.expectEqual(@as(i32, 0), scaled.r);
}

test "HexCoord neighbor wraps around all 6 directions" {
    const center = HexCoord.init(0, 0);

    // Test all 6 directions (0-5)
    const n0 = center.neighbor(0);
    try std.testing.expect(n0.eql(HexCoord.init(1, 0)));

    const n1 = center.neighbor(1);
    try std.testing.expect(n1.eql(HexCoord.init(1, -1)));

    const n2 = center.neighbor(2);
    try std.testing.expect(n2.eql(HexCoord.init(0, -1)));

    const n3 = center.neighbor(3);
    try std.testing.expect(n3.eql(HexCoord.init(-1, 0)));

    const n4 = center.neighbor(4);
    try std.testing.expect(n4.eql(HexCoord.init(-1, 1)));

    const n5 = center.neighbor(5);
    try std.testing.expect(n5.eql(HexCoord.init(0, 1)));
}

test "HexGrid getTile returns null for non-existent coordinate" {
    const allocator = std.testing.allocator;
    var grid = HexGrid.init(allocator);
    defer grid.deinit();

    try grid.setTile(HexCoord.init(0, 0));

    // Query for tile that doesn't exist
    const missing = grid.getTile(HexCoord.init(10, 10));
    try std.testing.expect(missing == null);
}

test "HexGrid setTile overwrites existing tile" {
    const allocator = std.testing.allocator;
    var grid = HexGrid.init(allocator);
    defer grid.deinit();

    const coord = HexCoord.init(5, 5);

    // Add tile once
    try grid.setTile(coord);
    try std.testing.expectEqual(@as(usize, 1), grid.count());

    // Add same tile again (should overwrite, not add)
    try grid.setTile(coord);
    try std.testing.expectEqual(@as(usize, 1), grid.count());

    try std.testing.expect(grid.hasTile(coord));
}

test "HexGrid createRect with zero dimensions" {
    const allocator = std.testing.allocator;
    var grid = HexGrid.init(allocator);
    defer grid.deinit();

    // Zero width
    try grid.createRect(0, 5);
    try std.testing.expectEqual(@as(usize, 0), grid.count());

    // Zero height
    try grid.createRect(5, 0);
    try std.testing.expectEqual(@as(usize, 0), grid.count());

    // Both zero
    try grid.createRect(0, 0);
    try std.testing.expectEqual(@as(usize, 0), grid.count());
}

test "HexGrid createRect with large dimensions" {
    const allocator = std.testing.allocator;
    var grid = HexGrid.init(allocator);
    defer grid.deinit();

    // Create 100x100 grid
    try grid.createRect(100, 100);
    try std.testing.expectEqual(@as(usize, 10000), grid.count());

    // Verify corners
    try std.testing.expect(grid.hasTile(HexCoord.init(0, 0)));
    try std.testing.expect(grid.hasTile(HexCoord.init(99, 0)));
    try std.testing.expect(grid.hasTile(HexCoord.init(0, 99)));
    try std.testing.expect(grid.hasTile(HexCoord.init(99, 99)));
}

test "HexGrid removeTile on non-existent tile is safe" {
    const allocator = std.testing.allocator;
    var grid = HexGrid.init(allocator);
    defer grid.deinit();

    // Remove from empty grid (should not crash)
    grid.removeTile(HexCoord.init(5, 5));
    try std.testing.expectEqual(@as(usize, 0), grid.count());

    // Add a tile, then remove a different one
    try grid.setTile(HexCoord.init(0, 0));
    grid.removeTile(HexCoord.init(5, 5));
    try std.testing.expectEqual(@as(usize, 1), grid.count());
}

test "HexCoord distance is always non-negative" {
    const a = HexCoord.init(-10, -10);
    const b = HexCoord.init(10, 10);

    const dist = a.distance(b);
    try std.testing.expect(dist >= 0);

    // Check some edge cases
    const c = HexCoord.init(0, 0);
    try std.testing.expectEqual(@as(u32, 0), c.distance(c));
}

test "HexGrid with negative coordinates" {
    const allocator = std.testing.allocator;
    var grid = HexGrid.init(allocator);
    defer grid.deinit();

    // Add tiles with negative coordinates
    try grid.setTile(HexCoord.init(-5, -5));
    try grid.setTile(HexCoord.init(-10, 3));
    try grid.setTile(HexCoord.init(5, -7));

    try std.testing.expectEqual(@as(usize, 3), grid.count());
    try std.testing.expect(grid.hasTile(HexCoord.init(-5, -5)));
    try std.testing.expect(grid.hasTile(HexCoord.init(-10, 3)));
    try std.testing.expect(grid.hasTile(HexCoord.init(5, -7)));
}

test "HexCoord.fromFloat with exact integer coordinates" {
    const coord = HexCoord.fromFloat(5.0, 3.0);
    try std.testing.expectEqual(@as(i32, 5), coord.q);
    try std.testing.expectEqual(@as(i32, 3), coord.r);
}

test "HexCoord.fromFloat with fractional coordinates rounds correctly" {
    // Should round to nearest hex (verify cube constraint, not exact values)
    const coord1 = HexCoord.fromFloat(5.4, 3.2);
    try std.testing.expectEqual(@as(i32, 0), coord1.q + coord1.r + coord1.s());

    const coord2 = HexCoord.fromFloat(5.6, 3.8);
    try std.testing.expectEqual(@as(i32, 0), coord2.q + coord2.r + coord2.s());

    // Coordinates should be close to input
    try std.testing.expect(@abs(@as(f32, @floatFromInt(coord1.q)) - 5.4) < 1.0);
    try std.testing.expect(@abs(@as(f32, @floatFromInt(coord1.r)) - 3.2) < 1.0);
}

test "HexCoord.fromFloat with negative fractional coordinates" {
    const coord1 = HexCoord.fromFloat(-2.3, 1.7);
    try std.testing.expectEqual(@as(i32, 0), coord1.q + coord1.r + coord1.s());

    const coord2 = HexCoord.fromFloat(-2.8, 1.2);
    try std.testing.expectEqual(@as(i32, 0), coord2.q + coord2.r + coord2.s());

    // Coordinates should be close to input (within 1 hex)
    try std.testing.expect(@abs(@as(f32, @floatFromInt(coord1.q)) - (-2.3)) < 1.0);
    try std.testing.expect(@abs(@as(f32, @floatFromInt(coord2.q)) - (-2.8)) < 1.0);
}

test "HexCoord.fromFloat cube coordinate constraint" {
    // For any input, q + r + s should equal 0
    const coords = [_][2]f32{
        .{ 1.5, 2.3 },
        .{ -3.7, 4.2 },
        .{ 0.0, 0.0 },
        .{ 5.9, -2.1 },
    };

    for (coords) |c| {
        const hex = HexCoord.fromFloat(c[0], c[1]);
        // Verify cube coordinate invariant
        try std.testing.expectEqual(@as(i32, 0), hex.q + hex.r + hex.s());
    }
}

test "HexCoord.fromFloat at hex boundaries" {
    // Test rounding at 0.5 boundaries (tricky cases)
    const coord1 = HexCoord.fromFloat(2.5, 1.5);
    // Should round consistently
    try std.testing.expectEqual(@as(i32, 0), coord1.q + coord1.r + coord1.s());

    const coord2 = HexCoord.fromFloat(-0.5, 0.5);
    try std.testing.expectEqual(@as(i32, 0), coord2.q + coord2.r + coord2.s());
}

test "HexCoord.fromFloat with zero coordinates" {
    const coord = HexCoord.fromFloat(0.0, 0.0);
    try std.testing.expectEqual(@as(i32, 0), coord.q);
    try std.testing.expectEqual(@as(i32, 0), coord.r);
    try std.testing.expectEqual(@as(i32, 0), coord.s());
}
