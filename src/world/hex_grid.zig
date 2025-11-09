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
    pub fn distance(self: HexCoord, other: HexCoord) i32 {
        const diff = self.sub(other);
        return @divTrunc(
            @abs(diff.q) + @abs(diff.r) + @abs(diff.s()),
            2,
        );
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

    try std.testing.expectEqual(@as(i32, 0), a.distance(a));
    try std.testing.expectEqual(@as(i32, 3), a.distance(b));
    try std.testing.expectEqual(@as(i32, 3), a.distance(c));
    try std.testing.expectEqual(@as(i32, 2), a.distance(d));
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
