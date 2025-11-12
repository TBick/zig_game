# Lua Scripting API Specification

**Complete specification of the Lua API for player scripts.**

---

## Current Status

**Phase 2 (Lua Integration)**: 30% Complete

- ✅ **Lua VM Integrated** - Basic runtime operational
- ⏳ **Game APIs** - Entity and World APIs not yet implemented
- ⏳ **Sandboxing** - CPU/memory limits pending
- ⏳ **Script Integration** - Per-entity execution pending

---

## Documentation Structure

### 📦 What's Currently Working
**→ Read [LUA_API_IMPLEMENTED.md](LUA_API_IMPLEMENTED.md)**
- Lua VM operations (init, deinit, doString)
- Global variable access (numbers and strings)
- Current capabilities and limitations
- 5 tests passing, 0 memory leaks
- Example code showing what works NOW

### 📋 Complete Planned API
**→ Read [LUA_API_PLANNED.md](LUA_API_PLANNED.md)**
- Full entity API specification (`entity.*`)
- Complete world query API (`world.*`)
- Sandbox environment details
- API design principles
- Usage examples for all planned functions

---

## Quick Reference

### Currently Implemented (Phase 2 - 30%)

**Lua VM Operations**:
```zig
var vm = try LuaVM.init(allocator);
defer vm.deinit();

try vm.doString("x = 42");
const x = try vm.getGlobalNumber("x");
```

**See [LUA_API_IMPLEMENTED.md](LUA_API_IMPLEMENTED.md) for complete details.**

### Planned Entity API (Not Yet Implemented)

**Entity Functions** (from planned spec):
```lua
-- Query entity state
local pos = entity.getPosition()    -- returns {q, r}
local energy = entity.getEnergy()   -- returns number

-- Issue commands
entity.move("north")               -- queue movement action
entity.harvest()                   -- queue harvest action
entity.build("solar_panel")        -- queue construction action
```

**See [LUA_API_PLANNED.md](LUA_API_PLANNED.md) for complete API specification.**

### Planned World API (Not Yet Implemented)

**World Query Functions** (from planned spec):
```lua
-- Query world state
local tile = world.getTileAt(5, 3)         -- returns tile info
local entities = world.findEntities({      -- returns array
    position = {q=0, r=0},
    range = 5,
    role = "worker"
})

-- Query neighbors
local neighbors = world.getNeighbors(self.position)
```

**See [LUA_API_PLANNED.md](LUA_API_PLANNED.md) for complete API specification.**

---

## Implementation Progress

| Component | Status | Module | Tests |
|-----------|--------|--------|-------|
| Lua VM | ✅ Complete | `src/scripting/lua_vm.zig` | 5/5 passing |
| Lua C Bindings | ✅ Complete | `src/scripting/lua_c.zig` | Covered by VM tests |
| Entity API | ⏳ Planned | `src/scripting/entity_api.zig` | Not started |
| World API | ⏳ Planned | `src/scripting/world_api.zig` | Not started |
| Sandboxing | ⏳ Planned | `src/scripting/sandbox.zig` | Not started |
| Script Manager | ⏳ Planned | `src/scripting/script_manager.zig` | Not started |

---

## Development Roadmap

### Phase 2 Remaining Work

1. **Entity Lua API** (Next):
   - Create C functions for entity operations
   - Register functions with Lua VM
   - Expose entity pointer via userdata
   - Test each API function from Lua

2. **World Query API**:
   - Implement world query functions
   - Efficient spatial queries (hex range)
   - Return Lua tables with results

3. **Sandboxing**:
   - CPU instruction limits (lua_sethook)
   - Memory limits (custom allocator)
   - Restrict standard library

4. **Integration**:
   - Per-entity script execution
   - Load scripts from files
   - Hot-reload support
   - Error handling

**See [DEVELOPMENT_PLAN.md](DEVELOPMENT_PLAN.md) Phase 2 for complete task breakdown.**

---

## Key Design Decisions

### Why Raw C Bindings Instead of ziglua?

**Decision** (Session 5): Use raw Lua C API bindings

**Rationale**:
- ziglua 0.5.0 incompatible with Zig 0.15.1
- Full control over API surface
- No waiting for third-party updates
- Educational value (understand Lua C API)
- Easy to optimize for our use case

**Trade-off**: More manual work upfront, but eliminates dependency blocker

**See `CONTEXT_HANDOFF_PROTOCOL.md` Session 5 for detailed rationale.**

### API Design Principles

1. **Read-Query-Command Pattern**: Scripts query state, then issue commands
2. **No Direct Mutation**: Scripts can't directly modify game state
3. **Functional Style**: Prefer pure functions where possible
4. **Lua-Friendly**: Follow Lua conventions (1-indexed arrays)
5. **Error Tolerant**: Invalid calls return nil/false, don't crash

**See [LUA_API_PLANNED.md](LUA_API_PLANNED.md) for complete design principles.**

---

## For Developers

### Implementing a New API Function

1. Read the planned spec in [LUA_API_PLANNED.md](LUA_API_PLANNED.md)
2. Create C function in appropriate module (`entity_api.zig`, `world_api.zig`)
3. Register function with Lua VM (see `lua_vm.zig` examples)
4. Write unit tests (Zig side)
5. Write integration tests (Lua side)
6. Update [LUA_API_IMPLEMENTED.md](LUA_API_IMPLEMENTED.md)

### Testing Lua API Functions

```bash
# Run all tests (includes Lua VM tests)
zig build test

# Run specific Lua tests
zig build test -- --filter "Lua"
```

---

## References

- **Current Implementation**: [LUA_API_IMPLEMENTED.md](LUA_API_IMPLEMENTED.md)
- **Planned Specification**: [LUA_API_PLANNED.md](LUA_API_PLANNED.md)
- **Source Code**: `src/scripting/` directory
- **Tests**: `zig build test` (5 Lua VM tests currently)
- **Lua 5.4 Manual**: https://www.lua.org/manual/5.4/
- **Phase 2 Progress**: See `SESSION_STATE.md`

---

**Specification Version**: 2.0 (restructured for implementation tracking)
**Last Updated**: 2025-11-12 (Session 6 - Phase 2 Documentation Audit)
**Previous Version**: See git history for monolithic LUA_API_SPEC.md v1.0
