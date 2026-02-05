const std = @import("std");
const rl = @import("raylib");
const HexCoord = @import("../world/hex_grid.zig").HexCoord;
const HexGrid = @import("../world/hex_grid.zig").HexGrid;
const DrawableTileSet = @import("drawable_tile_set.zig").DrawableTileSet;

/// Hexagon direction/edge enum for flat-top hexagons
/// Directions represent both neighbor positions and edge indices
pub const HexDirection_Flat = enum(u3) {
    northeast = 0, // E:  q+1, r+0  (also: edge connecting corners 0→1)
    north = 1, // NE: q+1, r-1  (also: edge connecting corners 1→2)
    northwest = 2, // NW: q+0, r-1  (also: edge connecting corners 2→3)
    southwest = 3, // W:  q-1, r+0  (also: edge connecting corners 3→4)
    south = 4, // SW: q-1, r+1  (also: edge connecting corners 4→5)
    southeast = 5, // SE: q+0, r+1  (also: edge connecting corners 5→0)

    /// Convert to integer index
    pub fn toInt(self: HexDirection_Flat) u3 {
        return @intFromEnum(self);
    }

    /// Create from integer index
    pub fn fromInt(value: u3) HexDirection_Flat {
        return @enumFromInt(value);
    }

    /// Get all 6 directions in order
    pub fn all() [6]HexDirection_Flat {
        return [6]HexDirection_Flat{
            .northeast, .north, .northwest,
            .southwest, .south, .southeast,
        };
    }
};

// Hexagon direction/edge enum for pointy-top hexagons
pub const HexDirection_Pointy = enum(u3) {
    east = 0,
    northeast = 1,
    northwest = 2,
    west = 3,
    southwest = 4,
    southeast = 5,

    pub fn toInt(self: HexDirection_Pointy) u3 {
        return @intFromEnum(self);
    }

    pub fn fromInt(value: u3) HexDirection_Pointy {
        return @enumFromInt(value);
    }

    pub fn all() [6]HexDirection_Pointy {
        return [6]HexDirection_Pointy{
            .east, .northeast, .northwest,
            .west, .southwest, .southeast,
        };
    }
};

/// Camera for viewing the hex grid
pub const Camera = struct {
    x: f32, // World position X
    y: f32, // World position Y
    zoom: f32, // Zoom level (1.0 = normal)

    pub fn init() Camera {
        return Camera{
            .x = 0.0,
            .y = 0.0,
            .zoom = 1.0,
        };
    }

    /// Convert world coordinates to screen coordinates
    pub fn worldToScreen(self: Camera, world_x: f32, world_y: f32, screen_width: i32, screen_height: i32) rl.Vector2 {
        const half_w: f32 = @as(f32, @floatFromInt(screen_width)) / 2.0;
        const half_h: f32 = @as(f32, @floatFromInt(screen_height)) / 2.0;

        return rl.Vector2{
            .x = (world_x - self.x) * self.zoom + half_w,
            .y = (world_y - self.y) * self.zoom + half_h,
        };
    }

    /// Convert screen coordinates to world coordinates
    pub fn screenToWorld(self: Camera, screen_x: f32, screen_y: f32, screen_width: i32, screen_height: i32) rl.Vector2 {
        const half_w: f32 = @as(f32, @floatFromInt(screen_width)) / 2.0;
        const half_h: f32 = @as(f32, @floatFromInt(screen_height)) / 2.0;

        return rl.Vector2{
            .x = (screen_x - half_w) / self.zoom + self.x,
            .y = (screen_y - half_h) / self.zoom + self.y,
        };
    }

    /// Pan the camera
    pub fn pan(self: *Camera, dx: f32, dy: f32) void {
        self.x += dx / self.zoom;
        self.y += dy / self.zoom;
    }

    /// Zoom the camera (centered on screen)
    pub fn zoomBy(self: *Camera, factor: f32) void {
        self.zoom *= factor;
        // Clamp zoom
        if (self.zoom < 0.1) self.zoom = 0.1;
        if (self.zoom > 5.0) self.zoom = 5.0;
    }
};

/// Hex rendering configuration
pub const HexLayout = struct {
    size: f32, // Radius of hexagon
    orientation: bool, // true = flat-top, false = pointy-top

    pub fn init(size: f32, flat_top: bool) HexLayout {
        return HexLayout{
            .size = size,
            .orientation = flat_top,
        };
    }

    /// Convert hex coordinate to pixel position (center of hex)
    pub fn hexToPixel(self: HexLayout, hex: HexCoord) rl.Vector2 {
        if (self.orientation) {
            // Flat-top orientation
            const x = self.size * (3.0 / 2.0 * @as(f32, @floatFromInt(hex.q)));
            const y = self.size * (std.math.sqrt(3.0) / 2.0 * @as(f32, @floatFromInt(hex.q)) +
                std.math.sqrt(3.0) * @as(f32, @floatFromInt(hex.r)));
            return rl.Vector2{ .x = x, .y = y };
        } else {
            // Pointy-top orientation
            const x = self.size * (std.math.sqrt(3.0) * @as(f32, @floatFromInt(hex.q)) +
                std.math.sqrt(3.0) / 2.0 * @as(f32, @floatFromInt(hex.r)));
            const y = self.size * (3.0 / 2.0 * @as(f32, @floatFromInt(hex.r)));
            return rl.Vector2{ .x = x, .y = y };
        }
    }

    /// Convert pixel position to hex coordinate (inverse of hexToPixel)
    /// Returns the hex coordinate closest to the given pixel position
    pub fn pixelToHex(self: HexLayout, pixel: rl.Vector2) HexCoord {
        if (self.orientation) {
            // Flat-top orientation (inverse transformation)
            const q = (2.0 / 3.0 * pixel.x) / self.size;
            const r = (-1.0 / 3.0 * pixel.x + std.math.sqrt(3.0) / 3.0 * pixel.y) / self.size;
            return HexCoord.fromFloat(q, r);
        } else {
            // Pointy-top orientation (inverse transformation)
            const q = (std.math.sqrt(3.0) / 3.0 * pixel.x - 1.0 / 3.0 * pixel.y) / self.size;
            const r = (2.0 / 3.0 * pixel.y) / self.size;
            return HexCoord.fromFloat(q, r);
        }
    }

    /// Get the 6 corner points of a hexagon
    pub fn hexCorners(self: HexLayout, hex: HexCoord) [6]rl.Vector2 {
        const center = self.hexToPixel(hex);
        var corners: [6]rl.Vector2 = undefined;

        for (0..6) |i| {
            const offset: f32 = if (self.orientation) 0.0 else 30.0;
            const angle_deg: f32 = 60.0 * @as(f32, @floatFromInt(i)) + offset;
            const angle_rad = -angle_deg * std.math.pi / 180.0;

            corners[i] = rl.Vector2{
                .x = center.x + self.size * @cos(angle_rad),
                .y = center.y + self.size * @sin(angle_rad),
            };
        }

        return corners;
    }
};

/// Hex renderer
pub const HexRenderer = struct {
    layout: HexLayout,
    camera: Camera,

    pub fn init(hex_size: f32) HexRenderer {
        return HexRenderer{
            .layout = HexLayout.init(hex_size, true), // flat-top
            .camera = Camera.init(),
        };
    }

    /// Draw a single hex outline
    pub fn drawHexOutline(self: *HexRenderer, hex: HexCoord, color: rl.Color, screen_width: i32, screen_height: i32) void {
        const corners = self.layout.hexCorners(hex);

        // Convert all corners to screen space
        var screen_corners: [6]rl.Vector2 = undefined;
        for (corners, 0..) |corner, i| {
            screen_corners[i] = self.camera.worldToScreen(corner.x, corner.y, screen_width, screen_height);
        }

        // Draw lines between consecutive corners
        for (0..6) |i| {
            const next = (i + 1) % 6;
            rl.drawLineV(screen_corners[i], screen_corners[next], color);
        }
    }

    /// Draw a filled hex
    pub fn drawHexFilled(self: *HexRenderer, hex: HexCoord, color: rl.Color, screen_width: i32, screen_height: i32) void {
        const corners = self.layout.hexCorners(hex);

        // Convert all corners to screen space
        var screen_corners: [6]rl.Vector2 = undefined;
        for (corners, 0..) |corner, i| {
            screen_corners[i] = self.camera.worldToScreen(corner.x, corner.y, screen_width, screen_height);
        }

        // Draw filled polygon (triangle fan)
        for (1..5) |i| {
            rl.drawTriangle(screen_corners[0], screen_corners[i], screen_corners[i + 1], color);
        }
    }

    /// Draw the entire hex grid
    pub fn drawGrid(self: *HexRenderer, grid: *HexGrid, screen_width: i32, screen_height: i32) void {
        var it = grid.tiles.iterator();
        while (it.next()) |entry| {
            const coord = entry.key_ptr.*;

            // Draw filled hex
            self.drawHexFilled(coord, rl.Color.dark_gray, screen_width, screen_height);

            // Draw outline
            self.drawHexOutline(coord, rl.Color.light_gray, screen_width, screen_height);
        }
    }

    // ========================================================================
    // Optimized Edge Rendering
    // ========================================================================

    /// Get the two vertex positions for a specific edge direction
    /// Returns vertices in world coordinates
    fn getEdgeVertices(self: *HexRenderer, coord: HexCoord, direction_idx: u3) struct { v1: rl.Vector2, v2: rl.Vector2 } {
        const corners: [6]rl.Vector2 = self.layout.hexCorners(coord);
        const next_dir = (direction_idx + 1) % 6;
        return .{
            .v1 = corners[direction_idx],
            .v2 = corners[next_dir],
        };
    }

    /// Draw a single edge segment from this tile in the specified direction
    fn drawEdgeSegment(
        self: *HexRenderer,
        coord: HexCoord,
        color: rl.Color,
        direction_idx: u3,
        screen_width: i32,
        screen_height: i32,
    ) void {
        const vertices = self.getEdgeVertices(coord, direction_idx);

        // Convert to screen space
        const screen_v1 = self.camera.worldToScreen(vertices.v1.x, vertices.v1.y, screen_width, screen_height);
        const screen_v2 = self.camera.worldToScreen(vertices.v2.x, vertices.v2.y, screen_width, screen_height);

        // Draw the edge
        rl.drawLineV(screen_v1, screen_v2, color);
    }

    /// Draw seamless edges for a set of drawable tiles
    /// Only draws boundary edges (edges where there's no neighboring tile)
    /// Interior edges are not drawn, creating a seamless filled appearance
    /// Result: Smooth filled regions with clear boundary outlines
    pub fn drawOptimizedEdges(
        self: *HexRenderer,
        drawable_set: *const DrawableTileSet,
        screen_width: i32,
        screen_height: i32,
    ) void {
        const edgeColor = rl.Color{
            .r = 255,
            .g = 255,
            .b = 255,
            .a = 255,
        };

        var it = drawable_set.iterator();
        while (it.next()) |coord_ptr| {
            const coord = coord_ptr.*;
            const neighbors: [6]HexCoord = coord.neighbors(self.layout.orientation);

            var index: u3 = 0;
            for (neighbors) |neighbor_coord| {
                if (!drawable_set.contains(neighbor_coord)) {
                    // Boundary edge (no neighbor in this direction) - draw it
                    drawEdgeSegment(self, coord, edgeColor, index, screen_width, screen_height);
                }
                // If neighbor exists: skip drawing (interior edge - seamless)
                index += 1;
            }
        }
    }
};

// ============================================================================
// Tests
// ============================================================================

test "Camera world to screen conversion" {
    const cam = Camera.init();
    const screen_w = 800;
    const screen_h = 600;

    const screen_pos = cam.worldToScreen(0.0, 0.0, screen_w, screen_h);
    try std.testing.expectEqual(@as(f32, 400.0), screen_pos.x);
    try std.testing.expectEqual(@as(f32, 300.0), screen_pos.y);
}

test "Camera pan" {
    var cam = Camera.init();
    cam.pan(10.0, 20.0);

    try std.testing.expectEqual(@as(f32, 10.0), cam.x);
    try std.testing.expectEqual(@as(f32, 20.0), cam.y);
}

test "Camera zoom" {
    var cam = Camera.init();
    cam.zoomBy(2.0);
    try std.testing.expectEqual(@as(f32, 2.0), cam.zoom);

    cam.zoomBy(0.1);
    try std.testing.expectEqual(@as(f32, 0.2), cam.zoom);

    // Test zoom clamping
    cam.zoomBy(0.01);
    try std.testing.expectEqual(@as(f32, 0.1), cam.zoom); // Clamped to min
}

test "HexLayout hex to pixel conversion" {
    const layout = HexLayout.init(30.0, true);
    const hex = HexCoord.init(0, 0);
    const pixel = layout.hexToPixel(hex);

    try std.testing.expectEqual(@as(f32, 0.0), pixel.x);
    try std.testing.expectEqual(@as(f32, 0.0), pixel.y);
}

test "HexLayout hex corners" {
    const layout = HexLayout.init(30.0, true);
    const hex = HexCoord.init(0, 0);
    const corners = layout.hexCorners(hex);

    try std.testing.expectEqual(@as(usize, 6), corners.len);
    // Verify corners are roughly the right distance from center
    for (corners) |corner| {
        const dist = @sqrt(corner.x * corner.x + corner.y * corner.y);
        try std.testing.expect(@abs(dist - 30.0) < 0.1);
    }
}

test "Camera screenToWorld conversion" {
    const cam = Camera.init();
    const screen_w = 800;
    const screen_h = 600;

    // Center of screen should map to world origin
    const world_pos = cam.screenToWorld(400.0, 300.0, screen_w, screen_h);
    try std.testing.expectEqual(@as(f32, 0.0), world_pos.x);
    try std.testing.expectEqual(@as(f32, 0.0), world_pos.y);
}

test "Camera worldToScreen and screenToWorld roundtrip" {
    const cam = Camera.init();
    const screen_w = 800;
    const screen_h = 600;

    const world_x: f32 = 100.0;
    const world_y: f32 = 200.0;

    const screen_pos = cam.worldToScreen(world_x, world_y, screen_w, screen_h);
    const world_pos = cam.screenToWorld(screen_pos.x, screen_pos.y, screen_w, screen_h);

    try std.testing.expectApproxEqAbs(world_x, world_pos.x, 0.01);
    try std.testing.expectApproxEqAbs(world_y, world_pos.y, 0.01);
}

test "Camera worldToScreen with panned camera" {
    var cam = Camera.init();
    cam.x = 100.0;
    cam.y = 50.0;
    const screen_w = 800;
    const screen_h = 600;

    // World position 100,50 should be at screen center (since camera is there)
    const screen_pos = cam.worldToScreen(100.0, 50.0, screen_w, screen_h);
    try std.testing.expectEqual(@as(f32, 400.0), screen_pos.x);
    try std.testing.expectEqual(@as(f32, 300.0), screen_pos.y);
}

test "Camera worldToScreen with zoomed camera" {
    var cam = Camera.init();
    cam.zoom = 2.0;
    const screen_w = 800;
    const screen_h = 600;

    // At 2x zoom, world position 50,0 should appear at 50*2 + 400 = 500
    const screen_pos = cam.worldToScreen(50.0, 0.0, screen_w, screen_h);
    try std.testing.expectEqual(@as(f32, 500.0), screen_pos.x);
    try std.testing.expectEqual(@as(f32, 300.0), screen_pos.y);
}

test "Camera zoom clamping at maximum" {
    var cam = Camera.init();
    cam.zoom = 4.0;
    cam.zoomBy(2.0); // Would be 8.0, but should clamp to 5.0
    try std.testing.expectEqual(@as(f32, 5.0), cam.zoom);
}

test "Camera pan compensates for zoom" {
    var cam = Camera.init();
    cam.zoom = 2.0;

    // Pan by 100 pixels (screen space)
    cam.pan(100.0, 0.0);

    // With 2x zoom, 100 screen pixels = 50 world units
    try std.testing.expectEqual(@as(f32, 50.0), cam.x);
    try std.testing.expectEqual(@as(f32, 0.0), cam.y);
}

test "HexLayout hexToPixel with non-origin coordinates" {
    const layout = HexLayout.init(30.0, true);
    const hex1 = HexCoord.init(1, 0);
    const hex2 = HexCoord.init(0, 1);

    const pixel1 = layout.hexToPixel(hex1);
    const pixel2 = layout.hexToPixel(hex2);

    // Verify pixels are not at origin
    try std.testing.expect(pixel1.x != 0.0 or pixel1.y != 0.0);
    try std.testing.expect(pixel2.x != 0.0 or pixel2.y != 0.0);

    // Verify they're different from each other
    try std.testing.expect(pixel1.x != pixel2.x or pixel1.y != pixel2.y);
}

test "HexLayout pointy-top orientation" {
    const flat_layout = HexLayout.init(30.0, true);
    const pointy_layout = HexLayout.init(30.0, false);

    const hex = HexCoord.init(1, 1);
    const flat_pixel = flat_layout.hexToPixel(hex);
    const pointy_pixel = pointy_layout.hexToPixel(hex);

    // Pointy and flat should give different results
    try std.testing.expect(flat_pixel.x != pointy_pixel.x or flat_pixel.y != pointy_pixel.y);
}

test "HexLayout hexCorners for pointy-top" {
    const layout = HexLayout.init(30.0, false); // Pointy-top
    const hex = HexCoord.init(0, 0);
    const corners = layout.hexCorners(hex);

    try std.testing.expectEqual(@as(usize, 6), corners.len);
    // All corners should be at radius distance from center
    for (corners) |corner| {
        const dist = @sqrt(corner.x * corner.x + corner.y * corner.y);
        try std.testing.expect(@abs(dist - 30.0) < 0.1);
    }
}

test "Camera with extreme coordinates" {
    var cam = Camera.init();
    cam.x = 10000.0;
    cam.y = -10000.0;
    const screen_w = 800;
    const screen_h = 600;

    const screen_pos = cam.worldToScreen(10000.0, -10000.0, screen_w, screen_h);
    try std.testing.expectEqual(@as(f32, 400.0), screen_pos.x);
    try std.testing.expectEqual(@as(f32, 300.0), screen_pos.y);
}

test "HexLayout with different sizes" {
    const small_layout = HexLayout.init(10.0, true);
    const large_layout = HexLayout.init(100.0, true);

    const hex = HexCoord.init(1, 0);
    const small_pixel = small_layout.hexToPixel(hex);
    const large_pixel = large_layout.hexToPixel(hex);

    // Larger size should give larger distances
    const small_dist = @sqrt(small_pixel.x * small_pixel.x + small_pixel.y * small_pixel.y);
    const large_dist = @sqrt(large_pixel.x * large_pixel.x + large_pixel.y * large_pixel.y);

    try std.testing.expect(large_dist > small_dist);
}

test "HexLayout.pixelToHex with origin" {
    const layout = HexLayout.init(30.0, true);
    const pixel = rl.Vector2{ .x = 0.0, .y = 0.0 };
    const hex = layout.pixelToHex(pixel);

    // Origin pixel should map to origin hex
    try std.testing.expectEqual(@as(i32, 0), hex.q);
    try std.testing.expectEqual(@as(i32, 0), hex.r);
}

test "HexLayout.hexToPixel and pixelToHex roundtrip (flat-top)" {
    const layout = HexLayout.init(30.0, true);

    // Test several hex coordinates
    const test_coords = [_]HexCoord{
        HexCoord.init(0, 0),
        HexCoord.init(1, 0),
        HexCoord.init(0, 1),
        HexCoord.init(1, 1),
        HexCoord.init(-1, 0),
        HexCoord.init(0, -1),
        HexCoord.init(5, 5),
        HexCoord.init(-3, 2),
    };

    for (test_coords) |original_hex| {
        const pixel = layout.hexToPixel(original_hex);
        const result_hex = layout.pixelToHex(pixel);

        // Roundtrip should return to original coordinate
        try std.testing.expectEqual(original_hex.q, result_hex.q);
        try std.testing.expectEqual(original_hex.r, result_hex.r);
    }
}

test "HexLayout.hexToPixel and pixelToHex roundtrip (pointy-top)" {
    const layout = HexLayout.init(30.0, false); // Pointy-top

    const test_coords = [_]HexCoord{
        HexCoord.init(0, 0),
        HexCoord.init(1, 0),
        HexCoord.init(0, 1),
        HexCoord.init(2, 3),
        HexCoord.init(-2, -3),
    };

    for (test_coords) |original_hex| {
        const pixel = layout.hexToPixel(original_hex);
        const result_hex = layout.pixelToHex(pixel);

        try std.testing.expectEqual(original_hex.q, result_hex.q);
        try std.testing.expectEqual(original_hex.r, result_hex.r);
    }
}

test "HexLayout.pixelToHex with different hex sizes" {
    const small_layout = HexLayout.init(10.0, true);
    const large_layout = HexLayout.init(50.0, true);

    const hex = HexCoord.init(3, 2);

    // Convert to pixels with different sizes
    const small_pixel = small_layout.hexToPixel(hex);
    const large_pixel = large_layout.hexToPixel(hex);

    // Convert back to hex
    const small_result = small_layout.pixelToHex(small_pixel);
    const large_result = large_layout.pixelToHex(large_pixel);

    // Both should roundtrip correctly despite different sizes
    try std.testing.expectEqual(hex.q, small_result.q);
    try std.testing.expectEqual(hex.r, small_result.r);
    try std.testing.expectEqual(hex.q, large_result.q);
    try std.testing.expectEqual(hex.r, large_result.r);
}

test "HexLayout.pixelToHex at hex boundaries" {
    const layout = HexLayout.init(30.0, true);
    const hex = HexCoord.init(1, 1);

    // Get the center pixel of this hex
    const center = layout.hexToPixel(hex);

    // Points slightly offset from center should still map to same hex
    const offsets = [_]rl.Vector2{
        rl.Vector2{ .x = center.x + 5.0, .y = center.y },
        rl.Vector2{ .x = center.x - 5.0, .y = center.y },
        rl.Vector2{ .x = center.x, .y = center.y + 5.0 },
        rl.Vector2{ .x = center.x, .y = center.y - 5.0 },
    };

    for (offsets) |offset_pixel| {
        const result = layout.pixelToHex(offset_pixel);
        // Small offsets from center should still be in the same hex
        try std.testing.expectEqual(hex.q, result.q);
        try std.testing.expectEqual(hex.r, result.r);
    }
}

test "HexLayout.pixelToHex with negative coordinates" {
    const layout = HexLayout.init(30.0, true);

    const test_hexes = [_]HexCoord{
        HexCoord.init(-5, 3),
        HexCoord.init(3, -5),
        HexCoord.init(-2, -2),
    };

    for (test_hexes) |hex| {
        const pixel = layout.hexToPixel(hex);
        const result = layout.pixelToHex(pixel);

        try std.testing.expectEqual(hex.q, result.q);
        try std.testing.expectEqual(hex.r, result.r);
    }
}

// ============================================================================
// Optimized Edge Rendering Tests
// ============================================================================

test "HexRenderer.getEdgeVertices returns correct vertices for east direction" {
    var renderer = HexRenderer.init(30.0);
    const coord = HexCoord.init(0, 0);

    // Direction east should return corners[0] and corners[1]
    const edge = renderer.getEdgeVertices(coord, 0);
    const corners = renderer.layout.hexCorners(coord);

    try std.testing.expectEqual(corners[0].x, edge.v1.x);
    try std.testing.expectEqual(corners[0].y, edge.v1.y);
    try std.testing.expectEqual(corners[1].x, edge.v2.x);
    try std.testing.expectEqual(corners[1].y, edge.v2.y);
}

test "HexRenderer.getEdgeVertices wraps correctly at southeast direction" {
    var renderer = HexRenderer.init(30.0);
    const coord = HexCoord.init(1, 1);

    // Direction southeast should return corners[5] and corners[0] (wrap around)
    const edge = renderer.getEdgeVertices(coord, 5);
    const corners = renderer.layout.hexCorners(coord);

    try std.testing.expectEqual(corners[5].x, edge.v1.x);
    try std.testing.expectEqual(corners[5].y, edge.v1.y);
    try std.testing.expectEqual(corners[0].x, edge.v2.x);
    try std.testing.expectEqual(corners[0].y, edge.v2.y);
}
