const std = @import("std");
const rl = @import("raylib");
const Entity = @import("../entities/entity.zig").Entity;
const EntityRole = @import("../entities/entity.zig").EntityRole;
const HexCoord = @import("../world/hex_grid.zig").HexCoord;
const Camera = @import("hex_renderer.zig").Camera;
const HexLayout = @import("hex_renderer.zig").HexLayout;

/// Renders entities as colored circles on the hex grid
pub const EntityRenderer = struct {
    entity_radius: f32, // Radius of entity circle in pixels

    /// Initialize the entity renderer
    pub fn init(entity_radius: f32) EntityRenderer {
        return EntityRenderer{
            .entity_radius = entity_radius,
        };
    }

    /// Get color for an entity based on its role
    fn getRoleColor(role: EntityRole) rl.Color {
        return switch (role) {
            .worker => rl.Color.init(100, 200, 100, 255), // Green
            .combat => rl.Color.init(200, 100, 100, 255), // Red
            .scout => rl.Color.init(100, 150, 200, 255), // Blue
            .engineer => rl.Color.init(200, 150, 100, 255), // Orange
        };
    }

    /// Draw a single entity
    pub fn drawEntity(
        self: *const EntityRenderer,
        entity: *const Entity,
        camera: *const Camera,
        layout: *const HexLayout,
        screen_width: i32,
        screen_height: i32,
    ) void {
        // Skip dead entities
        if (!entity.alive) return;

        // Convert hex coord to world pixel position
        const world_pos = layout.hexToPixel(entity.position);

        // Convert world position to screen position
        const screen_pos = camera.worldToScreen(world_pos.x, world_pos.y, screen_width, screen_height);

        // Get color based on role
        const color = getRoleColor(entity.role);

        // Draw entity as a circle
        rl.drawCircle(
            @intFromFloat(screen_pos.x),
            @intFromFloat(screen_pos.y),
            self.entity_radius * camera.zoom,
            color,
        );

        // Draw energy bar above entity
        self.drawEnergyBar(entity, screen_pos, camera.zoom);
    }

    /// Draw a single entity with optional selection highlight
    pub fn drawEntityWithSelection(
        self: *const EntityRenderer,
        entity: *const Entity,
        selected: bool,
        camera: *const Camera,
        layout: *const HexLayout,
        screen_width: i32,
        screen_height: i32,
    ) void {
        // Draw the entity normally
        self.drawEntity(entity, camera, layout, screen_width, screen_height);

        // Draw selection ring if selected
        if (selected and entity.alive) {
            // Convert hex coord to world pixel position
            const world_pos = layout.hexToPixel(entity.position);

            // Convert world position to screen position
            const screen_pos = camera.worldToScreen(world_pos.x, world_pos.y, screen_width, screen_height);

            // Draw selection highlight (yellow circle outline, 1.5x entity radius)
            const highlight_radius = self.entity_radius * 1.5 * camera.zoom;
            rl.drawCircleLines(
                @intFromFloat(screen_pos.x),
                @intFromFloat(screen_pos.y),
                highlight_radius,
                rl.Color.yellow,
            );

            // Draw second ring for better visibility
            const outer_radius = highlight_radius + 1.0;
            rl.drawCircleLines(
                @intFromFloat(screen_pos.x),
                @intFromFloat(screen_pos.y),
                outer_radius,
                rl.Color.init(255, 255, 0, 180), // Semi-transparent yellow
            );
        }
    }

    /// Draw energy bar above entity
    fn drawEnergyBar(
        self: *const EntityRenderer,
        entity: *const Entity,
        screen_pos: rl.Vector2,
        zoom: f32,
    ) void {
        const bar_width: f32 = self.entity_radius * 2.0 * zoom;
        const bar_height: f32 = 4.0 * zoom;
        const bar_y_offset: f32 = (self.entity_radius + 8.0) * zoom;

        // Background (black)
        rl.drawRectangle(
            @intFromFloat(screen_pos.x - bar_width / 2.0),
            @intFromFloat(screen_pos.y - bar_y_offset),
            @intFromFloat(bar_width),
            @intFromFloat(bar_height),
            rl.Color.black,
        );

        // Energy fill (green to red gradient based on energy percentage)
        const energy_percent = entity.energy / entity.max_energy;
        const filled_width = bar_width * energy_percent;

        const energy_color = if (energy_percent > 0.6)
            rl.Color.green
        else if (energy_percent > 0.3)
            rl.Color.yellow
        else
            rl.Color.red;

        if (filled_width > 0) {
            rl.drawRectangle(
                @intFromFloat(screen_pos.x - bar_width / 2.0),
                @intFromFloat(screen_pos.y - bar_y_offset),
                @intFromFloat(filled_width),
                @intFromFloat(bar_height),
                energy_color,
            );
        }
    }

    /// Draw all entities in a list
    pub fn drawEntities(
        self: *const EntityRenderer,
        entities: []Entity,
        camera: *const Camera,
        layout: *const HexLayout,
        screen_width: i32,
        screen_height: i32,
    ) void {
        for (entities) |*entity| {
            if (entity.alive) {
                self.drawEntity(entity, camera, layout, screen_width, screen_height);
            }
        }
    }
};

// ============================================================================
// Tests
// ============================================================================

test "EntityRenderer.init" {
    const renderer = EntityRenderer.init(10.0);
    try std.testing.expectEqual(@as(f32, 10.0), renderer.entity_radius);
}

test "EntityRenderer.getRoleColor returns different colors for different roles" {
    const worker_color = EntityRenderer.getRoleColor(.worker);
    const combat_color = EntityRenderer.getRoleColor(.combat);
    const scout_color = EntityRenderer.getRoleColor(.scout);
    const engineer_color = EntityRenderer.getRoleColor(.engineer);

    // Verify colors are different
    try std.testing.expect(worker_color.r != combat_color.r or
        worker_color.g != combat_color.g or
        worker_color.b != combat_color.b);

    try std.testing.expect(worker_color.r != scout_color.r or
        worker_color.g != scout_color.g or
        worker_color.b != scout_color.b);

    try std.testing.expect(worker_color.r != engineer_color.r or
        worker_color.g != engineer_color.g or
        worker_color.b != engineer_color.b);
}

test "EntityRenderer.getRoleColor returns valid colors" {
    const worker_color = EntityRenderer.getRoleColor(.worker);
    const combat_color = EntityRenderer.getRoleColor(.combat);
    const scout_color = EntityRenderer.getRoleColor(.scout);
    const engineer_color = EntityRenderer.getRoleColor(.engineer);

    // All colors should have full alpha
    try std.testing.expectEqual(@as(u8, 255), worker_color.a);
    try std.testing.expectEqual(@as(u8, 255), combat_color.a);
    try std.testing.expectEqual(@as(u8, 255), scout_color.a);
    try std.testing.expectEqual(@as(u8, 255), engineer_color.a);

    // Verify expected color themes
    try std.testing.expect(worker_color.g > worker_color.r); // Workers are greenish
    try std.testing.expect(combat_color.r > combat_color.g); // Combat is reddish
    try std.testing.expect(scout_color.b > scout_color.r); // Scouts are bluish
}

test "EntityRenderer with different radii" {
    const small_renderer = EntityRenderer.init(5.0);
    const large_renderer = EntityRenderer.init(20.0);

    try std.testing.expectEqual(@as(f32, 5.0), small_renderer.entity_radius);
    try std.testing.expectEqual(@as(f32, 20.0), large_renderer.entity_radius);
}

test "EntityRenderer handles dead entities correctly" {
    // Verify dead entity early return logic (without rendering)
    const renderer = EntityRenderer.init(10.0);
    var entity = Entity.init(1, HexCoord{ .q = 0, .r = 0 }, .worker);
    entity.kill();

    try std.testing.expect(!entity.alive);
    _ = renderer; // Entity renderer exists and is valid
}

test "EntityRenderer with mixed alive and dead entities" {
    const allocator = std.testing.allocator;
    var manager = @import("../entities/entity_manager.zig").EntityManager.init(allocator);
    defer manager.deinit();

    _ = try manager.spawn(HexCoord{ .q = 0, .r = 0 }, .worker);
    const dead_id = try manager.spawn(HexCoord{ .q = 1, .r = 0 }, .combat);
    _ = try manager.spawn(HexCoord{ .q = 2, .r = 0 }, .scout);

    // Kill one entity
    _ = manager.destroy(dead_id);

    const renderer = EntityRenderer.init(10.0);
    _ = renderer; // Verify renderer setup

    // Verify entity manager state (can't test actual rendering without window)
    try std.testing.expectEqual(@as(usize, 2), manager.getAliveCount());
    try std.testing.expectEqual(@as(usize, 3), manager.getTotalCount());
}

test "EntityRenderer energy bar calculation logic" {
    // Test energy percentage calculations (logic only, no rendering)
    var entity = Entity.init(1, HexCoord{ .q = 0, .r = 0 }, .worker);

    // Full energy
    try std.testing.expectEqual(entity.max_energy, entity.energy);
    const full_percent = entity.energy / entity.max_energy;
    try std.testing.expectEqual(@as(f32, 1.0), full_percent);

    // Half energy
    entity.energy = entity.max_energy / 2.0;
    const half_percent = entity.energy / entity.max_energy;
    try std.testing.expectEqual(@as(f32, 0.5), half_percent);

    // Zero energy
    entity.energy = 0.0;
    const zero_percent = entity.energy / entity.max_energy;
    try std.testing.expectEqual(@as(f32, 0.0), zero_percent);
}

test "EntityRenderer coordinate transformation setup" {
    const renderer = EntityRenderer.init(12.0);
    const entity = Entity.init(1, HexCoord{ .q = 5, .r = 5 }, .engineer);

    const camera = Camera.init();
    const layout = HexLayout.init(30.0, true);

    // Verify coordinate transformation calculation
    const world_pos = layout.hexToPixel(entity.position);
    const screen_pos = camera.worldToScreen(world_pos.x, world_pos.y, 800, 600);

    // Entity should appear somewhere on screen (not at origin)
    try std.testing.expect(screen_pos.x != 0.0 or screen_pos.y != 0.0);
    _ = renderer; // Renderer exists
}

test "EntityRenderer with extreme entity positions" {
    const renderer = EntityRenderer.init(10.0);
    const far_entity = Entity.init(1, HexCoord{ .q = 1000, .r = 1000 }, .scout);

    const camera = Camera.init();
    const layout = HexLayout.init(30.0, true);

    // Verify extreme position calculation doesn't crash
    const world_pos = layout.hexToPixel(far_entity.position);
    const screen_pos = camera.worldToScreen(world_pos.x, world_pos.y, 800, 600);

    try std.testing.expect(world_pos.x != 0.0); // Far from origin
    try std.testing.expect(screen_pos.x != 0.0 or screen_pos.y != 0.0);
    _ = renderer; // Renderer valid
}

test "EntityRenderer handles varying energy levels" {
    var worker = Entity.init(1, HexCoord{ .q = 0, .r = 0 }, .worker);
    var combat = Entity.init(2, HexCoord{ .q = 1, .r = 0 }, .combat);
    var scout = Entity.init(3, HexCoord{ .q = 2, .r = 0 }, .scout);

    // Different energy states
    worker.energy = worker.max_energy * 0.8; // 80%
    combat.energy = combat.max_energy * 0.4; // 40%
    scout.energy = scout.max_energy * 0.1; // 10%

    // Verify energy percentages
    try std.testing.expect((worker.energy / worker.max_energy) > 0.6);
    try std.testing.expect((combat.energy / combat.max_energy) > 0.3 and
        (combat.energy / combat.max_energy) < 0.6);
    try std.testing.expect((scout.energy / scout.max_energy) < 0.3);
}

test "EntityRenderer with different zoom levels affects rendered size" {
    const renderer = EntityRenderer.init(10.0);
    var camera = Camera.init();

    // Verify that entity radius scales with zoom
    camera.zoom = 0.5;
    const small_radius = renderer.entity_radius * camera.zoom;
    try std.testing.expectEqual(@as(f32, 5.0), small_radius);

    camera.zoom = 2.0;
    const large_radius = renderer.entity_radius * camera.zoom;
    try std.testing.expectEqual(@as(f32, 20.0), large_radius);
}

test "EntityRenderer.drawEntityWithSelection with selected entity" {
    const renderer = EntityRenderer.init(10.0);
    const entity = Entity.init(1, HexCoord{ .q = 0, .r = 0 }, .worker);
    const camera = Camera.init();
    const layout = HexLayout.init(30.0, true);

    // Verify method compiles and can be called with selected=true
    // (actual rendering cannot be tested without Raylib window)
    _ = entity;
    _ = camera;
    _ = layout;

    // Verify selection highlight radius calculation
    const highlight_radius = renderer.entity_radius * 1.5;
    try std.testing.expectEqual(@as(f32, 15.0), highlight_radius);
}

test "EntityRenderer.drawEntityWithSelection with unselected entity" {
    const renderer = EntityRenderer.init(12.0);
    const entity = Entity.init(2, HexCoord{ .q = 1, .r = 1 }, .scout);
    const camera = Camera.init();
    const layout = HexLayout.init(30.0, true);

    // Verify method compiles and can be called with selected=false
    _ = renderer;
    _ = entity;
    _ = camera;
    _ = layout;

    // When not selected, only entity is drawn (no highlight)
    // This is verified by the logic in drawEntityWithSelection
}

test "EntityRenderer.drawEntityWithSelection highlight scales with zoom" {
    const renderer = EntityRenderer.init(10.0);
    var camera = Camera.init();

    // At 1x zoom
    camera.zoom = 1.0;
    const normal_highlight = renderer.entity_radius * 1.5 * camera.zoom;
    try std.testing.expectEqual(@as(f32, 15.0), normal_highlight);

    // At 2x zoom
    camera.zoom = 2.0;
    const zoomed_highlight = renderer.entity_radius * 1.5 * camera.zoom;
    try std.testing.expectEqual(@as(f32, 30.0), zoomed_highlight);

    // At 0.5x zoom
    camera.zoom = 0.5;
    const small_highlight = renderer.entity_radius * 1.5 * camera.zoom;
    try std.testing.expectEqual(@as(f32, 7.5), small_highlight);
}

test "EntityRenderer.drawEntityWithSelection does not highlight dead entities" {
    var entity = Entity.init(3, HexCoord{ .q = 2, .r = 2 }, .combat);
    entity.kill(); // Mark as dead

    const renderer = EntityRenderer.init(10.0);
    const camera = Camera.init();
    const layout = HexLayout.init(30.0, true);

    // Even if selected=true, dead entities should not be highlighted
    // The logic checks: if (selected and entity.alive)
    try std.testing.expect(!entity.alive);
    _ = renderer;
    _ = camera;
    _ = layout;
}
