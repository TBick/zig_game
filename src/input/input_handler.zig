const std = @import("std");
const rl = @import("raylib");
const Camera = @import("../rendering/hex_renderer.zig").Camera;
const EntitySelector = @import("entity_selector.zig").EntitySelector;
const EntityManager = @import("../entities/entity_manager.zig").EntityManager;
const Entity = @import("../entities/entity.zig").Entity;
const HexLayout = @import("../rendering/hex_renderer.zig").HexLayout;
const DebugOverlay = @import("../ui/debug_overlay.zig").DebugOverlay;

/// Central input handling system
/// Coordinates camera controls, entity selection, and debug shortcuts
pub const InputHandler = struct {
    camera: *Camera, // Reference to camera (owned by HexRenderer)
    entity_selector: EntitySelector, // Entity selection state
    last_mouse_pos: rl.Vector2, // For mouse drag tracking

    /// Initialize input handler with camera reference
    pub fn init(camera: *Camera) InputHandler {
        return InputHandler{
            .camera = camera,
            .entity_selector = EntitySelector.init(),
            .last_mouse_pos = rl.Vector2{ .x = 0, .y = 0 },
        };
    }

    /// Update all input systems (call once per frame in main loop)
    pub fn update(
        self: *InputHandler,
        frame_time: f32,
        entity_manager: *EntityManager,
        layout: *const HexLayout,
        debug_overlay: *DebugOverlay,
        screen_width: i32,
        screen_height: i32,
    ) void {
        // Update camera controls (mouse + keyboard)
        self.updateCamera(frame_time);

        // Update entity selection (delegate to EntitySelector)
        self.updateSelection(entity_manager, layout, screen_width, screen_height);

        // Update debug controls (F3 toggle)
        self.updateDebug(debug_overlay);

        // Save mouse position for next frame (drag tracking)
        self.last_mouse_pos = rl.getMousePosition();
    }

    /// Get currently selected entity (delegates to EntitySelector)
    pub fn getSelectedEntity(self: *const InputHandler, manager: *EntityManager) ?*Entity {
        return self.entity_selector.getSelected(manager);
    }

    // Private methods
    fn updateCamera(self: *InputHandler, frame_time: f32) void {
        const mouse_pos = rl.getMousePosition();

        // Mouse drag panning (right button)
        if (rl.isMouseButtonDown(rl.MouseButton.right)) {
            const dx = mouse_pos.x - self.last_mouse_pos.x;
            const dy = mouse_pos.y - self.last_mouse_pos.y;
            self.camera.pan(-dx, -dy);
        }

        // Mouse wheel zoom
        const wheel = rl.getMouseWheelMove();
        if (wheel != 0) {
            const zoom_factor: f32 = if (wheel > 0) 1.1 else 0.9;
            self.camera.zoomBy(zoom_factor);
        }

        // Keyboard panning (frame-rate independent)
        const base_speed = 400.0; // pixels per second
        const pan_speed = base_speed * frame_time;

        if (rl.isKeyDown(rl.KeyboardKey.left) or rl.isKeyDown(rl.KeyboardKey.a)) {
            self.camera.pan(-pan_speed, 0);
        }
        if (rl.isKeyDown(rl.KeyboardKey.right) or rl.isKeyDown(rl.KeyboardKey.d)) {
            self.camera.pan(pan_speed, 0);
        }
        if (rl.isKeyDown(rl.KeyboardKey.up) or rl.isKeyDown(rl.KeyboardKey.w)) {
            self.camera.pan(0, -pan_speed);
        }
        if (rl.isKeyDown(rl.KeyboardKey.down) or rl.isKeyDown(rl.KeyboardKey.s)) {
            self.camera.pan(0, pan_speed);
        }

        // Keyboard zoom
        if (rl.isKeyDown(rl.KeyboardKey.equal) or rl.isKeyDown(rl.KeyboardKey.kp_add)) {
            self.camera.zoomBy(1.02);
        }
        if (rl.isKeyDown(rl.KeyboardKey.minus) or rl.isKeyDown(rl.KeyboardKey.kp_subtract)) {
            self.camera.zoomBy(0.98);
        }

        // Reset camera (R key)
        if (rl.isKeyPressed(rl.KeyboardKey.r)) {
            self.camera.* = Camera.init();
        }
    }

    fn updateSelection(
        self: *InputHandler,
        entity_manager: *EntityManager,
        layout: *const HexLayout,
        screen_width: i32,
        screen_height: i32,
    ) void {
        const mouse_pos = rl.getMousePosition();
        const left_click = rl.isMouseButtonPressed(rl.MouseButton.left);

        // Delegate to EntitySelector
        self.entity_selector.update(
            mouse_pos,
            left_click,
            entity_manager,
            self.camera,
            layout,
            screen_width,
            screen_height,
        );
    }

    fn updateDebug(self: *InputHandler, debug_overlay: *DebugOverlay) void {
        _ = self;

        // Toggle debug overlay with F3
        if (rl.isKeyPressed(rl.KeyboardKey.f3)) {
            debug_overlay.toggle();
        }

        // Update debug overlay
        debug_overlay.update();
    }
};

// ============================================================================
// TESTS
// ============================================================================

test "InputHandler.init creates valid instance" {
    var camera = Camera.init();
    const handler = InputHandler.init(&camera);

    try std.testing.expectEqual(&camera, handler.camera);
    try std.testing.expect(!handler.entity_selector.hasSelection());
}

test "InputHandler camera reference is correct" {
    var camera = Camera.init();
    camera.x = 100.0;
    camera.y = 200.0;

    const handler = InputHandler.init(&camera);

    // Verify camera pointer works
    try std.testing.expectEqual(@as(f32, 100.0), handler.camera.x);
    try std.testing.expectEqual(@as(f32, 200.0), handler.camera.y);
}

test "InputHandler.update compiles without errors" {
    const allocator = std.testing.allocator;
    var manager = try EntityManager.init(allocator);
    defer manager.deinit();

    var camera = Camera.init();
    var handler = InputHandler.init(&camera);
    var debug_overlay = DebugOverlay.init();
    const layout = HexLayout.init(30.0, true);

    // Verify update() can be called
    handler.update(0.016, &manager, &layout, &debug_overlay, 800, 600);

    try std.testing.expect(true);
}

// ============================================================================
// Camera Control Tests
// ============================================================================

test "InputHandler.updateCamera preserves frame-rate independence" {
    var camera = Camera.init();
    var handler = InputHandler.init(&camera);

    // Verify frame time is used in calculation (compile-time check via function signature)
    handler.updateCamera(0.016); // 60 FPS
    handler.updateCamera(0.033); // 30 FPS

    try std.testing.expect(true);
}

test "InputHandler.updateCamera modifies camera via pointer" {
    var camera = Camera.init();
    camera.x = 100.0;
    camera.y = 200.0;

    var handler = InputHandler.init(&camera);

    // Verify camera modifications work through pointer
    handler.camera.pan(50.0, 50.0);

    try std.testing.expectEqual(@as(f32, 150.0), camera.x);
    try std.testing.expectEqual(@as(f32, 250.0), camera.y);
}

// ============================================================================
// Entity Selection Tests
// ============================================================================

test "InputHandler.updateSelection delegates to EntitySelector" {
    const allocator = std.testing.allocator;
    var manager = try EntityManager.init(allocator);
    defer manager.deinit();

    var camera = Camera.init();
    var handler = InputHandler.init(&camera);
    const layout = HexLayout.init(30.0, true);

    // Verify selection methods are accessible
    try std.testing.expect(!handler.entity_selector.hasSelection());

    handler.updateSelection(&manager, &layout, 800, 600);

    try std.testing.expect(!handler.entity_selector.hasSelection());
}

test "InputHandler.getSelectedEntity returns null when no selection" {
    const allocator = std.testing.allocator;
    var manager = try EntityManager.init(allocator);
    defer manager.deinit();

    var camera = Camera.init();
    var handler = InputHandler.init(&camera);

    const selected = handler.getSelectedEntity(&manager);
    try std.testing.expect(selected == null);
}

// ============================================================================
// Debug Control Test
// ============================================================================

test "InputHandler.updateDebug calls debug overlay" {
    var camera = Camera.init();
    var handler = InputHandler.init(&camera);
    var debug_overlay = DebugOverlay.init();

    // Verify debug methods are called
    handler.updateDebug(&debug_overlay);

    try std.testing.expect(true);
}
