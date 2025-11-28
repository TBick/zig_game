const std = @import("std");
const rl = @import("raylib");
const HexRenderer = @import("hex_renderer.zig").HexRenderer;
const EntityRenderer = @import("entity_renderer.zig").EntityRenderer;
const DebugOverlay = @import("../ui/debug_overlay.zig").DebugOverlay;
const EntityInfoPanel = @import("../ui/entity_info_panel.zig").EntityInfoPanel;
const UIManager = @import("../ui/ui_manager.zig").UIManager;
const HexGrid = @import("../world/hex_grid.zig").HexGrid;
const HexCoord = @import("../world/hex_grid.zig").HexCoord;
const EntityManager = @import("../entities/entity_manager.zig").EntityManager;
const InputHandler = @import("../input/input_handler.zig").InputHandler;
const TickScheduler = @import("../core/tick_scheduler.zig").TickScheduler;
const Camera = @import("hex_renderer.zig").Camera;
const HexLayout = @import("hex_renderer.zig").HexLayout;

/// Central rendering coordinator
/// Orchestrates all rendering in correct layer order (world → UI)
pub const GameRenderer = struct {
    // References to renderers (not owned - created in main)
    hex_renderer: *HexRenderer,
    entity_renderer: *EntityRenderer,
    debug_overlay: *DebugOverlay,
    info_panel: *EntityInfoPanel,

    // Owned stateless renderer
    ui_manager: UIManager,

    /// Initialize the game renderer with references to existing renderers
    pub fn init(
        hex_renderer: *HexRenderer,
        entity_renderer: *EntityRenderer,
        debug_overlay: *DebugOverlay,
        info_panel: *EntityInfoPanel,
    ) GameRenderer {
        return GameRenderer{
            .hex_renderer = hex_renderer,
            .entity_renderer = entity_renderer,
            .debug_overlay = debug_overlay,
            .info_panel = info_panel,
            .ui_manager = UIManager.init(),
        };
    }

    /// Main render method - orchestrates all rendering
    /// Replaces all rendering code in main.zig
    pub fn render(
        self: *GameRenderer,
        grid: *HexGrid,
        entity_manager: *EntityManager,
        input_handler: *const InputHandler,
        tick_scheduler: *const TickScheduler,
        screen_width: i32,
        screen_height: i32,
    ) void {
        // Clear background
        rl.clearBackground(rl.Color.init(30, 30, 40, 255));

        // Render world layer (tiles, entities)
        self.renderTiles(grid, input_handler, screen_width, screen_height);
        self.renderEntities(entity_manager, input_handler, screen_width, screen_height);

        // Render UI layer (text, panels, debug)
        self.renderUI(grid, entity_manager, input_handler, tick_scheduler, screen_width, screen_height);
    }

    /// Render all tiles with hover/selection highlighting
    fn renderTiles(
        self: *GameRenderer,
        grid: *const HexGrid,
        input_handler: *const InputHandler,
        screen_width: i32,
        screen_height: i32,
    ) void {
        const hovered_tile = input_handler.getHoveredTile();
        const selected_tile = input_handler.getSelectedTile();

        var it = grid.tiles.iterator();
        while (it.next()) |entry| {
            const coord = entry.key_ptr.*;

            // Determine tile state for visual feedback
            const is_selected = if (selected_tile) |sel| sel.q == coord.q and sel.r == coord.r else false;
            const is_hovered = if (hovered_tile) |hov| hov.q == coord.q and hov.r == coord.r else false;

            // Get colors based on state (centralized logic)
            const colors = getTileColors(is_selected, is_hovered);

            // Draw tile with state-appropriate colors
            self.hex_renderer.drawHexFilled(coord, colors.fill, screen_width, screen_height);
            self.hex_renderer.drawHexOutline(coord, colors.outline, screen_width, screen_height);
        }
    }

    /// Render all entities with hover/selection highlighting
    fn renderEntities(
        self: *GameRenderer,
        entity_manager: *EntityManager,
        input_handler: *const InputHandler,
        screen_width: i32,
        screen_height: i32,
    ) void {
        const selected_entity = input_handler.getSelectedEntity(entity_manager);
        const hovered_entity = input_handler.getHoveredEntity(entity_manager);

        for (entity_manager.getAliveEntities()) |*entity| {
            const is_selected = if (selected_entity) |sel| sel.id == entity.id else false;
            const is_hovered = if (hovered_entity) |hov| hov.id == entity.id else false;

            // Show highlight ring for both hover and selection
            const show_highlight = is_selected or is_hovered;

            self.entity_renderer.drawEntityWithSelection(
                entity,
                show_highlight,
                &self.hex_renderer.camera,
                &self.hex_renderer.layout,
                screen_width,
                screen_height,
            );
        }
    }

    /// Render all UI elements (text, panels, debug)
    fn renderUI(
        self: *GameRenderer,
        grid: *HexGrid,
        entity_manager: *EntityManager,
        input_handler: *const InputHandler,
        tick_scheduler: *const TickScheduler,
        screen_width: i32,
        screen_height: i32,
    ) void {
        // Render UI text (help, camera info, counts, tick)
        self.ui_manager.draw(
            &self.hex_renderer.camera,
            entity_manager.getAliveCount(),
            grid.count(),
            tick_scheduler.getCurrentTick(),
            @floatCast(tick_scheduler.getTickRate()),
            screen_width,
            screen_height,
        );

        // Render debug overlay (toggleable with F3)
        self.debug_overlay.draw(entity_manager.getAliveCount(), @floatCast(tick_scheduler.getTickRate()));

        // Render entity info panel (bottom-left)
        const selected_entity = input_handler.getSelectedEntity(entity_manager);
        self.info_panel.draw(selected_entity, tick_scheduler.getCurrentTick());
    }
};

/// Get tile fill and outline colors based on hover/selection state
/// Centralized color logic - single source of truth
fn getTileColors(is_selected: bool, is_hovered: bool) struct { fill: rl.Color, outline: rl.Color } {
    if (is_selected) {
        return .{
            .fill = rl.Color.init(80, 120, 180, 255), // Selected: blue fill
            .outline = rl.Color.init(120, 180, 255, 255), // Selected: bright blue outline
        };
    }
    if (is_hovered) {
        return .{
            .fill = rl.Color.init(70, 70, 90, 255), // Hovered: lighter gray fill
            .outline = rl.Color.init(150, 150, 170, 255), // Hovered: bright gray outline
        };
    }
    // Normal state
    return .{
        .fill = rl.Color.dark_gray, // Normal: dark gray fill
        .outline = rl.Color.light_gray, // Normal: light gray outline
    };
}

// ============================================================================
// Tests
// ============================================================================

test "GameRenderer.init creates valid instance" {
    // Create mock renderers (just for structure, no actual rendering)
    var hex_renderer = HexRenderer.init(30.0);
    var entity_renderer = EntityRenderer.init(12.0);
    var debug_overlay = DebugOverlay.init();
    var info_panel = EntityInfoPanel.init(10, 250, 250, 200);

    const game_renderer = GameRenderer.init(
        &hex_renderer,
        &entity_renderer,
        &debug_overlay,
        &info_panel,
    );

    // Verify references are stored correctly
    try std.testing.expect(game_renderer.hex_renderer == &hex_renderer);
    try std.testing.expect(game_renderer.entity_renderer == &entity_renderer);
}

test "GameRenderer stores references not ownership" {
    var hex_renderer = HexRenderer.init(30.0);
    var entity_renderer = EntityRenderer.init(12.0);
    var debug_overlay = DebugOverlay.init();
    var info_panel = EntityInfoPanel.init(10, 250, 250, 200);

    const game_renderer = GameRenderer.init(
        &hex_renderer,
        &entity_renderer,
        &debug_overlay,
        &info_panel,
    );

    // Verify we can still access original renderers
    _ = hex_renderer.camera.x;
    _ = game_renderer.hex_renderer.camera.x;
}

test "getTileColors returns correct colors for selected state" {
    const colors = getTileColors(true, false);

    // Selected should be blue
    try std.testing.expectEqual(@as(u8, 80), colors.fill.r);
    try std.testing.expectEqual(@as(u8, 120), colors.fill.g);
    try std.testing.expectEqual(@as(u8, 180), colors.fill.b);

    try std.testing.expectEqual(@as(u8, 120), colors.outline.r);
    try std.testing.expectEqual(@as(u8, 180), colors.outline.g);
    try std.testing.expectEqual(@as(u8, 255), colors.outline.b);
}

test "getTileColors returns correct colors for hovered state" {
    const colors = getTileColors(false, true);

    // Hovered should be lighter gray
    try std.testing.expectEqual(@as(u8, 70), colors.fill.r);
    try std.testing.expectEqual(@as(u8, 70), colors.fill.g);
    try std.testing.expectEqual(@as(u8, 90), colors.fill.b);

    try std.testing.expectEqual(@as(u8, 150), colors.outline.r);
    try std.testing.expectEqual(@as(u8, 150), colors.outline.g);
    try std.testing.expectEqual(@as(u8, 170), colors.outline.b);
}

test "getTileColors returns correct colors for normal state" {
    const colors = getTileColors(false, false);

    // Normal should be dark gray
    try std.testing.expectEqual(rl.Color.dark_gray.r, colors.fill.r);
    try std.testing.expectEqual(rl.Color.dark_gray.g, colors.fill.g);
    try std.testing.expectEqual(rl.Color.dark_gray.b, colors.fill.b);

    try std.testing.expectEqual(rl.Color.light_gray.r, colors.outline.r);
    try std.testing.expectEqual(rl.Color.light_gray.g, colors.outline.g);
    try std.testing.expectEqual(rl.Color.light_gray.b, colors.outline.b);
}

test "getTileColors prioritizes selected over hovered" {
    // When both selected and hovered, selected takes precedence
    const colors = getTileColors(true, true);

    // Should return selected colors (blue), not hovered (gray)
    try std.testing.expectEqual(@as(u8, 80), colors.fill.r);
    try std.testing.expectEqual(@as(u8, 120), colors.fill.g);
    try std.testing.expectEqual(@as(u8, 180), colors.fill.b);
}
