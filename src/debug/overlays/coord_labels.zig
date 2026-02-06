const std = @import("std");
const rl = @import("raylib");
const HexGrid = @import("../../world/hex_grid.zig").HexGrid;
const HexLayout = @import("../../rendering/hex_renderer.zig").HexLayout;
const Camera = @import("../../rendering/hex_renderer.zig").Camera;

/// Debug overlay that renders coordinate labels in the center of each hex tile
pub const CoordLabels = struct {
    /// Font size for coordinate labels
    font_size: i32 = 10,

    /// Text color for labels
    color: rl.Color = rl.Color.white,

    /// Initialize the coordinate labels overlay
    pub fn init() CoordLabels {
        return CoordLabels{};
    }

    /// Render coordinate labels for all tiles in the grid
    /// Requires hex layout and camera for coordinate transformation
    pub fn render(
        self: *const CoordLabels,
        grid: *const HexGrid,
        layout: *const HexLayout,
        camera: *const Camera,
        screen_width: i32,
        screen_height: i32,
    ) void {
        var it = grid.tiles.iterator();
        while (it.next()) |entry| {
            const coord = entry.key_ptr.*;

            // Convert hex coordinate to world pixel position
            const pixel = layout.hexToPixel(coord);

            // Convert world position to screen position
            const screen_pos = camera.worldToScreen(pixel.x, pixel.y, screen_width, screen_height);

            // Format coordinate text
            var buf: [32:0]u8 = undefined;
            const label = std.fmt.bufPrintZ(&buf, "{d},{d}", .{ coord.q, coord.r }) catch "??";

            // Center the text on the hex
            const text_width = rl.measureText(label, self.font_size);
            const text_x: i32 = @as(i32, @intFromFloat(screen_pos.x)) - @divTrunc(text_width, 2);
            const text_y: i32 = @as(i32, @intFromFloat(screen_pos.y)) - @divTrunc(self.font_size, 2);

            rl.drawText(label, text_x, text_y, self.font_size, self.color);
        }
    }
};

// ============================================================================
// Tests
// ============================================================================

test "CoordLabels.init creates with defaults" {
    const labels = CoordLabels.init();
    try std.testing.expectEqual(@as(i32, 10), labels.font_size);
}
