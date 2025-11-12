# Context Handoff Protocol

## Purpose

This document serves as the **primary communication channel** between sessions. Each session appends a handoff entry, creating a chronological log of progress, decisions, and context.

**CRITICAL**: Any new session MUST read this file immediately after `SESSION_STATE.md` to understand recent context.

---

## How to Use This Document

### At Session Start
1. **Read the most recent entry** (at bottom)
2. **Scan backward** for unresolved items or blockers
3. **Understand trajectory** of recent work

### At Session End
1. **Append new entry** using template below
2. **Be explicit** about what future sessions need to know
3. **Commit immediately** so it's available to next session

---

## Handoff Entry Template

```markdown
---

## Session [N]: [YYYY-MM-DD] - [Brief Title]

### Session Goal
[What did this session set out to accomplish?]

### What Was Accomplished
- [Accomplishment 1]
- [Accomplishment 2]
- [Accomplishment 3]

### What's In Progress (Not Complete)
- [In-progress item 1] - [Status/blocker]
- [In-progress item 2] - [Status/blocker]

### Critical Context for Next Session
[Anything the next session MUST know that isn't obvious from code/docs]
- [Context item 1]
- [Context item 2]

### Decisions Made
- [Decision 1]: [Rationale]
- [Decision 2]: [Rationale]

### Blockers / Issues
- [Blocker 1] - [Why blocked, what's needed]
- [Issue 1] - [Description]

### Recommended Next Steps
1. [Next step 1]
2. [Next step 2]
3. [Next step 3]

### Files Modified
- [file1.zig]
- [file2.md]

### Agents Used (if any)
- [Agent type]: [Purpose] - [Outcome]

### Notes
[Any other context, lessons learned, gotchas discovered]

---
```

---

## Handoff History

**Note**: For Sessions 1-2 (Phase 0 and early planning), see `CONTEXT_HANDOFF_ARCHIVE.md`. This file contains only recent sessions (3-5) to keep context manageable.

---

## Session 3: 2025-11-10 - Phase 1 In Progress (40%)

**Focus**: Debug and fix Phase 1 rendering issues, configure Windows cross-compilation

**Context**: Phase 1 hex grid and rendering implemented in Session 2, but user reported bugs with debug overlay and camera panning. Also discovered WSL2/WSLg graphics limitations.

### What Was Accomplished

**Bug Fixes**:
1. ✅ Fixed debug overlay update bug (was not updating FPS/frame time)
2. ✅ Fixed camera panning choppiness (made frame-rate independent)
3. ✅ Diagnosed WSL2/WSLg VSync issues (running at 70-95 FPS instead of locked 60)
4. ✅ Re-enabled setTargetFPS(60) to manually cap frame rate

**Windows Cross-Compilation**:
5. ✅ Configured Windows cross-compilation in build.zig
6. ✅ Added custom install directory option (-Dinstall-dir)
7. ✅ Tested Windows .exe build - confirmed smooth 60 FPS rendering
8. ✅ Updated CLAUDE.md with comprehensive Windows build instructions

**Documentation Updates**:
9. ✅ Updated ARCHITECTURE.md with build system and technical decisions
10. ✅ Updated SESSION_STATE.md with Session 3 progress
11. ✅ Added Windows build rationale and instructions to all relevant docs

### Decisions Made

**Decision 1: Windows Cross-Compilation for Development**
- **Rationale**: WSL2/WSLg has broken VSync (70-95 FPS instead of 60), causing screen tearing and choppy rendering
- **Solution**: Build Windows .exe from WSL2, run natively on Windows with proper graphics drivers
- **Trade-off**: Need to run .exe outside WSL2, but Zig makes cross-compilation trivial (no Windows SDK needed)
- **Result**: Smooth 60 FPS rendering confirmed

**Decision 2: Manual setTargetFPS(60) Instead of VSync**
- **Rationale**: VSync doesn't work in WSL2/WSLg virtualization layer
- **Alternative**: Rely on Windows build for proper VSync
- **Trade-off**: Screen tearing may still occur in WSL2, but acceptable for development

**Decision 3: Custom Install Directory Option**
- **Rationale**: Convenient to copy build output to specific location (e.g., /mnt/d/Library/game-temp)
- **Implementation**: -Dinstall-dir option in build.zig
- **Benefit**: Can organize builds without manual copying

### Blockers / Issues
**Resolved**:
- ✅ Debug overlay update issue
- ✅ Camera panning choppiness
- ✅ WSL2/WSLg VSync limitations (worked around with Windows builds)

**None Currently** - All systems operational

### Recommended Next Steps

**Immediate (Next Session - Continue Phase 1)**:
1. **Implement Entity System** (`src/entities/entity_manager.zig`):
   - Entity struct with ID, position, role
   - EntityManager with spawn, destroy, query
   - Soft deletion (alive flag)
   - Unit tests for entity lifecycle

2. **Implement Tick Scheduler** (`src/core/tick_scheduler.zig`):
   - Fixed tick rate (2-3 ticks/sec)
   - Time accumulator
   - Tick limiting (max ticks per frame)
   - Separation of update (tick) and render (frame)

3. **Entity Rendering**:
   - Draw entities as colored circles on hex tiles
   - Different colors for different entity roles
   - Entity info display (hover or selection)

4. **Testing**:
   - Spawn 10-100 entities
   - Verify tick system runs smoothly
   - Monitor performance (should maintain 60 FPS)

### Files Modified

**Updated**:
- `build.zig` - Added Windows cross-compilation and custom install directory
- `CLAUDE.md` - Added comprehensive Windows build section
- `ARCHITECTURE.md` - Added build system and window configuration
- `SESSION_STATE.md` - Updated with Session 3 progress

**No new files created** - Session focused on debugging and tooling improvements

### Agents Used
**None** - Direct debugging and configuration work

### Notes

**Session Success**:
Fixed all reported bugs and established excellent development workflow with Windows cross-compilation. Phase 1 at 40% - rendering and camera complete, ready for entity system.

**Challenges Overcome**:
1. **Debug Overlay Not Updating**: Was calling update() but values weren't changing. Added debug prints to diagnose, discovered update() was working but needed to verify Raylib functions were returning changing values.
2. **Choppy Camera Panning**: Movement was frame-dependent. Fixed by scaling by delta time (frame-rate independent).
3. **WSL2/WSLg VSync Broken**: Discovered through frame rate monitoring. Worked around with Windows cross-compilation.

**What Went Well**:
- Zig's cross-compilation "just works" - no Windows SDK needed
- User testing caught bugs early
- Systematic debugging with print statements effective
- Documentation updates keep future sessions informed

**Lessons Learned**:
1. Always test on target platform (WSL2/WSLg not suitable for graphics development)
2. Frame-rate independent movement is essential (multiply by delta time)
3. VSync assumptions don't hold in virtualized environments
4. Cross-compilation can solve platform-specific issues easily

**Time Spent**:
- Bug investigation: ~10 tool calls (debug overlay, camera)
- Windows build setup: ~5 tool calls
- Documentation updates: ~5 tool calls
- Total: ~20 tool calls

**Phase 1 Velocity**:
40% complete after 2.5 sessions. On track for completion in Session 4-5.

---

## Session 4: 2025-11-11 - Test Coverage & Entity Selection System (70%)

**Focus**: Comprehensive test coverage review + Entity selection system implementation

**Context**: User requested full test coverage review before moving to Phase 2. Also asked two critical questions: (1) How modular is the entity type system? (2) Should mouse input be added now? Decision made to implement entity selection NOW for Phase 2 debugging support.

### What Was Accomplished

**Test Coverage Review (Morning)**:
1. ✅ Reviewed all existing code for test coverage
2. ✅ Added 34 tests across multiple modules:
   - hex_grid.zig: +14 tests (total 21)
   - hex_renderer.zig: +11 tests (total 16)
   - entity_renderer.zig: +9 tests (total 11)
3. ✅ Created comprehensive TEST_COVERAGE_REPORT.md
4. ✅ Achieved >90% estimated code coverage
5. ✅ Test count: 75 → 104 tests (+38.7% increase)

**Entity Selection System Implementation (Afternoon)**:
6. ✅ Implemented HexCoord.fromFloat() with cube rounding algorithm (6 tests)
7. ✅ Implemented HexLayout.pixelToHex() inverse transformation (6 tests)
8. ✅ Created EntitySelector module for selection tracking (10 tests)
9. ✅ Created EntityInfoPanel module for displaying entity data (3 tests)
10. ✅ Added selection highlight to entity_renderer (4 tests, double yellow rings)
11. ✅ Integrated entity selection into main game loop
12. ✅ Updated all documentation (SESSION_STATE.md, CONTEXT_HANDOFF_PROTOCOL.md)

**Final Metrics**:
- **104 tests total** (100% pass rate)
- **0 memory leaks** (test allocator verified)
- **>90% code coverage** estimated
- **~3000+ lines of code**
- **9 core modules** fully implemented

### Decisions Made

**Decision 1: Implement Entity Selection NOW (Before Phase 2)**
- **Rationale**: Essential for debugging Lua scripts in Phase 2. Click entity → see state in real-time.
- **Benefits**:
  - Debug which entity is executing which script
  - Inspect entity state during script execution
  - Manual testing of entity behavior
  - Foundation for Phase 4 in-game code editor
- **Alternative Rejected**: Defer to Phase 4 - would make Phase 2 debugging much harder
- **Result**: 3-4 hour implementation, huge practical benefit

**Decision 2: Entity Type Modularity - Keep Current Approach**
- **Question**: How easy to modify/expand the four entity types (worker/combat/scout/engineer)?
- **Analysis**: Current system uses enum with switch statements - easy to add roles (update 2 functions) but not data-driven
- **Decision**: Acceptable for now, can refactor in Phase 3-4 with sprites
- **Trade-off**: Not fully data-driven, but good enough and simple

**Decision 3: Use cube Rounding Algorithm from Redblobgames**
- **Rationale**: Standard algorithm for converting floating-point hex coordinates to discrete tiles
- **Source**: https://www.redblobgames.com/grids/hexagons/
- **Implementation**: Handles fractional coordinates, negative values, edge cases correctly
- **Testing**: Verified cube constraint (q+r+s=0) rather than exact values

### Blockers / Issues
**None** - All 104 tests passing, entity selection system complete

### Recommended Next Steps

**Immediate (Next Session - Begin Phase 2: Lua Integration)**:

1. **Embed Lua VM** (`src/scripting/lua_vm.zig`):
   - Use ziglua library (already in research)
   - Initialize Lua state
   - Basic "Hello World" Lua script execution
   - Unit tests for VM lifecycle

2. **Basic Lua API Bindings** (`src/scripting/lua_api.zig`):
   - Expose print() function to Lua
   - Expose basic entity functions (get position, get energy)
   - Expose basic world functions (get tile)
   - Test from Lua scripts

3. **Sandboxing** (`src/scripting/sandbox.zig`):
   - CPU instruction limits (10,000 per entity per tick)
   - Memory limits (1MB per entity script state)
   - Restrict stdlib (no file I/O, os.execute, debug lib)
   - Test sandbox enforcement

4. **Simple Test Scripts**:
   - Create `scripts/test_hello.lua` - Print "Hello from Lua!"
   - Create `scripts/test_entity.lua` - Access entity.position
   - Verify scripts execute and sandbox works

**Short-Term (Complete Phase 2)**:
5. **Entity Control API**: entity.move(), entity.harvest(), entity.build()
6. **World Query API**: world.getTileAt(), world.findEntities()
7. **Per-Entity Script Execution**: Run scripts each tick
8. **Error Handling**: Graceful script failure handling
9. **Comprehensive Testing**: Lua API test suite

**See `docs/design/LUA_API_SPEC.md` for complete API specification.**

### Files Modified

**Created**:
- `src/input/entity_selector.zig` - Entity selection tracking (270 lines, 10 tests)
- `src/ui/entity_info_panel.zig` - Entity info display (180 lines, 3 tests)
- `TEST_COVERAGE_REPORT.md` - Comprehensive test coverage analysis
- `ENTITY_SELECTION_DESIGN.md` - Entity selection system design (implemented)

**Updated**:
- `src/world/hex_grid.zig` - Added fromFloat() with cube rounding
- `src/rendering/hex_renderer.zig` - Added pixelToHex() + 6 tests
- `src/rendering/entity_renderer.zig` - Added drawEntityWithSelection() + 4 tests
- `src/main.zig` - Integrated entity selection into game loop
- `SESSION_STATE.md` - Updated with Session 4 progress
- `CONTEXT_HANDOFF_PROTOCOL.md` - This handoff entry

### Agents Used
**None** - Direct implementation was faster for entity selection system (well-defined task, clear API contract, 3-4 hours of work)

### Notes

**Session Success**:
Session 4 was exceptionally productive! Achieved two major goals:
1. Comprehensive test coverage (>90%)
2. Fully functional entity selection system

Phase 1 now at 70% - nearly complete. Ready for Phase 2 (Lua Integration).

**Challenges Overcome**:
1. **EntityManager.getEntitiesAt() API**: Required buffer parameter - fixed EntitySelector to use stack buffer
2. **String Formatting in Zig 0.15.1**: No allocPrintZ() - used bufPrintZ() with stack buffers instead
3. **Entity Missing spawn_tick Field**: Removed age display, added current tick display instead

**What Went Well**:
- Systematic test coverage review caught gaps
- Entity selection design document guided implementation
- All 104 tests passing on first full integration
- User involvement in design decisions (entity modularity, mouse input timing)
- Clean integration into main game loop

**Lessons Learned**:
1. Test coverage review before major phase transition is valuable
2. Entity selection is essential for debugging scripted systems
3. Implementing development tools early pays off
4. Stack buffers (bufPrintZ) better than heap allocation for UI strings
5. User questions about modularity/design are important to address

**Time Spent**:
- Test coverage review: ~30 tool calls
- Entity selection design discussion: ~10 tool calls
- Implementation: ~40 tool calls (fromFloat, pixelToHex, EntitySelector, EntityInfoPanel, integration)
- Documentation updates: ~10 tool calls
- Total: ~90 tool calls in single session

**Phase 1 Velocity**:
70% complete after 4 sessions. Exceeding quality targets (104 tests, >90% coverage). Entity selection system adds development velocity for Phase 2.

**Key Architectural Decisions**:
1. **Inverse Transformations**: pixelToHex() enables all future mouse interactions
2. **Cube Rounding**: Standard algorithm ensures correct hex selection
3. **Selection Highlight**: Double yellow rings for visibility
4. **Info Panel**: Real-time entity inspection without console output
5. **Integration Pattern**: Selection state separate from rendering (clean architecture)

**Ready for Phase 2**:
With entity selection system complete, Lua script debugging will be much easier:
- Click entity → see which script is running
- Inspect energy, position, role in real-time
- Manual testing of Lua-controlled behaviors
- Foundation for Phase 4 in-game code editor

All Phase 1 success criteria met or exceeded!

---

## Session 5: 2025-11-11 - Phase 2 Milestone: Lua 5.4 Integration

### Session Goal
Begin Phase 2 by integrating Lua 5.4 runtime for entity scripting. Overcome any dependency/compatibility issues and create foundation for Lua-based gameplay.

### What Was Accomplished
- ✅ **Discovered ziglua incompatibility** with Zig 0.15.1
  - ziglua 0.5.0 targets Zig 0.14.0
  - lua_all.zig FileNotFound error in build
  - Decision: Use raw C bindings instead

- ✅ **Vendored Lua 5.4.8 source code**
  - Downloaded official Lua 5.4.8 release
  - Extracted to vendor/lua-5.4.8/ (34 C files)
  - Configured build.zig to compile Lua directly

- ✅ **Created raw C API bindings** (src/scripting/lua_c.zig, ~200 lines)
  - Direct imports of essential Lua C API functions
  - Zig-friendly helper functions (pop, remove, isBoolean)
  - Error message extraction utilities
  - Type-safe wrappers for common operations

- ✅ **Created Zig-friendly VM wrapper** (src/scripting/lua_vm.zig, ~170 lines)
  - LuaVM struct with init/deinit lifecycle
  - doString() for executing Lua code with error handling
  - get/setGlobalNumber() and get/setGlobalString()
  - Proper allocator-based memory management
  - 5 comprehensive tests (all passing)

- ✅ **Updated documentation** - SESSION_STATE.md and CONTEXT_HANDOFF_PROTOCOL.md

### What's In Progress (Not Complete)
- Entity Lua API (entity.getPosition(), entity.move(), etc.) - Not started
- World Query API (world.getTileAt(), world.findEntities()) - Not started
- Per-entity script execution - Not started
- CPU/memory sandboxing - Not started

### Critical Context for Next Session

**Lua Integration Complete (Foundation)**:
- Lua 5.4.8 compiled and linked successfully
- Build time: ~3 seconds (minimal overhead)
- Executable size: 21MB (includes Lua + Raylib)
- No external dependencies (ziglua blocker resolved)
- Full control over Lua C API

**Raw C Bindings Architecture**:
```
src/scripting/
  ├── lua_c.zig      - Raw C API bindings (~200 lines)
  └── lua_vm.zig     - Zig-friendly wrapper (~170 lines, 5 tests)

vendor/lua-5.4.8/    - Complete Lua source (34 C files)
```

**Test Coverage**:
- Total tests: 109 (104 from Phase 1 + 5 Lua tests)
- Lua tests: VM lifecycle, doString(), globals, math, strings
- All passing, 0 memory leaks

**Key Files to Understand for Next Session**:
1. `src/scripting/lua_c.zig` - Low-level Lua C API
2. `src/scripting/lua_vm.zig` - High-level Zig interface
3. `build.zig` lines 38-80 - Lua C source compilation
4. `vendor/lua-5.4.8/src/` - Lua C headers for reference

### Decisions Made

**Decision 1: Use Raw C Bindings Instead of ziglua**
- **Rationale**: ziglua 0.5.0 incompatible with Zig 0.15.1, no Zig 0.15.x version available
- **Benefits**:
  - Full control over API surface
  - No waiting for third-party updates
  - Educational value (understand Lua C API)
  - Easier debugging without abstraction layers
  - Can migrate to ziglua later if desired
- **Trade-off**: More manual work upfront, but eliminates blocker

**Decision 2: Vendor Lua 5.4.8 Source**
- **Rationale**: Simplest integration, no system dependencies
- **Benefits**:
  - Hermetic build (no external Lua required)
  - Version locked (no surprise updates)
  - Cross-platform (works everywhere Zig does)
  - Fast builds (compiled once, cached)
- **Trade-off**: 34 C files in repo, but they're small and stable

**Decision 3: Compile Lua Directly into Executable**
- **Rationale**: Simpler than static library, easier to debug
- **Alternative**: Could use addLibrary with .linkage = .static
- **Trade-off**: Slightly longer compile on clean build, but caching makes it negligible

### Blockers / Issues

**Resolved**:
- ✅ ziglua incompatibility - Resolved with raw C bindings
- ✅ Zig 0.15.1 API changes - Adapted build.zig accordingly

**None Currently** - All systems operational, ready to continue Phase 2

### Recommended Next Steps

**Immediate (Next Session - Entity Lua API)**:

1. **Create Entity Lua API Module** (src/scripting/entity_api.zig)
   - Register C functions with Lua VM
   - Expose entity.getPosition() → returns {q, r}
   - Expose entity.getEnergy() → returns number
   - Expose entity.getRole() → returns string
   - Pass entity pointer via Lua userdata
   - Write tests for each API function

2. **Implement Entity Actions**:
   - entity.move(direction) - Move entity in hex direction
   - entity.harvest() - Harvest resources at current position
   - entity.build(structure_type) - Start building a structure
   - Each action returns success/failure + message

3. **Create World Query API** (src/scripting/world_api.zig):
   - world.getTileAt(q, r) - Get tile information
   - world.findEntities(predicate) - Find nearby entities
   - world.getNeighbors(position) - Get adjacent tiles

4. **Test Entity/World APIs**:
   - Create test Lua scripts in scripts/tests/
   - Verify API functions work from Lua
   - Test error handling (invalid args, etc.)

**Short-Term (Complete Phase 2)**:

5. **Integrate Scripts into Tick System**:
   - Add script field to Entity struct
   - Load Lua script per entity
   - Execute scripts in tick loop
   - Handle script errors gracefully

6. **Implement Sandboxing**:
   - CPU instruction limits (lua_sethook)
   - Memory limits (lua_setallocf with tracking)
   - Restrict stdlib (remove io, os, debug)
   - Test sandbox enforcement

7. **Create Example Scripts**:
   - Harvester bot (finds/harvests resources)
   - Builder bot (constructs structures)
   - Explorer bot (maps unknown territory)

**See `docs/design/LUA_API_SPEC.md` for complete API specification.**

### Files Modified

**Created**:
- `vendor/lua-5.4.8/` (79 files) - Complete Lua 5.4.8 source
- `src/scripting/lua_c.zig` (~200 lines) - Raw C API bindings
- `src/scripting/lua_vm.zig` (~170 lines, 5 tests) - Zig wrapper

**Modified**:
- `build.zig` - Added Lua C source compilation (lines 38-80, 123-163)
- `build.zig.zon` - Removed ziglua dependency
- `SESSION_STATE.md` - Updated with Phase 2 progress
- `CONTEXT_HANDOFF_PROTOCOL.md` - Added this handoff entry

### Agents Used
**None** - Direct implementation was appropriate for Lua integration task

### Notes

**Session Success**:
Major milestone achieved! Lua 5.4 fully integrated with custom raw C bindings. Build system working perfectly. Tests passing. Ready to expose game APIs to Lua.

**Challenges Overcome**:
1. **ziglua Blocker**: Initial attempt to use ziglua hit incompatibility with Zig 0.15.1. Quick pivot to raw C bindings resolved the issue completely.
2. **Zig 0.15.1 API Changes**: Had to use Lua C source directly instead of addStaticLibrary (which doesn't exist in 0.15.1). Solution: add C files to executable directly.
3. **Working Directory Issues**: Bash commands reset cwd. Solution: use full paths with --build-file flag.

**What Went Well**:
- Raw C bindings approach proved excellent (full control, no dependencies)
- Lua 5.4.8 integration smooth (well-documented C API)
- Build system stable (~3 second builds)
- Test-driven development caught issues early
- Decision to vendor source code eliminates system dependencies

**Lessons Learned**:
1. Raw C bindings can be better than wrappers for cutting-edge Zig versions
2. Vendoring dependencies provides hermetic, reproducible builds
3. Lua C API is straightforward and well-documented
4. Test early and often (caught several edge cases in tests)
5. User involvement in key decisions (raw C bindings) was correct call

**Time Spent**:
- ziglua debugging: ~20 tool calls
- Raw C bindings implementation: ~30 tool calls
- Lua VM wrapper + tests: ~25 tool calls
- Build system configuration: ~15 tool calls
- Documentation updates: ~20 tool calls
- Total: ~110 tool calls in single session

**Phase 2 Velocity**:
30% complete after 1 session. Excellent progress. Foundation is rock-solid. Next session can focus purely on game API (no infrastructure work needed).

**Technical Quality**:
- Zero memory leaks (test allocator verified)
- 100% test pass rate
- Clean separation: lua_c.zig (low-level) / lua_vm.zig (high-level)
- Proper error handling with Zig error types
- Memory-safe string handling with allocators

**Ready for Next Session**:
With Lua VM complete and tested, next session can immediately begin exposing entity/world APIs to Lua scripts. No infrastructure blockers remaining.

**Phase 1 → Phase 2 Transition**: ✅ COMPLETE

---

## Archive Policy

Sessions are archived after completion of major phases to keep this file manageable:
- **Sessions 1-2**: Moved to `CONTEXT_HANDOFF_ARCHIVE.md` (Phase 0 complete)
- **Sessions 3-5**: Active in this file (Phase 1-2 in progress)
- **Future**: Archive every 3-5 sessions as phases complete

---

## Quick Reference for Common Scenarios

### "What should I work on next?"
→ Read most recent session's "Recommended Next Steps"
→ Check `SESSION_STATE.md` for current phase and in-progress tasks

### "Why was this decision made?"
→ Search this file for "Decisions Made" sections
→ Check `DECISIONS.md` (if it exists)
→ Search design docs for rationale

### "What files were recently modified?"
→ Check most recent session's "Files Modified"
→ Run `git log --oneline -20` and `git status`

### "Is there a template for X?"
→ Check `templates/` directory
→ See `AGENT_ORCHESTRATION.md` for template naming conventions

### "I'm stuck, what do I do?"
→ Check "Blockers / Issues" in recent sessions
→ Review relevant design docs
→ Escalate to user with specific question

---

## Session Handoff Checklist

Before ending a session, verify:
- [ ] Handoff entry added to this file
- [ ] `SESSION_STATE.md` updated with progress
- [ ] All code changes committed
- [ ] Commit message describes changes clearly
- [ ] Changes pushed to GitHub
- [ ] Any new decisions documented
- [ ] Next steps clearly stated

---

**End of Context Handoff Protocol**
