const std = @import("std");
const rl = @import("raylib");
const HexCoord = @import("../world/hex_grid.zig").HexCoord;
const HexGrid = @import("../world/hex_grid.zig").HexGrid;
const HexLayout = @import("../rendering/hex_renderer.zig").HexLayout;
const Camera = @import("../rendering/hex_renderer.zig").Camera;

/// Tile selection and hover tracking system
/// Manages which tile is currently hovered or selected by the player
pub const TileSelector = struct {
    hovered_tile: ?HexCoord, // Currently hovered tile (null if none)
    selected_tile: ?HexCoord, // Currently selected tile (null if none)

    /// Initialize tile selector with no selection or hover
    pub fn init() TileSelector {
        return TileSelector{
            .hovered_tile = null,
            .selected_tile = null,
        };
    }

    /// Update tile hover and selection based on mouse input
    /// Call this every frame to track mouse position over tiles
    pub fn update(
        self: *TileSelector,
        mouse_pos: rl.Vector2,
        left_click: bool,
        grid: *HexGrid,
        camera: *const Camera,
        layout: *const HexLayout,
        screen_width: i32,
        screen_height: i32,
    ) void {
        // Convert mouse screen position to world position
        const world_pos = camera.screenToWorld(mouse_pos.x, mouse_pos.y, screen_width, screen_height);

        // Convert world position to hex coordinate
        const hex_coord = layout.pixelToHex(world_pos);

        // Check if this coordinate has a tile in the grid
        if (grid.getTile(hex_coord)) |_| {
            // Valid tile - update hover
            self.hovered_tile = hex_coord;

            // If left click, select this tile
            if (left_click) {
                self.selected_tile = hex_coord;
            }
        } else {
            // No tile at this position - clear hover
            self.hovered_tile = null;

            // If left click on empty space, deselect
            if (left_click) {
                self.selected_tile = null;
            }
        }
    }

    /// Get the currently hovered tile coordinate (null if none)
    pub fn getHovered(self: *const TileSelector) ?HexCoord {
        return self.hovered_tile;
    }

    /// Get the currently selected tile coordinate (null if none)
    pub fn getSelected(self: *const TileSelector) ?HexCoord {
        return self.selected_tile;
    }

    /// Check if a specific tile is currently hovered
    pub fn isHovered(self: *const TileSelector, coord: HexCoord) bool {
        if (self.hovered_tile) |hovered| {
            return hovered.q == coord.q and hovered.r == coord.r;
        }
        return false;
    }

    /// Check if a specific tile is currently selected
    pub fn isSelected(self: *const TileSelector, coord: HexCoord) bool {
        if (self.selected_tile) |selected| {
            return selected.q == coord.q and selected.r == coord.r;
        }
        return false;
    }

    /// Check if any tile is currently hovered
    pub fn hasHover(self: *const TileSelector) bool {
        return self.hovered_tile != null;
    }

    /// Check if any tile is currently selected
    pub fn hasSelection(self: *const TileSelector) bool {
        return self.selected_tile != null;
    }

    /// Clear the current selection
    pub fn clearSelection(self: *TileSelector) void {
        self.selected_tile = null;
    }

    /// Clear the current hover
    pub fn clearHover(self: *TileSelector) void {
        self.hovered_tile = null;
    }
};

// ============================================================================
// TESTS
// ============================================================================

test "TileSelector.init creates empty state" {
    const selector = TileSelector.init();

    try std.testing.expect(!selector.hasHover());
    try std.testing.expect(!selector.hasSelection());
    try std.testing.expect(selector.getHovered() == null);
    try std.testing.expect(selector.getSelected() == null);
}

test "TileSelector.update sets hover on valid tile" {
    const allocator = std.testing.allocator;
    var grid = HexGrid.init(allocator);
    defer grid.deinit();

    // Create a simple grid
    try grid.createRect(5, 5);

    var selector = TileSelector.init();
    const camera = Camera.init();
    const layout = HexLayout.init(30.0, true);

    // Simulate mouse at tile (2, 2)
    const tile_coord = HexCoord{ .q = 2, .r = 2 };
    const world_pos = layout.hexToPixel(tile_coord);
    const screen_pos = camera.worldToScreen(world_pos.x, world_pos.y, 800, 600);
    const mouse_pos = rl.Vector2{ .x = screen_pos.x, .y = screen_pos.y };

    selector.update(mouse_pos, false, &grid, &camera, &layout, 800, 600);

    try std.testing.expect(selector.hasHover());
    try std.testing.expect(selector.isHovered(tile_coord));
}

test "TileSelector.update selects tile on click" {
    const allocator = std.testing.allocator;
    var grid = HexGrid.init(allocator);
    defer grid.deinit();

    try grid.createRect(5, 5);

    var selector = TileSelector.init();
    const camera = Camera.init();
    const layout = HexLayout.init(30.0, true);

    const tile_coord = HexCoord{ .q = 3, .r = 1 };
    const world_pos = layout.hexToPixel(tile_coord);
    const screen_pos = camera.worldToScreen(world_pos.x, world_pos.y, 800, 600);
    const mouse_pos = rl.Vector2{ .x = screen_pos.x, .y = screen_pos.y };

    // First frame: hover without click
    selector.update(mouse_pos, false, &grid, &camera, &layout, 800, 600);
    try std.testing.expect(selector.hasHover());
    try std.testing.expect(!selector.hasSelection());

    // Second frame: click
    selector.update(mouse_pos, true, &grid, &camera, &layout, 800, 600);
    try std.testing.expect(selector.hasSelection());
    try std.testing.expect(selector.isSelected(tile_coord));
}

test "TileSelector.clearSelection removes selection" {
    var selector = TileSelector.init();
    selector.selected_tile = HexCoord{ .q = 5, .r = 5 };

    try std.testing.expect(selector.hasSelection());

    selector.clearSelection();

    try std.testing.expect(!selector.hasSelection());
}

test "TileSelector.clearHover removes hover" {
    var selector = TileSelector.init();
    selector.hovered_tile = HexCoord{ .q = 3, .r = 3 };

    try std.testing.expect(selector.hasHover());

    selector.clearHover();

    try std.testing.expect(!selector.hasHover());
}

test "TileSelector.update clears hover on empty space" {
    const allocator = std.testing.allocator;
    var grid = HexGrid.init(allocator);
    defer grid.deinit();

    // Small grid (3x3)
    try grid.createRect(3, 3);

    var selector = TileSelector.init();
    selector.hovered_tile = HexCoord{ .q = 1, .r = 1 }; // Preset hover

    const camera = Camera.init();
    const layout = HexLayout.init(30.0, true);

    // Mouse at position far outside the grid
    const far_coord = HexCoord{ .q = 100, .r = 100 };
    const world_pos = layout.hexToPixel(far_coord);
    const screen_pos = camera.worldToScreen(world_pos.x, world_pos.y, 800, 600);
    const mouse_pos = rl.Vector2{ .x = screen_pos.x, .y = screen_pos.y };

    selector.update(mouse_pos, false, &grid, &camera, &layout, 800, 600);

    try std.testing.expect(!selector.hasHover());
}

test "TileSelector.update deselects on empty click" {
    const allocator = std.testing.allocator;
    var grid = HexGrid.init(allocator);
    defer grid.deinit();

    try grid.createRect(3, 3);

    var selector = TileSelector.init();
    selector.selected_tile = HexCoord{ .q = 1, .r = 1 }; // Preset selection

    const camera = Camera.init();
    const layout = HexLayout.init(30.0, true);

    // Click on empty space
    const far_coord = HexCoord{ .q = 100, .r = 100 };
    const world_pos = layout.hexToPixel(far_coord);
    const screen_pos = camera.worldToScreen(world_pos.x, world_pos.y, 800, 600);
    const mouse_pos = rl.Vector2{ .x = screen_pos.x, .y = screen_pos.y };

    selector.update(mouse_pos, true, &grid, &camera, &layout, 800, 600);

    try std.testing.expect(!selector.hasSelection());
}

test "TileSelector.isHovered returns false for wrong tile" {
    var selector = TileSelector.init();
    selector.hovered_tile = HexCoord{ .q = 2, .r = 3 };

    try std.testing.expect(selector.isHovered(HexCoord{ .q = 2, .r = 3 }));
    try std.testing.expect(!selector.isHovered(HexCoord{ .q = 3, .r = 2 }));
}
