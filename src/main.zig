const std = @import("std");
const rl = @import("raylib");
const HexGrid = @import("world/hex_grid.zig").HexGrid;
const HexRenderer = @import("rendering/hex_renderer.zig").HexRenderer;
const DebugOverlay = @import("ui/debug_overlay.zig").DebugOverlay;

pub fn main() !void {
    // Window configuration - fullscreen borderless
    const screen_width = rl.getScreenWidth();
    const screen_height = rl.getScreenHeight();

    // Initialize window
    rl.initWindow(screen_width, screen_height, "Zig Game - Hex Grid Prototype");
    defer rl.closeWindow();

    // Toggle fullscreen for borderless fullscreen
    rl.toggleBorderlessWindowed();

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

    // Initialize debug overlay
    var debug_overlay = DebugOverlay.init();

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
        // Scale by delta time for frame-rate independence
        const base_speed = 400.0; // pixels per second
        const pan_speed = base_speed * rl.getFrameTime();
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

        // Toggle debug overlay with F3
        if (rl.isKeyPressed(rl.KeyboardKey.f3)) {
            debug_overlay.toggle();
        }

        // Update debug overlay
        debug_overlay.update();

        last_mouse_pos = mouse_pos;

        // Draw
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.init(30, 30, 40, 255));

        // Draw hex grid
        renderer.drawGrid(&grid, screen_width, screen_height);

        // Draw UI
        rl.drawText("Zig Game - Phase 1: Hex Grid", 10, 180, 20, rl.Color.ray_white);
        rl.drawText("WASD/Arrows: Pan  |  Wheel/+/-: Zoom  |  R: Reset  |  F3: Debug  |  ESC: Exit", 10, 210, 14, rl.Color.light_gray);

        // Draw camera info
        const cam_y = screen_height - 60;
        var buf: [100:0]u8 = undefined;
        const info = std.fmt.bufPrintZ(&buf, "Camera: ({d:.0}, {d:.0}) Zoom: {d:.2}x", .{
            renderer.camera.x,
            renderer.camera.y,
            renderer.camera.zoom,
        }) catch "Error";
        rl.drawText(info, 10, cam_y, 14, rl.Color.green);

        // Draw tile count
        var buf2: [100:0]u8 = undefined;
        const count_text = std.fmt.bufPrintZ(&buf2, "Tiles: {d}", .{grid.count()}) catch "Error";
        rl.drawText(count_text, 10, cam_y + 20, 14, rl.Color.green);

        // Draw debug overlay (uses entity count = tile count for now, tick_rate = null)
        debug_overlay.draw(grid.count(), null);
    }
}

test "basic functionality" {
    try std.testing.expect(true);
}
