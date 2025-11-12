# Entity Selection System - Design Document

## Overview
Add mouse-based entity selection before Phase 2 to improve development workflow and prepare for Phase 4 UI.

## Goals
1. Click entity to select/inspect
2. Visual selection indicator
3. Info panel showing entity state
4. Foundation for future UI (Phase 4)

## Architecture

### New Module: `src/input/entity_selector.zig`
```zig
pub const EntitySelector = struct {
    selected_entity_id: ?EntityId,

    pub fn init() EntitySelector;

    /// Update selection based on mouse input
    pub fn update(
        self: *EntitySelector,
        mouse_pos: rl.Vector2,
        mouse_clicked: bool,
        entity_manager: *EntityManager,
        camera: *Camera,
        layout: *HexLayout,
        screen_width: i32,
        screen_height: i32,
    ) void;

    /// Get currently selected entity
    pub fn getSelected(self: *const EntitySelector, manager: *EntityManager) ?*Entity;

    /// Clear selection
    pub fn deselect(self: *EntitySelector) void;
};
```

### Selection Logic
1. **Mouse Click Detection**: Check `rl.isMouseButtonPressed(.left)`
2. **Screen to World**: `camera.screenToWorld(mouse_x, mouse_y)`
3. **World to Hex**: `layout.pixelToHex(world_pos)` ← **NEED TO IMPLEMENT**
4. **Query Entities**: `entity_manager.getEntitiesAt(hex_coord)`
5. **Select First**: Store `selected_entity_id`

### Visual Feedback
**Selection Highlight** (in `entity_renderer.zig`):
```zig
pub fn drawEntityWithSelection(
    self: *const EntityRenderer,
    entity: *const Entity,
    selected: bool,
    camera: *const Camera,
    layout: *const HexLayout,
    screen_width: i32,
    screen_height: i32,
) void {
    // Draw entity (existing code)
    self.drawEntity(entity, camera, layout, screen_width, screen_height);

    // Draw selection ring if selected
    if (selected) {
        const radius = self.entity_radius * 1.5 * camera.zoom;
        rl.drawCircleLines(
            @intFromFloat(screen_pos.x),
            @intFromFloat(screen_pos.y),
            @intFromFloat(radius),
            rl.Color.yellow, // Highlight color
        );
    }
}
```

### Info Panel
**New Module: `src/ui/entity_info_panel.zig`**
```zig
pub const EntityInfoPanel = struct {
    x: i32,
    y: i32,
    width: i32,
    height: i32,

    pub fn draw(
        self: *const EntityInfoPanel,
        entity: ?*const Entity,
        tick: u64,
    ) void {
        if (entity) |e| {
            // Draw semi-transparent background
            // Draw entity info text:
            //   - ID
            //   - Role
            //   - Position (q, r)
            //   - Energy (50/100)
            //   - Age (tick - spawn_tick)
        }
    }
};
```

## Missing Functionality

### **CRITICAL: Need pixelToHex()**
Current gap: We have `hexToPixel()` but NOT `pixelToHex()`

**Add to `hex_renderer.zig:HexLayout`**:
```zig
/// Convert pixel position to hex coordinate (inverse of hexToPixel)
pub fn pixelToHex(self: HexLayout, pixel: rl.Vector2) HexCoord {
    if (self.orientation) {
        // Flat-top: inverse transformation
        const q = (2.0 / 3.0 * pixel.x) / self.size;
        const r = (-1.0 / 3.0 * pixel.x + std.math.sqrt(3.0) / 3.0 * pixel.y) / self.size;
        return HexCoord.fromFloat(q, r); // Need rounding
    } else {
        // Pointy-top: inverse transformation
        const q = (std.math.sqrt(3.0) / 3.0 * pixel.x - 1.0 / 3.0 * pixel.y) / self.size;
        const r = (2.0 / 3.0 * pixel.y) / self.size;
        return HexCoord.fromFloat(q, r);
    }
}
```

**Add to `hex_grid.zig:HexCoord`**:
```zig
/// Create HexCoord from floating point coordinates (with rounding)
pub fn fromFloat(q_float: f32, r_float: f32) HexCoord {
    // Cube rounding algorithm (from redblobgames)
    const q = @round(q_float);
    const r = @round(r_float);
    const s = @round(-q_float - r_float);

    const q_diff = @abs(q - q_float);
    const r_diff = @abs(r - r_float);
    const s_diff = @abs(s - (-q_float - r_float));

    if (q_diff > r_diff and q_diff > s_diff) {
        return HexCoord{ .q = @intFromFloat(-r - s), .r = @intFromFloat(r) };
    } else if (r_diff > s_diff) {
        return HexCoord{ .q = @intFromFloat(q), .r = @intFromFloat(-q - s) };
    } else {
        return HexCoord{ .q = @intFromFloat(q), .r = @intFromFloat(r) };
    }
}
```

## Integration Points

### main.zig Updates
```zig
// Add to game state
var entity_selector = EntitySelector.init();
var info_panel = EntityInfoPanel.init(10, 250, 250, 200);

// In main loop (after camera input, before rendering)
entity_selector.update(
    rl.getMousePosition(),
    rl.isMouseButtonPressed(rl.MouseButton.left),
    &entity_manager,
    &hex_renderer.camera,
    &hex_renderer.layout,
    current_width,
    current_height,
);

// In rendering section
const selected_entity = entity_selector.getSelected(&entity_manager);

// Draw entities with selection highlight
for (entity_manager.getAliveEntities()) |*entity| {
    const is_selected = if (selected_entity) |sel| sel.id == entity.id else false;
    entity_renderer.drawEntityWithSelection(
        entity,
        is_selected,
        &hex_renderer.camera,
        &hex_renderer.layout,
        current_width,
        current_height,
    );
}

// Draw info panel
info_panel.draw(selected_entity, tick_scheduler.getCurrentTick());
```

## Testing Requirements

### Unit Tests
- `pixelToHex()` inverse of `hexToPixel()` (roundtrip)
- `HexCoord.fromFloat()` rounding behavior
- `EntitySelector.update()` selection logic
- Selection at hex boundaries
- Multiple entities at same hex

### Integration Tests
- Click entity → select → info panel shows data
- Click empty space → deselect
- Click different entity → switch selection

### Manual Testing
- Click entities at various zoom levels
- Click at grid edges
- Click rapidly (no crashes)
- Verify info panel updates

## Timeline

**Estimated: 3-4 hours**
1. Implement `pixelToHex()` and `fromFloat()` (1 hour)
2. Implement `EntitySelector` (1 hour)
3. Implement `EntityInfoPanel` (1 hour)
4. Integration and testing (1 hour)

## Benefits

### Immediate (Phase 2)
✅ Debug Lua scripts - see which entity is executing what
✅ Inspect entity state during script execution
✅ Manual testing of entity behavior
✅ Better development workflow

### Future (Phase 3-4)
✅ Foundation for in-game code editor
✅ Entity script assignment UI
✅ Drag-select for bulk operations
✅ Context menus for actions

## Alternatives Considered

**Alt 1: Defer to Phase 4**
- ❌ Harder to debug Lua scripts without selection
- ❌ More work to retrofit later
- ❌ Miss development productivity gains

**Alt 2: Keyboard-only selection**
- ❌ Less intuitive
- ❌ Doesn't prepare for Phase 4 mouse UI
- ✅ Simpler to implement

**Alt 3: Debug overlay only**
- ❌ Can't inspect individual entities
- ❌ No selection concept
- ✅ Very simple

## Decision: **Implement Now (Recommended)**

Selection is:
- **Essential** for Phase 4 UI
- **Valuable** for Phase 2 debugging
- **Simple** enough to implement quickly (3-4 hours)
- **Foundation** for future features

---

**Status**: Design Complete, Ready for Implementation
**Priority**: High - Implement before Phase 2
