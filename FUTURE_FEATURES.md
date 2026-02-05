# Future Features & Polish Items

This document tracks features and polish improvements planned for future development.

---

## Rendering Polish

### ✅ Seamless Tile Rendering (IMPLEMENTED - Session 11)
**Goal:** Create a seamless visual appearance for interior tiles while maintaining boundary clarity.

**Status: COMPLETE** (2026-02-04)

**Implementation:**
Modified `drawOptimizedEdges()` in `src/rendering/hex_renderer.zig`:
- Only boundary edges are drawn (edges where there's no neighboring tile)
- Interior edges are skipped entirely, creating seamless filled regions
- Result: Smooth filled area with clear boundary outline

**Benefits Achieved:**
- Cleaner visual appearance ✓
- Better visibility of the playable area boundaries ✓
- More "zone-like" feel for contiguous regions ✓
- Foundation for fog of war (boundary edges define explored area) ✓

---

## Input & Interaction Polish

### Click Tolerance for Tile Selection
**Goal:** Make tile selection more forgiving near hex boundaries

**Current State:**
- Pixel-perfect hit detection using pixelToHex
- Clicking near hex edges can feel inconsistent

**Desired State:**
- Small tolerance radius around each hex center
- Prioritize the closest hex center within tolerance
- Makes clicking feel more responsive

**Estimated Effort:** 1-2 hours

---

### Camera Smoothing
**Goal:** Add smooth interpolation to camera panning/zooming

**Current State:**
- Instant camera movement
- Can feel jarring with large movements

**Desired State:**
- Lerp camera position over a few frames
- Ease-in/ease-out for zoom
- Optional: inertia for mouse drag

**Estimated Effort:** 2-3 hours

---

## Visual Effects

### Tile Hover Glow Effect
**Goal:** Add a subtle glow/highlight around hovered tiles

**Current State:**
- Hovered tiles have different fill color
- No visual "pop" or emphasis

**Desired State:**
- Animated glow around hovered tile edges
- Pulsing alpha or brightness
- More engaging visual feedback

**Estimated Effort:** 2-4 hours

---

### Selection Animation
**Goal:** Animate selection changes

**Current State:**
- Instant color change on selection
- No transition

**Desired State:**
- Brief animation when selecting/deselecting
- Scale pulse, color fade, or edge glow
- Makes selection state changes obvious

**Estimated Effort:** 2-3 hours

---

## Performance Optimizations

### Spatial Partitioning for Entity Queries
**Goal:** Optimize entity-under-mouse lookups

**Current State:**
- Linear search through all alive entities
- O(N) per frame

**Desired State:**
- Spatial hash grid or quadtree
- O(1) average case for mouse queries
- Matters when entity count grows (100s or 1000s)

**Estimated Effort:** 4-6 hours

---

### View Frustum Culling for Tiles
**Goal:** Only render tiles visible in viewport

**Current State:**
- Iterate and draw all tiles in grid
- Wastes draw calls for off-screen tiles

**Desired State:**
- Calculate which tiles are in camera view
- Skip rendering for off-screen tiles
- Matters for large maps (100x100+)

**Estimated Effort:** 3-4 hours

---

## Debug Window System Enhancements

The debug system uses a window abstraction for debug tools. These are future enhancements:

### Window Dragging
**Goal:** Allow dragging windows by their title bar
**Current State:** Fixed positions
**Estimated Effort:** 2-3 hours

### Window Resizing
**Goal:** Drag window edges/corners to resize
**Current State:** Fixed sizes
**Estimated Effort:** 3-4 hours

### Window Snapping
**Goal:** Snap windows to screen edges and other windows
**Current State:** Manual positioning only
**Estimated Effort:** 3-4 hours

### Window Tabbing
**Goal:** Combine multiple windows into a tabbed container
**Current State:** Individual windows only
**Desired State:** Drag window onto another to create tab group
**Estimated Effort:** 6-8 hours

### Window Docking
**Goal:** Dock windows to screen edges with auto-layout
**Current State:** Free-floating only
**Estimated Effort:** 8-10 hours

### Window State Persistence
**Goal:** Save window positions/sizes to file, restore on restart
**Current State:** Default positions on each launch
**Estimated Effort:** 2-3 hours

### Additional Debug Windows (Phase 3+)
- **Console Window:** In-game Lua output/errors (Session 13 - Release Feature)
- **Pathfinding Visualizer:** Show A* paths and costs
- **Resource Inspector:** View resource deposits and quantities
- **Script Debugger:** Step through Lua execution
- **Performance Profiler:** Detailed timing breakdown

---

## Future Architectural Improvements

### Rendering Backend Abstraction
**Goal:** Separate rendering API from game logic

**Complexity:** High
**Estimated Effort:** 1-2 weeks

### Event System for Input
**Goal:** Replace polling with event-driven input handling

**Complexity:** Medium
**Estimated Effort:** 1 week

---

## Notes

- **Priority levels:** High (next few sessions), Medium (this phase), Low (future phases)
- **Effort estimates:** Rough approximations, may vary based on complexity discovered during implementation
- Items are not in strict priority order within sections
- This list will grow as new ideas emerge

**Last Updated:** 2026-02-05 (Session 12 - Debug System Refactor Planning)
