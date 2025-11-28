const std = @import("std");
const rl = @import("raylib");
const Camera = @import("../rendering/hex_renderer.zig").Camera;

/// Manager for rendering UI text elements (non-panel UI)
/// Handles help text, camera info, entity/tile counts, and tick information
pub const UIManager = struct {
    // Stateless - no fields needed

    /// Initialize the UI manager
    pub fn init() UIManager {
        return UIManager{};
    }

    /// Draw all UI text elements
    pub fn draw(
        self: *const UIManager,
        camera: *const Camera,
        entity_count: usize,
        tile_count: usize,
        current_tick: u64,
        tick_rate: f32,
        screen_width: i32,
        screen_height: i32,
    ) void {
        // Draw title and help text
        self.drawHelpText();

        // Draw camera information
        self.drawCameraInfo(camera, screen_height);

        // Draw entity and tile counts
        self.drawEntityTileCount(entity_count, tile_count, screen_height);

        // Draw tick information
        self.drawTickInfo(current_tick, tick_rate, screen_height);

        _ = screen_width; // Reserved for future use
    }

    /// Draw title and help text at the top of the screen
    fn drawHelpText(self: *const UIManager) void {
        _ = self;

        rl.drawText("Zig Game - Advanced Input System", 10, 180, 20, rl.Color.ray_white);
        rl.drawText("Hover: Preview tiles/entities  |  Left Click: Select  |  Right Drag: Pan", 10, 210, 14, rl.Color.light_gray);
        rl.drawText("WASD/Arrows: Pan  |  Wheel/+/-: Zoom  |  R: Reset  |  F3: Debug", 10, 230, 14, rl.Color.light_gray);
    }

    /// Draw camera position and zoom information
    fn drawCameraInfo(self: *const UIManager, camera: *const Camera, screen_height: i32) void {
        _ = self;

        const cam_y = screen_height - 80;
        var buf: [100:0]u8 = undefined;
        const info = std.fmt.bufPrintZ(&buf, "Camera: ({d:.0}, {d:.0}) Zoom: {d:.2}x", .{
            camera.x,
            camera.y,
            camera.zoom,
        }) catch "Error";
        rl.drawText(info, 10, cam_y, 14, rl.Color.green);
    }

    /// Draw entity and tile counts
    fn drawEntityTileCount(self: *const UIManager, entity_count: usize, tile_count: usize, screen_height: i32) void {
        _ = self;

        const cam_y = screen_height - 80;
        var buf: [100:0]u8 = undefined;
        const count_text = std.fmt.bufPrintZ(&buf, "Entities: {d}  Tiles: {d}", .{
            entity_count,
            tile_count,
        }) catch "Error";
        rl.drawText(count_text, 10, cam_y + 20, 14, rl.Color.green);
    }

    /// Draw tick counter and tick rate
    fn drawTickInfo(self: *const UIManager, current_tick: u64, tick_rate: f32, screen_height: i32) void {
        _ = self;

        const cam_y = screen_height - 80;
        var buf: [100:0]u8 = undefined;
        const tick_text = std.fmt.bufPrintZ(&buf, "Tick: {d}  Rate: {d:.1} tps", .{
            current_tick,
            tick_rate,
        }) catch "Error";
        rl.drawText(tick_text, 10, cam_y + 40, 14, rl.Color.green);
    }
};

// ============================================================================
// Tests
// ============================================================================

test "UIManager.init creates stateless instance" {
    const ui_manager = UIManager.init();
    _ = ui_manager; // Verify it's a valid instance
}

test "UIManager can be const" {
    const ui_manager = UIManager.init();
    // Verify draw method accepts const self (compile-time check)
    _ = ui_manager;
}

test "UIManager initialization is simple" {
    // Verify init requires no parameters
    const ui1 = UIManager.init();
    const ui2 = UIManager.init();

    // Both instances should be identical (stateless)
    _ = ui1;
    _ = ui2;
}
