const std = @import("std");
const rl = @import("raylib");
const HexCoord = @import("../world/hex_grid.zig").HexCoord;
const HexGrid = @import("../world/hex_grid.zig").HexGrid;

/// Camera for viewing the hex grid
pub const Camera = struct {
    x: f32,     // World position X
    y: f32,     // World position Y
    zoom: f32,  // Zoom level (1.0 = normal)

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
    size: f32,          // Radius of hexagon
    orientation: bool,  // true = flat-top, false = pointy-top

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

    /// Get the 6 corner points of a hexagon
    pub fn hexCorners(self: HexLayout, hex: HexCoord) [6]rl.Vector2 {
        const center = self.hexToPixel(hex);
        var corners: [6]rl.Vector2 = undefined;

        for (0..6) |i| {
            const offset: f32 = if (self.orientation) 0.0 else 30.0;
            const angle_deg: f32 = 60.0 * @as(f32, @floatFromInt(i)) + offset;
            const angle_rad = angle_deg * std.math.pi / 180.0;

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
