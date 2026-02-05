const std = @import("std");
const rl = @import("raylib");
const window = @import("../window.zig");
const DebugWindow = window.DebugWindow;
const WindowId = window.WindowId;
const HexCoord = @import("../../world/hex_grid.zig").HexCoord;

/// Tile information debug window
/// Displays information about the selected tile
/// Note: This is a placeholder for Phase 3 - will show resources, terrain, etc.
pub const TileInfoWindow = struct {
    /// The window container
    win: DebugWindow,

    /// Currently selected tile coordinate (may be null)
    selected_tile: ?HexCoord,

    /// Initialize the tile info window
    pub fn init() TileInfoWindow {
        return TileInfoWindow{
            .win = DebugWindow.init(
                .tile_info,
                "Tile Info",
                10, // x
                350, // y (below entity info window)
                200, // width
                100, // height
            ),
            .selected_tile = null,
        };
    }

    /// Set the selected tile (auto-opens window if tile is selected)
    pub fn setTile(self: *TileInfoWindow, coord: ?HexCoord) void {
        self.selected_tile = coord;
        if (coord != null and !self.win.is_open) {
            self.win.open();
        }
    }

    /// Clear the selection
    pub fn clearSelection(self: *TileInfoWindow) void {
        self.selected_tile = null;
    }

    /// Render the window and its contents
    pub fn render(self: *TileInfoWindow) void {
        const area = self.win.renderFrame() orelse return;

        const font_size: i32 = 14;
        const line_height: i32 = 18;
        var y: i32 = 0;

        if (self.selected_tile) |coord| {
            var buf: [64:0]u8 = undefined;

            // Coordinates
            const coord_text = std.fmt.bufPrintZ(&buf, "Coord: ({d}, {d})", .{ coord.q, coord.r }) catch "Coord: ???";
            area.drawText(coord_text, 0, y, font_size, rl.Color.white);
            y += line_height;

            // Placeholder for Phase 3 features
            area.drawText("Type: (Phase 3)", 0, y, 12, rl.Color.gray);
            y += line_height;

            area.drawText("Resources: (Phase 3)", 0, y, 12, rl.Color.gray);
        } else {
            area.drawText("No tile selected", 0, 0, font_size, rl.Color.gray);
            area.drawText("Click a tile", 0, line_height, 12, rl.Color.dark_gray);
        }
    }

    /// Handle input for this window
    pub fn handleInput(self: *TileInfoWindow) bool {
        return self.win.handleInput();
    }

    /// Get the window reference (for WindowManager registration)
    pub fn getWindow(self: *TileInfoWindow) *DebugWindow {
        return &self.win;
    }
};

// ============================================================================
// Tests
// ============================================================================

test "TileInfoWindow.init creates window at correct position" {
    const tiw = TileInfoWindow.init();
    try std.testing.expectEqual(WindowId.tile_info, tiw.win.id);
    try std.testing.expectEqual(@as(i32, 10), tiw.win.x);
    try std.testing.expectEqual(@as(i32, 350), tiw.win.y);
    try std.testing.expect(tiw.selected_tile == null);
}

test "TileInfoWindow.setTile" {
    var tiw = TileInfoWindow.init();
    tiw.win.close(); // Start closed

    const coord = HexCoord.init(5, 3);
    tiw.setTile(coord);

    try std.testing.expect(tiw.selected_tile != null);
    try std.testing.expectEqual(@as(i32, 5), tiw.selected_tile.?.q);
    try std.testing.expectEqual(@as(i32, 3), tiw.selected_tile.?.r);
    try std.testing.expect(tiw.win.is_open); // Auto-opened
}

test "TileInfoWindow.clearSelection" {
    var tiw = TileInfoWindow.init();
    tiw.setTile(HexCoord.init(1, 2));
    tiw.clearSelection();
    try std.testing.expect(tiw.selected_tile == null);
}
