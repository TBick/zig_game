const std = @import("std");
const rl = @import("raylib");
const HexGrid = @import("world/hex_grid.zig").HexGrid;
const HexRenderer = @import("rendering/hex_renderer.zig").HexRenderer;
const DebugOverlay = @import("ui/debug_overlay.zig").DebugOverlay;

// Entity system imports
const Entity = @import("entities/entity.zig").Entity;
const EntityId = @import("entities/entity.zig").EntityId;
const EntityRole = @import("entities/entity.zig").EntityRole;
const EntityManager = @import("entities/entity_manager.zig").EntityManager;
const EntityRenderer = @import("rendering/entity_renderer.zig").EntityRenderer;
const HexCoord = @import("world/hex_grid.zig").HexCoord;

// Core system imports
const TickScheduler = @import("core/tick_scheduler.zig").TickScheduler;

// Input and UI imports
const EntitySelector = @import("input/entity_selector.zig").EntitySelector;
const EntityInfoPanel = @import("ui/entity_info_panel.zig").EntityInfoPanel;
const InputHandler = @import("input/input_handler.zig").InputHandler;

// Rendering coordinator
const GameRenderer = @import("rendering/game_renderer.zig").GameRenderer;

// Test discovery: Ensure all module tests are included
test {
    std.testing.refAllDecls(@This());
    std.testing.refAllDecls(@import("entities/entity.zig"));
    std.testing.refAllDecls(@import("entities/entity_manager.zig"));
    std.testing.refAllDecls(@import("rendering/entity_renderer.zig"));
    std.testing.refAllDecls(@import("rendering/game_renderer.zig"));
    std.testing.refAllDecls(@import("core/tick_scheduler.zig"));
    std.testing.refAllDecls(@import("input/entity_selector.zig"));
    std.testing.refAllDecls(@import("input/tile_selector.zig"));
    std.testing.refAllDecls(@import("input/input_handler.zig"));
    std.testing.refAllDecls(@import("ui/entity_info_panel.zig"));
    std.testing.refAllDecls(@import("ui/ui_manager.zig"));
}

pub fn main() !void {
    // Enable VSync before window initialization to prevent screen tearing
    rl.setConfigFlags(rl.ConfigFlags{ .vsync_hint = true });

    // Initialize window at a default size first
    rl.initWindow(800, 600, "Zig Game - Hex Grid Prototype");
    defer rl.closeWindow();

    // NOW get monitor dimensions and set window to fullscreen size
    const monitor = rl.getCurrentMonitor();
    const screen_width = rl.getMonitorWidth(monitor);
    const screen_height = rl.getMonitorHeight(monitor);

    // Resize window to match monitor, then toggle borderless fullscreen
    rl.setWindowSize(screen_width, screen_height);
    rl.toggleBorderlessWindowed();

    // VSync doesn't work properly in WSL2/WSLg, so use setTargetFPS for consistent frame pacing
    rl.setTargetFPS(60);

    // Initialize hex grid
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var grid = HexGrid.init(allocator);
    defer grid.deinit();

    // Create a 10x10 hex grid
    try grid.createRect(10, 10);

    // Initialize renderers
    var hex_renderer = HexRenderer.init(30.0); // 30 pixel hex size
    var entity_renderer = EntityRenderer.init(12.0); // 12 pixel entity radius

    // Initialize entity manager
    var entity_manager = try EntityManager.init(allocator);
    defer entity_manager.deinit();

    // Spawn some test entities
    _ = try entity_manager.spawn(HexCoord{ .q = 2, .r = 2 }, .worker);
    _ = try entity_manager.spawn(HexCoord{ .q = 5, .r = 3 }, .combat);
    _ = try entity_manager.spawn(HexCoord{ .q = 7, .r = 5 }, .scout);
    _ = try entity_manager.spawn(HexCoord{ .q = 3, .r = 7 }, .engineer);

    // Initialize tick scheduler (2.5 ticks per second)
    var tick_scheduler = TickScheduler.init(2.5);

    // Initialize debug overlay
    var debug_overlay = DebugOverlay.init();

    // Initialize input handler (replaces entity_selector, last_mouse_pos, and all input code)
    var input_handler = InputHandler.init(&hex_renderer.camera);
    var info_panel = EntityInfoPanel.init(10, 250, 250, 200);

    // Initialize game renderer (coordinates all rendering)
    var game_renderer = GameRenderer.init(
        &hex_renderer,
        &entity_renderer,
        &debug_overlay,
        &info_panel,
    );

    // Main game loop
    while (!rl.windowShouldClose()) {
        // ====================================================================
        // TICK PROCESSING (Game Logic at Fixed Rate)
        // ====================================================================

        const frame_time = rl.getFrameTime();
        const ticks_to_process = tick_scheduler.update(@floatCast(frame_time));

        // Process each tick (game logic runs at fixed rate)
        var i: u32 = 0;
        while (i < ticks_to_process) : (i += 1) {
            processTick(&entity_manager, &tick_scheduler);
        }

        // ====================================================================
        // INPUT (Runs every frame for smooth response)
        // ====================================================================

        // Get current window dimensions for coordinate transformations
        const current_width = rl.getScreenWidth();
        const current_height = rl.getScreenHeight();

        // Centralized input handling (camera, tile selection, entity selection, debug)
        input_handler.update(
            @floatCast(frame_time),
            &entity_manager,
            &grid,
            &hex_renderer.layout,
            &debug_overlay,
            current_width,
            current_height,
        );

        // ====================================================================
        // RENDERING (Runs every frame at 60 FPS)
        // ====================================================================
        rl.beginDrawing();
        defer rl.endDrawing();

        // Render everything through the game renderer
        game_renderer.render(
            &grid,
            &entity_manager,
            &input_handler,
            &tick_scheduler,
            current_width,
            current_height,
        );
    }
}

/// Process one tick of game logic
fn processTick(entity_manager: *EntityManager, tick_scheduler: *TickScheduler) void {
    _ = entity_manager;
    _ = tick_scheduler;

    // TODO: Implement game logic here
    // - Execute Lua scripts for entities
    // - Process entity actions
    // - Update world state
    // - Handle resource distribution
}

test "basic functionality" {
    try std.testing.expect(true);
}
