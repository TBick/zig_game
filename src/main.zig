const std = @import("std");
const rl = @import("raylib");
const HexGrid = @import("world/hex_grid.zig").HexGrid;
const HexRenderer = @import("rendering/hex_renderer.zig").HexRenderer;

pub fn main() !void {
    // Window configuration
    const screen_width = 800;
    const screen_height = 600;

    // Initialize window
    rl.initWindow(screen_width, screen_height, "Zig Game - Hex Grid Prototype");
    defer rl.closeWindow();

    // Set target FPS
    rl.setTargetFPS(60);

    // Initialize hex grid
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var grid = HexGrid.init(allocator);
    defer grid.deinit();

    // Create a 10x10 hex grid
    try grid.createRect(10, 10);

    // Initialize renderer
    var renderer = HexRenderer.init(30.0); // 30 pixel hex size

    // Camera controls
    var last_mouse_pos = rl.getMousePosition();

    // Main game loop
    while (!rl.windowShouldClose()) {
        // Update
        const mouse_pos = rl.getMousePosition();

        // Camera panning (right mouse button for drag)
        if (rl.isMouseButtonDown(rl.MouseButton.right)) {
            const dx = mouse_pos.x - last_mouse_pos.x;
            const dy = mouse_pos.y - last_mouse_pos.y;
            renderer.camera.pan(-dx, -dy);
        }

        // Camera zoom (mouse wheel)
        const wheel = rl.getMouseWheelMove();
        if (wheel != 0) {
            const zoom_factor: f32 = if (wheel > 0) 1.1 else 0.9;
            renderer.camera.zoomBy(zoom_factor);
        }

        // Keyboard camera controls
        const pan_speed = 5.0;
        if (rl.isKeyDown(rl.KeyboardKey.left) or rl.isKeyDown(rl.KeyboardKey.a)) {
            renderer.camera.pan(-pan_speed, 0);
        }
        if (rl.isKeyDown(rl.KeyboardKey.right) or rl.isKeyDown(rl.KeyboardKey.d)) {
            renderer.camera.pan(pan_speed, 0);
        }
        if (rl.isKeyDown(rl.KeyboardKey.up) or rl.isKeyDown(rl.KeyboardKey.w)) {
            renderer.camera.pan(0, -pan_speed);
        }
        if (rl.isKeyDown(rl.KeyboardKey.down) or rl.isKeyDown(rl.KeyboardKey.s)) {
            renderer.camera.pan(0, pan_speed);
        }

        // Keyboard zoom
        if (rl.isKeyDown(rl.KeyboardKey.equal) or rl.isKeyDown(rl.KeyboardKey.kp_add)) {
            renderer.camera.zoomBy(1.02);
        }
        if (rl.isKeyDown(rl.KeyboardKey.minus) or rl.isKeyDown(rl.KeyboardKey.kp_subtract)) {
            renderer.camera.zoomBy(0.98);
        }

        // Reset camera
        if (rl.isKeyPressed(rl.KeyboardKey.r)) {
            renderer.camera = @import("rendering/hex_renderer.zig").Camera.init();
        }

        last_mouse_pos = mouse_pos;

        // Draw
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.init(30, 30, 40, 255));

        // Draw hex grid
        renderer.drawGrid(&grid, screen_width, screen_height);

        // Draw UI
        rl.drawText("Zig Game - Phase 1: Hex Grid", 10, 10, 20, rl.Color.ray_white);
        rl.drawText("WASD/Arrows: Pan  |  Mouse Wheel/+/-: Zoom  |  R: Reset  |  ESC: Exit", 10, 40, 14, rl.Color.light_gray);

        // Draw camera info
        var buf: [100:0]u8 = undefined;
        const info = std.fmt.bufPrintZ(&buf, "Camera: ({d:.0}, {d:.0}) Zoom: {d:.2}x", .{
            renderer.camera.x,
            renderer.camera.y,
            renderer.camera.zoom,
        }) catch "Error";
        rl.drawText(info, 10, screen_height - 30, 14, rl.Color.green);

        // Draw tile count
        var buf2: [100:0]u8 = undefined;
        const count_text = std.fmt.bufPrintZ(&buf2, "Tiles: {d}", .{grid.count()}) catch "Error";
        rl.drawText(count_text, 10, screen_height - 50, 14, rl.Color.green);
    }
}

test "basic functionality" {
    try std.testing.expect(true);
}
