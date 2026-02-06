const std = @import("std");
const rl = @import("raylib");
const HexCoord = @import("../../world/hex_grid.zig").HexCoord;
const HexLayout = @import("../../rendering/hex_renderer.zig").HexLayout;
const Camera = @import("../../rendering/hex_renderer.zig").Camera;
const Entity = @import("../../entities/entity.zig").Entity;

/// Debug overlay that renders selection and hover highlights
/// for tiles and entities
pub const SelectionOverlay = struct {
    // Tile highlight colors
    pub const selected_tile_fill = rl.Color.init(80, 120, 180, 255); // Blue
    pub const selected_tile_outline = rl.Color.init(120, 180, 255, 255); // Bright blue
    pub const hovered_tile_fill = rl.Color.init(70, 70, 90, 255); // Lighter gray
    pub const hovered_tile_outline = rl.Color.init(150, 150, 170, 255); // Bright gray

    // Entity highlight colors
    pub const entity_highlight_color = rl.Color.yellow;
    pub const entity_highlight_radius_offset: f32 = 4.0;

    /// Initialize the selection overlay
    pub fn init() SelectionOverlay {
        return SelectionOverlay{};
    }

    /// Render a highlight ring around an entity
    pub fn renderEntityHighlight(
        self: *const SelectionOverlay,
        entity: *const Entity,
        layout: *const HexLayout,
        camera: *const Camera,
        screen_width: i32,
        screen_height: i32,
    ) void {
        _ = self;

        // Convert entity position to screen coordinates
        const pixel = layout.hexToPixel(entity.position);
        const screen_pos = camera.worldToScreen(pixel.x, pixel.y, screen_width, screen_height);

        // Calculate radius based on hex size and camera zoom
        const base_radius = layout.size * 0.6;
        const scaled_radius = base_radius * camera.zoom;

        // Draw highlight ring
        rl.drawCircleLines(
            @intFromFloat(screen_pos.x),
            @intFromFloat(screen_pos.y),
            @floatCast(scaled_radius + entity_highlight_radius_offset),
            entity_highlight_color,
        );

        // Draw second ring for more visibility
        rl.drawCircleLines(
            @intFromFloat(screen_pos.x),
            @intFromFloat(screen_pos.y),
            @floatCast(scaled_radius + entity_highlight_radius_offset + 2),
            entity_highlight_color,
        );
    }

    /// Get tile fill and outline colors based on hover/selection state
    /// Returns null for normal state (no special rendering needed)
    pub fn getTileColors(
        self: *const SelectionOverlay,
        is_selected: bool,
        is_hovered: bool,
    ) ?struct { fill: rl.Color, outline: rl.Color } {
        _ = self;

        if (is_selected) {
            return .{
                .fill = selected_tile_fill,
                .outline = selected_tile_outline,
            };
        }
        if (is_hovered) {
            return .{
                .fill = hovered_tile_fill,
                .outline = hovered_tile_outline,
            };
        }
        return null; // Normal state, no special rendering
    }

    /// Render a highlighted tile (filled hex with colored outline)
    pub fn renderTileHighlight(
        self: *const SelectionOverlay,
        coord: HexCoord,
        is_selected: bool,
        is_hovered: bool,
        layout: *const HexLayout,
        camera: *const Camera,
        screen_width: i32,
        screen_height: i32,
    ) void {
        const colors = self.getTileColors(is_selected, is_hovered) orelse return;

        // Get hex corners in screen space
        const pixel = layout.hexToPixel(coord);
        const screen_pos = camera.worldToScreen(pixel.x, pixel.y, screen_width, screen_height);

        // Scale size by zoom
        const scaled_size = layout.size * camera.zoom;

        // Draw filled hex
        // Note: For a full implementation, we'd calculate all 6 corners
        // For now, draw a circle approximation
        rl.drawCircle(
            @intFromFloat(screen_pos.x),
            @intFromFloat(screen_pos.y),
            @floatCast(scaled_size * 0.8),
            colors.fill,
        );

        // Draw outline
        rl.drawCircleLines(
            @intFromFloat(screen_pos.x),
            @intFromFloat(screen_pos.y),
            @floatCast(scaled_size * 0.85),
            colors.outline,
        );
    }
};

// ============================================================================
// Tests
// ============================================================================

test "SelectionOverlay.init" {
    const overlay = SelectionOverlay.init();
    _ = overlay;
}

test "SelectionOverlay.getTileColors returns correct colors" {
    const overlay = SelectionOverlay.init();

    // Selected state
    const selected = overlay.getTileColors(true, false);
    try std.testing.expect(selected != null);
    try std.testing.expectEqual(SelectionOverlay.selected_tile_fill.r, selected.?.fill.r);

    // Hovered state
    const hovered = overlay.getTileColors(false, true);
    try std.testing.expect(hovered != null);
    try std.testing.expectEqual(SelectionOverlay.hovered_tile_fill.r, hovered.?.fill.r);

    // Normal state
    const normal = overlay.getTileColors(false, false);
    try std.testing.expect(normal == null);
}

test "SelectionOverlay.getTileColors selected takes priority" {
    const overlay = SelectionOverlay.init();

    // Both selected and hovered - selected wins
    const both = overlay.getTileColors(true, true);
    try std.testing.expect(both != null);
    try std.testing.expectEqual(SelectionOverlay.selected_tile_fill.r, both.?.fill.r);
}
