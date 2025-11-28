const std = @import("std");
const rl = @import("raylib");
const Entity = @import("../entities/entity.zig").Entity;
const EntityId = @import("../entities/entity.zig").EntityId;
const EntityManager = @import("../entities/entity_manager.zig").EntityManager;
const HexCoord = @import("../world/hex_grid.zig").HexCoord;
const Camera = @import("../rendering/hex_renderer.zig").Camera;
const HexLayout = @import("../rendering/hex_renderer.zig").HexLayout;

/// Handles entity selection and hover detection via mouse input
pub const EntitySelector = struct {
    selected_entity_id: ?EntityId,
    hovered_entity_id: ?EntityId,

    /// Initialize entity selector with no selection or hover
    pub fn init() EntitySelector {
        return EntitySelector{
            .selected_entity_id = null,
            .hovered_entity_id = null,
        };
    }

    /// Update selection and hover based on mouse input
    /// Call this each frame after processing camera input
    pub fn update(
        self: *EntitySelector,
        mouse_pos: rl.Vector2,
        mouse_clicked: bool,
        entity_manager: *EntityManager,
        camera: *const Camera,
        layout: *const HexLayout,
        screen_width: i32,
        screen_height: i32,
    ) void {
        // Convert screen position to world position
        const world_pos = camera.screenToWorld(mouse_pos.x, mouse_pos.y, screen_width, screen_height);

        // Convert world position to hex coordinate
        const hex_coord = layout.pixelToHex(world_pos);

        // Query entities at this hex position
        // Use a small buffer (max 10 entities per hex, which should be plenty)
        var entity_ids: [10]EntityId = undefined;
        const entity_count = entity_manager.getEntitiesAt(hex_coord, &entity_ids);

        // Update hover state (every frame)
        if (entity_count > 0) {
            self.hovered_entity_id = entity_ids[0];
        } else {
            self.hovered_entity_id = null;
        }

        // Update selection state (only on click)
        if (mouse_clicked) {
            if (entity_count > 0) {
                // Select the first entity at this position
                self.selected_entity_id = entity_ids[0];
            } else {
                // Clicked on empty space - deselect
                self.selected_entity_id = null;
            }
        }
    }

    /// Get the currently selected entity
    /// Returns null if no entity is selected or if the selected entity no longer exists
    pub fn getSelected(self: *const EntitySelector, manager: *EntityManager) ?*Entity {
        if (self.selected_entity_id) |id| {
            return manager.getEntity(id);
        }
        return null;
    }

    /// Clear the current selection
    pub fn deselect(self: *EntitySelector) void {
        self.selected_entity_id = null;
    }

    /// Check if an entity is currently selected
    pub fn hasSelection(self: *const EntitySelector) bool {
        return self.selected_entity_id != null;
    }

    /// Check if a specific entity is selected
    pub fn isSelected(self: *const EntitySelector, entity_id: EntityId) bool {
        if (self.selected_entity_id) |id| {
            return id == entity_id;
        }
        return false;
    }

    /// Get the currently hovered entity
    /// Returns null if no entity is hovered or if the hovered entity no longer exists
    pub fn getHovered(self: *const EntitySelector, manager: *EntityManager) ?*Entity {
        if (self.hovered_entity_id) |id| {
            return manager.getEntity(id);
        }
        return null;
    }

    /// Check if any entity is currently hovered
    pub fn hasHover(self: *const EntitySelector) bool {
        return self.hovered_entity_id != null;
    }

    /// Check if a specific entity is hovered
    pub fn isHovered(self: *const EntitySelector, entity_id: EntityId) bool {
        if (self.hovered_entity_id) |id| {
            return id == entity_id;
        }
        return false;
    }

    /// Clear the current hover
    pub fn clearHover(self: *EntitySelector) void {
        self.hovered_entity_id = null;
    }
};

// ============================================================================
// Tests
// ============================================================================

test "EntitySelector.init" {
    const selector = EntitySelector.init();
    try std.testing.expect(!selector.hasSelection());
    try std.testing.expect(!selector.hasHover());
    try std.testing.expectEqual(@as(?EntityId, null), selector.selected_entity_id);
    try std.testing.expectEqual(@as(?EntityId, null), selector.hovered_entity_id);
}

test "EntitySelector.deselect" {
    var selector = EntitySelector.init();
    selector.selected_entity_id = 42;

    selector.deselect();
    try std.testing.expect(!selector.hasSelection());
    try std.testing.expectEqual(@as(?EntityId, null), selector.selected_entity_id);
}

test "EntitySelector.hasSelection" {
    var selector = EntitySelector.init();
    try std.testing.expect(!selector.hasSelection());

    selector.selected_entity_id = 1;
    try std.testing.expect(selector.hasSelection());

    selector.selected_entity_id = null;
    try std.testing.expect(!selector.hasSelection());
}

test "EntitySelector.isSelected" {
    var selector = EntitySelector.init();

    // No selection
    try std.testing.expect(!selector.isSelected(1));
    try std.testing.expect(!selector.isSelected(2));

    // Select entity 1
    selector.selected_entity_id = 1;
    try std.testing.expect(selector.isSelected(1));
    try std.testing.expect(!selector.isSelected(2));

    // Select entity 2
    selector.selected_entity_id = 2;
    try std.testing.expect(!selector.isSelected(1));
    try std.testing.expect(selector.isSelected(2));
}

test "EntitySelector.getSelected with no selection" {
    const allocator = std.testing.allocator;
    var manager = try EntityManager.init(allocator);
    defer manager.deinit();

    const selector = EntitySelector.init();
    const result = selector.getSelected(&manager);

    try std.testing.expectEqual(@as(?*Entity, null), result);
}

test "EntitySelector.getSelected with valid selection" {
    const allocator = std.testing.allocator;
    var manager = try EntityManager.init(allocator);
    defer manager.deinit();

    // Spawn an entity
    const entity_id = try manager.spawn(HexCoord.init(0, 0), .worker);

    // Select it
    var selector = EntitySelector.init();
    selector.selected_entity_id = entity_id;

    // Retrieve it
    const result = selector.getSelected(&manager);
    try std.testing.expect(result != null);
    try std.testing.expectEqual(entity_id, result.?.id);
}

test "EntitySelector.getSelected with destroyed entity" {
    const allocator = std.testing.allocator;
    var manager = try EntityManager.init(allocator);
    defer manager.deinit();

    // Spawn and then destroy an entity
    const entity_id = try manager.spawn(HexCoord.init(0, 0), .worker);
    _ = manager.destroy(entity_id);

    // Try to get the destroyed entity
    var selector = EntitySelector.init();
    selector.selected_entity_id = entity_id;

    const result = selector.getSelected(&manager);
    try std.testing.expectEqual(@as(?*Entity, null), result);
}

test "EntitySelector.update with click on entity" {
    const allocator = std.testing.allocator;
    var manager = try EntityManager.init(allocator);
    defer manager.deinit();

    // Spawn entity at (1, 1)
    const entity_id = try manager.spawn(HexCoord.init(1, 1), .worker);

    // Setup camera and layout
    const camera = Camera.init();
    const layout = HexLayout.init(30.0, true);

    // Calculate where entity would appear on screen
    const entity_world_pos = layout.hexToPixel(HexCoord.init(1, 1));
    const entity_screen_pos = camera.worldToScreen(entity_world_pos.x, entity_world_pos.y, 800, 600);

    // Click on that position
    var selector = EntitySelector.init();
    selector.update(
        entity_screen_pos,
        true, // mouse clicked
        &manager,
        &camera,
        &layout,
        800,
        600,
    );

    // Should have selected the entity
    try std.testing.expect(selector.hasSelection());
    try std.testing.expectEqual(entity_id, selector.selected_entity_id.?);
}

test "EntitySelector.update with click on empty space" {
    const allocator = std.testing.allocator;
    var manager = try EntityManager.init(allocator);
    defer manager.deinit();

    // Spawn entity at (1, 1)
    _ = try manager.spawn(HexCoord.init(1, 1), .worker);

    // Setup camera and layout
    const camera = Camera.init();
    const layout = HexLayout.init(30.0, true);

    // Pre-select an entity
    var selector = EntitySelector.init();
    selector.selected_entity_id = 1;

    // Click on empty space (hex 5, 5 where no entity exists)
    const empty_world_pos = layout.hexToPixel(HexCoord.init(5, 5));
    const empty_screen_pos = camera.worldToScreen(empty_world_pos.x, empty_world_pos.y, 800, 600);

    selector.update(
        empty_screen_pos,
        true, // mouse clicked
        &manager,
        &camera,
        &layout,
        800,
        600,
    );

    // Should have deselected
    try std.testing.expect(!selector.hasSelection());
    try std.testing.expectEqual(@as(?EntityId, null), selector.selected_entity_id);
}

test "EntitySelector.update with no click" {
    const allocator = std.testing.allocator;
    var manager = try EntityManager.init(allocator);
    defer manager.deinit();

    const camera = Camera.init();
    const layout = HexLayout.init(30.0, true);

    var selector = EntitySelector.init();
    selector.selected_entity_id = 42;

    // Update without click
    selector.update(
        rl.Vector2{ .x = 400.0, .y = 300.0 },
        false, // mouse NOT clicked
        &manager,
        &camera,
        &layout,
        800,
        600,
    );

    // Selection should not change
    try std.testing.expectEqual(@as(?EntityId, 42), selector.selected_entity_id);
}

// ============================================================================
// Hover Tests
// ============================================================================

test "EntitySelector.hasHover" {
    var selector = EntitySelector.init();
    try std.testing.expect(!selector.hasHover());

    selector.hovered_entity_id = 1;
    try std.testing.expect(selector.hasHover());

    selector.hovered_entity_id = null;
    try std.testing.expect(!selector.hasHover());
}

test "EntitySelector.isHovered" {
    var selector = EntitySelector.init();

    // No hover
    try std.testing.expect(!selector.isHovered(1));
    try std.testing.expect(!selector.isHovered(2));

    // Hover entity 1
    selector.hovered_entity_id = 1;
    try std.testing.expect(selector.isHovered(1));
    try std.testing.expect(!selector.isHovered(2));

    // Hover entity 2
    selector.hovered_entity_id = 2;
    try std.testing.expect(!selector.isHovered(1));
    try std.testing.expect(selector.isHovered(2));
}

test "EntitySelector.clearHover" {
    var selector = EntitySelector.init();
    selector.hovered_entity_id = 42;

    selector.clearHover();
    try std.testing.expect(!selector.hasHover());
    try std.testing.expectEqual(@as(?EntityId, null), selector.hovered_entity_id);
}

test "EntitySelector.getHovered with no hover" {
    const allocator = std.testing.allocator;
    var manager = try EntityManager.init(allocator);
    defer manager.deinit();

    const selector = EntitySelector.init();
    try std.testing.expect(selector.getHovered(&manager) == null);
}

test "EntitySelector.getHovered with valid hover" {
    const allocator = std.testing.allocator;
    var manager = try EntityManager.init(allocator);
    defer manager.deinit();

    const id = try manager.spawn(HexCoord{ .q = 0, .r = 0 }, .worker);
    var selector = EntitySelector.init();
    selector.hovered_entity_id = id;

    const entity = selector.getHovered(&manager);
    try std.testing.expect(entity != null);
    try std.testing.expectEqual(id, entity.?.id);
}

test "EntitySelector.update updates hover without click" {
    const allocator = std.testing.allocator;
    var manager = try EntityManager.init(allocator);
    defer manager.deinit();

    // Spawn entity at (2, 3)
    _ = try manager.spawn(HexCoord{ .q = 2, .r = 3 }, .worker);

    const camera = Camera.init();
    const layout = HexLayout.init(30.0, true);

    var selector = EntitySelector.init();

    // Simulate mouse over entity without clicking
    const world_pos = layout.hexToPixel(HexCoord{ .q = 2, .r = 3 });
    const screen_pos = camera.worldToScreen(world_pos.x, world_pos.y, 800, 600);

    selector.update(
        rl.Vector2{ .x = screen_pos.x, .y = screen_pos.y },
        false, // No click
        &manager,
        &camera,
        &layout,
        800,
        600,
    );

    // Hover should be set
    try std.testing.expect(selector.hasHover());
    // Selection should remain null (no click)
    try std.testing.expect(!selector.hasSelection());
}

test "EntitySelector.hover and selection are independent" {
    const allocator = std.testing.allocator;
    var manager = try EntityManager.init(allocator);
    defer manager.deinit();

    const id1 = try manager.spawn(HexCoord{ .q = 1, .r = 1 }, .worker);
    const id2 = try manager.spawn(HexCoord{ .q = 2, .r = 2 }, .combat);

    var selector = EntitySelector.init();
    selector.selected_entity_id = id1;
    selector.hovered_entity_id = id2;

    // Both should be set to different entities
    try std.testing.expect(selector.hasSelection());
    try std.testing.expect(selector.hasHover());
    try std.testing.expect(selector.isSelected(id1));
    try std.testing.expect(selector.isHovered(id2));
    try std.testing.expect(!selector.isSelected(id2));
    try std.testing.expect(!selector.isHovered(id1));
}
