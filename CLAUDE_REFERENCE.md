# Claude Code Reference Guide

**Complete reference documentation for working on the zig_game project.**

For quick session startup, see [CLAUDE_QUICK_START.md](CLAUDE_QUICK_START.md).

---

## Table of Contents

- [Build Commands](#build-commands)
- [Project Structure](#project-structure)
- [Architecture Overview](#architecture-overview)
- [Agent Orchestration](#agent-orchestration)
- [Development Workflow](#development-workflow)
- [Common Development Tasks](#common-development-tasks)
- [Critical Constraints](#critical-constraints)
- [Session End Protocol](#session-end-protocol)
- [Open Questions](#open-questions)
- [Troubleshooting](#troubleshooting)

---

## Build Commands

### Development Commands (Linux/WSL2)

```bash
# Build the project (debug mode, Linux binary)
zig build

# Build and run (Linux binary in WSL2)
zig build run

# Run tests
zig build test

# Run specific test
zig build test -- --filter "test_name"

# Build release
zig build -Doptimize=ReleaseFast

# Format code
zig fmt src/

# Clean build artifacts
rm -rf zig-cache zig-out
```

### Windows Cross-Compilation (from WSL2)

**Why build for Windows?**
- WSL2/WSLg has rendering artifacts and broken VSync
- Native Windows .exe runs with proper VSync and smooth 60 FPS graphics
- Zig cross-compiles without needing Windows SDK!

**Quick method (recommended):**
```bash
# Build and deploy to D:\Projects\ZigGame\
zig build windows
```

This builds a **ReleaseFast** Windows executable and copies it directly to `D:\Projects\ZigGame\zig_game.exe`. Then run it from Windows Explorer or PowerShell.

**Manual method (more control):**
```bash
# Build Windows .exe (debug mode)
zig build -Dtarget=x86_64-windows

# Build Windows .exe (optimized release)
zig build -Dtarget=x86_64-windows -Doptimize=ReleaseFast

# Build and copy to custom directory
zig build -Dtarget=x86_64-windows -Dinstall-dir="/mnt/d/Library/game-temp"
```

**Output locations:**
- `zig build windows`: `D:\Projects\ZigGame\zig_game.exe`
- Default: `zig-out/bin/zig_game.exe`
- Custom: Uses `-Dinstall-dir` path

**Running the Windows .exe:**
```bash
# From Windows (recommended for best performance)
D:\Projects\ZigGame\zig_game.exe

# From WSL2 (uses Windows graphics layer)
/mnt/d/Projects/ZigGame/zig_game.exe
```

### Does `zig build run` work for Windows builds?

**Yes!** You can use `zig build run` for any target:

```bash
# Run Linux binary (default)
zig build run

# Run Windows .exe from WSL2
zig build run -Dtarget=x86_64-windows
```

When you run a Windows .exe from WSL2, it automatically uses Windows graphics, which fixes the VSync and rendering issues!

### Build System

- **Build file**: `build.zig`
- **Dependencies**: Managed in `build.zig.zon` (Zig package manager)
- **Test runner**: Built into Zig (`zig build test`)
- **Cross-compilation**: Zig includes all target toolchains by default

**Custom Install Directory:**
The `-Dinstall-dir` option installs to BOTH the default location (`zig-out/bin/`) AND your custom directory. This way you can test with `zig build run` and also have the binary in your preferred location.

---

## Project Structure

### Complete Directory Tree

```
zig_game/
├── .gitignore                    # Zig build artifacts, IDE files
├── README.md                     # Project overview (public-facing)
├── SESSION_STATE.md              # Current progress (READ FIRST)
├── CONTEXT_HANDOFF_PROTOCOL.md   # Session handoffs (READ SECOND)
├── CONTEXT_HANDOFF_ARCHIVE.md    # Archived sessions (Sessions 1-2)
├── CLAUDE_QUICK_START.md         # Quick session startup guide
├── CLAUDE_REFERENCE.md           # This file - complete reference
│
├── docs/
│   ├── design/                   # Design documents
│   │   ├── GAME_DESIGN.md        # Gameplay mechanics and vision
│   │   ├── ARCHITECTURE.md       # Technical architecture
│   │   ├── DEVELOPMENT_PLAN.md   # Phases, milestones, testing strategy
│   │   └── LUA_API_SPEC.md       # Lua scripting API for players
│   │
│   └── agent-framework/          # Agent orchestration framework
│       ├── AGENT_ORCHESTRATION.md  # How to use agents effectively
│       └── templates/            # Agent prompt templates
│           ├── module_agent_template.md
│           ├── feature_agent_template.md
│           └── test_agent_template.md
│
├── src/                          # Zig source code (~3,370 lines)
│   ├── main.zig                  # Entry point (game loop)
│   ├── core/                     # Core systems
│   │   └── tick_scheduler.zig    # ✅ Tick timing (2.5 ticks/sec)
│   ├── world/                    # World systems
│   │   └── hex_grid.zig          # ✅ Hex grid and coordinates
│   ├── entities/                 # Entity system
│   │   ├── entity.zig            # ✅ Entity data structure
│   │   └── entity_manager.zig    # ✅ Entity lifecycle management
│   ├── rendering/                # Rendering systems
│   │   ├── hex_renderer.zig      # ✅ Camera and hex rendering
│   │   └── entity_renderer.zig   # ✅ Entity visualization
│   ├── input/                    # Input handling
│   │   └── entity_selector.zig   # ✅ Mouse-based selection
│   ├── ui/                       # User interface
│   │   ├── debug_overlay.zig     # ✅ F3 debug info
│   │   └── entity_info_panel.zig # ✅ Entity inspection panel
│   ├── scripting/                # Lua integration (✅ Phase 2 COMPLETE)
│   │   ├── lua_c.zig             # ✅ Raw C API bindings (~220 lines)
│   │   ├── lua_vm.zig            # ✅ Zig wrapper (~170 lines, 5 tests)
│   │   ├── entity_api.zig        # ✅ Entity Lua API (~600 lines, 17 tests)
│   │   └── world_api.zig         # ✅ World Query API (~350 lines, 13 tests)
│   ├── resources/                # Resource management (Phase 3)
│   ├── structures/               # Buildings and construction (Phase 3)
│   └── utils/                    # Utility functions
│
├── vendor/                       # Vendored dependencies
│   └── lua-5.4.8/                # Complete Lua 5.4.8 source (34 C files)
│
├── tests/                        # Test files (109 passing tests)
├── scripts/                      # Example Lua scripts for players (Phase 2+)
├── assets/                       # Sprites, textures, etc. (Phase 4+)
├── build.zig                     # Build configuration (fully functional)
└── build.zig.zon                 # Dependencies (Raylib)
```

**Current State**: Phase 1 Complete (100%), Phase 2 Complete (100%). 207 tests passing, ready for Phase 3.

---

## Architecture Overview

### Core Systems

**1. Tick-Based Simulation**
- Game logic runs at fixed tick rate (2-3 ticks/sec)
- Deterministic simulation (same inputs → same outputs)
- Rendering interpolates between ticks for 60 FPS smoothness
- Module: `src/core/tick_scheduler.zig`

**2. Hex Grid World**
- Axial coordinate system (q, r)
- Cube coordinate math for distance calculations
- Module: `src/world/hex_grid.zig`
- See `ARCHITECTURE.md` for hex math details
- Reference: https://www.redblobgames.com/grids/hexagons/

**3. Entity System**
- ECS-inspired (components on entities)
- Four entity roles: Workers, Combat, Scouts, Engineers
- Energy management system
- Module: `src/entities/`

**4. Lua Scripting** (Phase 2 - In Progress)
- Embedded Lua 5.4 runtime with raw C bindings
- Decision: Use raw C API instead of ziglua (Zig 0.15.1 compatibility)
- Sandboxed: CPU limits, memory limits, no file I/O
- Module: `src/scripting/`
- API spec: `LUA_API_SPEC.md`

**5. Resource Economy** (Phase 3)
- Multiple resource types (energy, minerals, etc.)
- Harvesting, processing, construction
- Module: `src/resources/`

### Data Flow

```
Input → Tick Scheduler → Execute Lua Scripts → Process Actions
  ↓                                                      ↓
Camera Control                                    Update World State
  ↓                                                      ↓
Render (60 FPS) ←────────────────────────── Interpolate Positions
```

**See `docs/design/ARCHITECTURE.md` for detailed system design.**

---

## Agent Orchestration

### When to Use Agents vs Direct Implementation

**Use Direct Implementation** (you, Claude Code):
- Simple tasks (<50 LOC, 1 file)
- Quick edits or fixes
- Exploratory work (reading code, understanding)

**Use Subagents** (Task tool):
- Complex modules (>100 LOC, multiple files)
- Well-defined tasks with clear API contracts
- Parallel development opportunities
- Specialized work (testing, refactoring, etc.)

### Agent Types Available

See `docs/agent-framework/AGENT_ORCHESTRATION.md` for complete details. Quick reference:

**Development Agents**:
- **Module Agent**: Implement a single module (`docs/agent-framework/templates/module_agent_template.md`)
- **Feature Agent**: Implement cross-cutting feature (`docs/agent-framework/templates/feature_agent_template.md`)
- **Refactoring Agent**: Optimize or restructure existing code

**Analysis Agents**:
- **Explore Agent**: Understand codebase (use `Task` with `subagent_type=Explore`)
- **Design Agent**: Research and propose solutions

**QA Agents**:
- **Test Agent**: Generate comprehensive tests (`docs/agent-framework/templates/test_agent_template.md`)
- **Review Agent**: Review code for bugs and performance

### Orchestration Patterns

**Sequential**: Task A → Task B → Task C (when dependencies exist)

**Parallel**: Task A, B, C simultaneously (when independent)
- **IMPORTANT**: Use SINGLE message with multiple Task calls for parallel execution

**Map-Reduce**: Multiple agents do similar work → Integration agent combines

**See `docs/agent-framework/AGENT_ORCHESTRATION.md` for detailed patterns and examples.**

---

## Development Workflow

### Phase-Based Development

We're building this in 6 phases:
- **Phase 0**: Project setup (build system, tooling, structure) ✅ **COMPLETE**
- **Phase 1**: Core engine (hex grid, entities, rendering, tick system) ✅ **COMPLETE**
- **Phase 2**: Lua integration (VM, API, script execution) ✅ **COMPLETE**
- **Phase 3**: Gameplay (resources, construction, pathfinding) 🎯 **READY TO START**
- **Phase 4**: UI and editor (in-game code editor, panels)
- **Phase 5**: Content and polish (tech tree, scenarios, visuals)

**Current Status**: Phase 1 Complete (100%), Phase 2 Complete (100%), 207 tests passing. See `SESSION_STATE.md` for details.

### Testing Requirements

Every module MUST have:
- Unit tests for all public functions
- Edge case and error handling tests
- Memory leak verification (use test allocator)
- >80% code coverage target

Integration tests for:
- Cross-module workflows
- End-to-end feature scenarios

Performance tests for:
- Tick processing (target: stable tick rate with 1000 entities)
- Rendering (target: 60 FPS with 5000 visible hexes)
- Lua script execution (target: 1000 scripts per tick in budget)

**See `docs/design/DEVELOPMENT_PLAN.md` for detailed testing strategy.**

---

## Common Development Tasks

### Adding a New Module

1. Check `docs/design/ARCHITECTURE.md` for module specification
2. Define API contract (interface with function signatures)
3. Use module agent template:
   ```
   Task(subagent_type="general-purpose",
        description="Implement {module_name} module",
        prompt="[Use docs/agent-framework/templates/module_agent_template.md]")
   ```
4. Write tests (or use test agent)
5. Integrate with dependent modules

### Implementing a Feature

1. Check `docs/design/GAME_DESIGN.md` and `docs/design/DEVELOPMENT_PLAN.md` for feature spec
2. Identify affected modules
3. Use feature agent template
4. Write integration tests demonstrating workflow
5. Verify no regressions (existing tests pass)

### Adding Lua API Function

1. Check `docs/design/LUA_API_SPEC.md` for API design
2. Implement C binding in `src/scripting/api.zig`
3. Register function with Lua VM
4. Test from Lua (create test script)
5. Document in API spec if new function

### Debugging Issues

1. Check recent changes: `git log --oneline -20`
2. Run tests: `zig build test`
3. Use Zig's built-in debugger or print debugging
4. Check for memory leaks (test allocator will report)
5. Profile if performance issue (`zig build -Dprofile=true`)

---

## Critical Constraints

### Performance Targets

- **Tick Rate**: Maintain stable 2-3 ticks/sec with 1000 entities
- **Rendering**: 60 FPS with full screen of hex tiles
- **Lua Scripts**: Execute 1000 entity scripts per tick within tick budget
- **Memory**: <100MB for medium world (10k tiles, 1k entities)

### Lua Sandboxing Requirements

**MUST enforce**:
- CPU limit: 10,000 instructions per entity per tick
- Memory limit: 1MB per entity script state
- No file I/O, os.execute, or debug library access
- Script errors don't crash game

### Code Style

**Follow Zig conventions**:
- `camelCase` for functions and variables
- `PascalCase` for types
- Explicit error handling (no hidden control flow)
- Doc comments on all public APIs:
  ```zig
  /// Returns the tile at the given hex coordinate.
  /// Returns null if coordinate is out of bounds.
  pub fn getTile(self: *HexGrid, coord: HexCoord) ?*Tile {
      // ...
  }
  ```

---

## Session End Protocol

**Before ending ANY session**, you MUST:

1. **Update `SESSION_STATE.md`**:
   - Mark completed tasks
   - Update progress percentages
   - Note any blockers

2. **Add handoff to `CONTEXT_HANDOFF_PROTOCOL.md`**:
   - Use the template in that file
   - Be explicit about critical context
   - Recommend next steps

3. **Commit and push**:
   ```bash
   git add .
   git commit -m "Session N: [brief summary]"
   git push
   ```

4. **Document decisions** (if any major choices made):
   - Add to `CONTEXT_HANDOFF_PROTOCOL.md` in "Decisions Made" section

**This is NOT optional.** Without handoff, next session loses context.

---

## Key Design Decisions (Already Made)

These are locked in. Don't revisit unless compelling reason:

1. **Zig for engine** - Performance, safety, cross-platform
2. **Lua 5.4 for scripting** - Embeddable, player-friendly
3. **Raw C bindings for Lua** - Full control, no ziglua compatibility issues
4. **Hex grid** - Movement symmetry, differentiation from Screeps
5. **Tick-based simulation** - Determinism, fairness
6. **Single-player first** - Scope management
7. **Data-oriented design** - Cache efficiency for many entities
8. **Raylib for rendering** - Prototype speed, cross-platform

**See `CONTEXT_HANDOFF_PROTOCOL.md` Session 1 for detailed rationale.**

---

## Open Questions (To Be Decided During Development)

1. ~~Lua 5.4 vs LuaJIT~~ - **DECIDED: Lua 5.4 with raw C bindings** (Session 5)
2. Exact tick rate (tune based on testing) - Currently 2.5 ticks/sec
3. Multi-threading strategy (defer until profiling shows need)
4. Asset pipeline and formats (Phase 4)
5. Specific entity stats and balancing (Phase 5)

---

## Troubleshooting

### "Where should I start?"
→ Read `SESSION_STATE.md` and `CONTEXT_HANDOFF_PROTOCOL.md`
→ Check "Recommended Next Steps" in most recent handoff

### "The build fails"
→ Build system is fully functional. Check dependencies in `build.zig.zon`
→ Try `rm -rf zig-cache zig-out && zig build`
→ Ensure Zig 0.15.1 is installed

### "I don't understand the architecture"
→ Read `docs/design/ARCHITECTURE.md` for technical design
→ Read `docs/design/GAME_DESIGN.md` for gameplay context
→ Use Explore agent to understand existing code

### "Tests are failing"
→ Check which tests: `zig build test`
→ Fix failures before proceeding (don't pile up broken tests)
→ If stuck, escalate to user

### "Should I create an agent for this?"
→ Is it >100 LOC or >3 files? Yes, use agent.
→ Is it simple edit? No, do it directly.
→ See `docs/agent-framework/AGENT_ORCHESTRATION.md` for detailed guidance.

### "Context is too large, can't read everything"
→ **Don't read everything.** Use layered approach:
  1. `SESSION_STATE.md` (current state)
  2. `CONTEXT_HANDOFF_PROTOCOL.md` (recent work)
  3. Specific module docs as needed
  4. Use Explore agent for code understanding

---

## Anti-Patterns (Don't Do This)

❌ **Starting session without reading SESSION_STATE.md**
→ You'll miss critical context and redo work

❌ **Ending session without updating handoff docs**
→ Next session loses all context

❌ **Creating agents for trivial tasks**
→ Overhead not worth it for simple edits

❌ **Implementing without tests**
→ No module is complete without tests

❌ **Ignoring test failures**
→ Fix tests immediately, don't accumulate broken tests

❌ **Breaking API contracts**
→ If module interface is defined, implement exactly as specified

❌ **Skipping performance benchmarks**
→ This game has strict performance requirements

---

## Success Criteria Reminder

For ANY implementation work:
- ✅ Code compiles without warnings
- ✅ All tests pass (existing + new)
- ✅ No memory leaks (test allocator verifies)
- ✅ Public APIs documented
- ✅ Meets performance targets (if specified)
- ✅ No regressions (existing functionality still works)

---

## Resources and References

### Project Documentation
- [SESSION_STATE.md](SESSION_STATE.md) - **READ FIRST**
- [CONTEXT_HANDOFF_PROTOCOL.md](CONTEXT_HANDOFF_PROTOCOL.md) - **READ SECOND**
- [CLAUDE_QUICK_START.md](CLAUDE_QUICK_START.md) - Quick session startup
- [docs/design/GAME_DESIGN.md](docs/design/GAME_DESIGN.md) - Gameplay mechanics
- [docs/design/ARCHITECTURE.md](docs/design/ARCHITECTURE.md) - Technical design
- [docs/design/DEVELOPMENT_PLAN.md](docs/design/DEVELOPMENT_PLAN.md) - Phases and milestones
- [docs/design/LUA_API_SPEC.md](docs/design/LUA_API_SPEC.md) - Lua API reference
- [docs/agent-framework/AGENT_ORCHESTRATION.md](docs/agent-framework/AGENT_ORCHESTRATION.md) - How to use agents

### External Resources
- **Zig**: https://ziglang.org/documentation/master/
- **Lua 5.4**: https://www.lua.org/manual/5.4/
- **Raylib**: https://www.raylib.com/
- **Hex Grids**: https://www.redblobgames.com/grids/hexagons/
- **Screeps** (inspiration): https://screeps.com/

### Templates
- `docs/agent-framework/templates/module_agent_template.md` - For implementing modules
- `docs/agent-framework/templates/feature_agent_template.md` - For cross-cutting features
- `docs/agent-framework/templates/test_agent_template.md` - For generating tests

---

## Final Notes

**This is an ambitious project.** We're building a complex game engine with embedded scripting, sophisticated simulation, and robust tooling. The meta-framework (agents, context handoff, state tracking) exists to make this manageable across many sessions.

**Follow the framework.** It exists to prevent context loss and coordination failures.

**Ask questions.** If something is unclear, escalate to the user rather than guessing.

**Have fun.** We're building a game about programming. That's meta and awesome.

---

**Reference Version**: 1.2 (Phase 2 complete)
**Last Updated**: 2026-02-05 (Session 11 - Phase 2 validation & polish)
**For quick session startup**: See CLAUDE_QUICK_START.md
