# Claude Code Quick Start Guide

**Quick reference for starting a new session on the zig_game project.**

For detailed information, see [CLAUDE_REFERENCE.md](CLAUDE_REFERENCE.md).

---

## Project Overview

**Zig Game** - A Lua-scripted automation game where players write code to control autonomous entities.

**Tech Stack**: Zig 0.15.1 + Lua 5.4.8 (raw C bindings) + Raylib 5.6.0

**Current Phase**: Phase 1 Complete (100%), Phase 2 (Lua Integration) at 70%

**Repository**: https://github.com/TBick/zig_game

---

## Starting a New Session

### Step 1: Read Current State (5-10 minutes)

**REQUIRED READING** (in order):

1. **`SESSION_STATE.md`** (3 min)
   - Current phase and progress
   - What's done, in progress, and next
   - Current blockers

2. **`CONTEXT_HANDOFF_PROTOCOL.md`** (5 min)
   - Read MOST RECENT session entry (at bottom)
   - Understand what previous session accomplished
   - Check for critical context

3. **Recent Git History**:
   ```bash
   git log --oneline -20
   git status
   ```

### Step 2: Understand Where You Are

After reading above, you know:
- Current phase and % complete
- What was just done
- What to do next
- Any blockers or decisions made

**Don't re-read all design docs** unless specifically needed for your task.

---

## Essential Build Commands

### Quick Commands

```bash
# Build and run (Linux)
zig build run

# Run tests (149 tests)
zig build test

# Build for Windows (better graphics)
zig build run -Dtarget=x86_64-windows

# Format code
zig fmt src/
```

### Why Windows Build?

WSL2/WSLg has broken VSync (70-95 FPS instead of 60). Windows .exe runs with proper VSync and smooth graphics. Zig cross-compiles without needing Windows SDK!

**See [CLAUDE_REFERENCE.md](CLAUDE_REFERENCE.md) for complete build options.**

---

## Project Structure (Quick View)

```
zig_game/
├── SESSION_STATE.md              # READ FIRST - current status
├── CONTEXT_HANDOFF_PROTOCOL.md   # READ SECOND - recent work
├── CLAUDE_QUICK_START.md         # This file
├── CLAUDE_REFERENCE.md           # Detailed reference
│
├── docs/
│   ├── design/                   # Design specifications
│   └── agent-framework/          # Agent templates
│
├── src/                          # ~4,500 lines of Zig code
│   ├── main.zig                  # Entry point
│   ├── core/                     # Tick scheduler, action queue
│   ├── world/                    # Hex grid (✅ complete)
│   ├── entities/                 # Entity system (✅ complete)
│   ├── rendering/                # Raylib rendering (✅ complete)
│   ├── input/                    # Entity selection (✅ complete)
│   ├── ui/                       # Debug overlay (✅ complete)
│   ├── scripting/                # Lua integration (🔄 70% - VM, Entity API, World API done)
│   ├── resources/                # Phase 3
│   └── structures/               # Phase 3
│
├── vendor/lua-5.4.8/             # Vendored Lua source
├── build.zig                     # Build configuration
└── build.zig.zon                 # Dependencies (Raylib)
```

**Current State**: Phase 1 Complete (100%), Phase 2 at 70%. 149 tests passing, 0 memory leaks.

---

## Common Tasks

### "What should I work on next?"
→ Read most recent `CONTEXT_HANDOFF_PROTOCOL.md` entry "Recommended Next Steps"
→ Check `SESSION_STATE.md` "In Progress" section

### "Where is [feature/module]?"
→ Check project structure above
→ Use `Glob` tool to find files by pattern
→ Use `Task` with `subagent_type=Explore` for understanding codebase

### "How do I test?"
```bash
zig build test                    # All tests
zig build test -- --filter "hex"  # Specific tests
```

### "The build fails"
```bash
rm -rf zig-cache zig-out && zig build
```
Build system is fully functional. Ensure Zig 0.15.1 installed.

### "Should I use an agent?"
- **Simple task** (<50 LOC, 1 file): Do it directly
- **Complex task** (>100 LOC, multiple files): Use agent
- See [CLAUDE_REFERENCE.md](CLAUDE_REFERENCE.md) for agent orchestration details

---

## Current Phase: Phase 2 (Lua Integration)

**What's Done** (70% complete):
- ✅ Lua 5.4.8 integrated with raw C bindings
- ✅ Lua VM wrapper with Zig-friendly API (5 tests)
- ✅ Entity Query API - 7 functions (getId, getPosition, getEnergy, etc.)
- ✅ Entity Action API - 3 functions (moveTo, harvest, consume)
- ✅ Action Queue System - Command queue pattern (7 tests)
- ✅ World Query API - 5 functions (getTileAt, distance, neighbors, findEntitiesAt, findNearbyEntities)
- ✅ 42 Lua-related tests passing (5 VM + 17 Entity + 7 Queue + 13 World)

**What's Next** (see `CONTEXT_HANDOFF_PROTOCOL.md` Session 7):
1. Integrate scripts into tick system (Phase 2C)
2. Add memory persistence (memory table)
3. Implement sandboxing (CPU/memory limits)
4. Create example scripts (harvester, builder, explorer)

**Key Files for Phase 2**:
- `src/scripting/lua_c.zig` - Raw C API bindings (~220 lines)
- `src/scripting/lua_vm.zig` - Zig wrapper (~170 lines, 5 tests)
- `src/scripting/entity_api.zig` - Entity Lua API (~600 lines, 17 tests)
- `src/scripting/world_api.zig` - World Query API (~350 lines, 13 tests)
- `src/core/action_queue.zig` - Action queue system (~200 lines, 7 tests)
- `docs/design/LUA_API_IMPLEMENTED.md` - Current API status
- `docs/design/LUA_API_SPEC.md` - Complete API specification

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

**This is NOT optional.** Without handoff, next session loses context.

---

## Key Design Decisions (Locked In)

These are finalized. Don't revisit unless compelling reason:

1. **Zig for engine** - Performance, safety, cross-platform
2. **Lua 5.4 for scripting** - Embeddable, player-friendly
3. **Raw C bindings for Lua** - Full control, no ziglua dependency issues
4. **Hex grid** - Movement symmetry, differentiation from Screeps
5. **Tick-based simulation** - Determinism, fairness
6. **Single-player first** - Scope management
7. **Raylib for rendering** - Prototype speed, cross-platform

See `CONTEXT_HANDOFF_PROTOCOL.md` for rationale.

---

## Critical Constraints

### Performance Targets
- **Tick Rate**: 2-3 ticks/sec with 1000 entities
- **Rendering**: 60 FPS with full screen of hexes
- **Memory**: <100MB for medium world

### Code Style
- `camelCase` for functions/variables
- `PascalCase` for types
- Explicit error handling
- Doc comments on all public APIs

### Testing
- Unit tests for all public functions
- >80% code coverage target
- Zero memory leaks (test allocator verifies)

---

## Quick Reference Links

### Essential Files
- [SESSION_STATE.md](SESSION_STATE.md) - **Current status**
- [CONTEXT_HANDOFF_PROTOCOL.md](CONTEXT_HANDOFF_PROTOCOL.md) - **Recent work**
- [CLAUDE_REFERENCE.md](CLAUDE_REFERENCE.md) - **Complete reference**

### Design Documents
- [GAME_DESIGN.md](docs/design/GAME_DESIGN.md) - Gameplay mechanics
- [ARCHITECTURE.md](docs/design/ARCHITECTURE.md) - Technical design
- [DEVELOPMENT_PLAN.md](docs/design/DEVELOPMENT_PLAN.md) - Phases and milestones
- [LUA_API_SPEC.md](docs/design/LUA_API_SPEC.md) - Lua API specification

### Agent Framework
- [AGENT_ORCHESTRATION.md](docs/agent-framework/AGENT_ORCHESTRATION.md) - How to use agents
- [templates/](docs/agent-framework/templates/) - Agent prompt templates

### External Resources
- **Zig**: https://ziglang.org/documentation/master/
- **Lua 5.4**: https://www.lua.org/manual/5.4/
- **Raylib**: https://www.raylib.com/
- **Hex Grids**: https://www.redblobgames.com/grids/hexagons/

---

## Troubleshooting

### Common Issues

**"Where should I start?"**
→ Read `SESSION_STATE.md` and `CONTEXT_HANDOFF_PROTOCOL.md`

**"Tests are failing"**
→ `zig build test` to see which tests
→ Fix failures before proceeding

**"Context is too large"**
→ Use layered approach: SESSION_STATE → CONTEXT_HANDOFF → specific docs as needed
→ Use `Task` with `subagent_type=Explore` for code understanding

**"Should I create an agent?"**
→ Is it >100 LOC or >3 files? Yes, use agent
→ Is it simple edit? No, do it directly
→ See [CLAUDE_REFERENCE.md](CLAUDE_REFERENCE.md) for guidance

---

## Anti-Patterns

❌ **Starting session without reading SESSION_STATE.md** - You'll miss critical context

❌ **Ending session without updating handoff docs** - Next session loses context

❌ **Implementing without tests** - No module is complete without tests

❌ **Breaking API contracts** - If interface is defined, implement exactly as specified

---

## Success Criteria

For ANY implementation work:
- ✅ Code compiles without warnings
- ✅ All tests pass (existing + new)
- ✅ No memory leaks (test allocator verifies)
- ✅ Public APIs documented
- ✅ No regressions

---

## Need More Details?

**See [CLAUDE_REFERENCE.md](CLAUDE_REFERENCE.md)** for:
- Complete build commands (all options)
- Complete project structure
- Agent orchestration patterns
- Development workflow details
- Complete troubleshooting guide

---

**Quick Start Version**: 1.1 (metrics updated)
**Last Updated**: 2025-11-24 (Session 7 - Phase 2B World API Complete)
**For detailed reference**: See CLAUDE_REFERENCE.md
