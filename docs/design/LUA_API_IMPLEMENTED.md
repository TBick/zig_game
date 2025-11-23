# Lua API - Currently Implemented

**Status**: Phase 2 at 45% complete - Lua VM operational, Entity query API implemented!

This document describes the **currently working** Lua integration. For planned API functions, see [LUA_API_PLANNED.md](LUA_API_PLANNED.md).

---

## Implementation Status

### ✅ Implemented (Phase 2 - 45%)

**Lua VM Foundation** (`src/scripting/lua_vm.zig`, `lua_c.zig`):
- ✅ Lua 5.4.8 integrated with raw C bindings (~220 lines)
- ✅ VM lifecycle management (init, deinit)
- ✅ Script execution (`doString`)
- ✅ Global variable access (get/set for numbers and strings)
- ✅ Table operations (createTable, getI/setI)
- ✅ Light userdata support (pushLightuserdata)
- ✅ 5 comprehensive tests covering VM operations

**Entity Query API** (`src/scripting/entity_api.zig`):
- ✅ Entity context injection (setEntityContext, getEntityContext)
- ✅ Self table creation with entity properties
- ✅ `entity.getId()` - Get entity ID
- ✅ `entity.getPosition()` - Get hex position as {q, r} table
- ✅ `entity.getEnergy()` - Get current energy
- ✅ `entity.getMaxEnergy()` - Get maximum energy
- ✅ `entity.getRole()` - Get role as string
- ✅ `entity.isAlive()` - Check if entity is alive
- ✅ `entity.isActive()` - Check if entity is active (alive && has energy)
- ✅ 8 comprehensive integration tests

### ⏳ In Progress / Not Yet Implemented

- ⏳ Entity Action API (entity.moveTo, entity.harvest, entity.consume)
- ⏳ Action queue system
- ⏳ World Query API (world.*, see LUA_API_PLANNED.md)
- ⏳ Memory persistence (memory table)
- ⏳ Sandboxing (CPU/memory limits)
- ⏳ Per-entity script execution in tick system
- ⏳ Script loading from files
- ⏳ Error handling and debugging

---

## Currently Available Lua Operations

### Basic VM Operations

The following operations work through the `LuaVM` struct in `src/scripting/lua_vm.zig`:

#### Execute Lua Code

```zig
var vm = try LuaVM.init(allocator);
defer vm.deinit();

try vm.doString("x = 42");
```

**Capabilities**:
- Execute arbitrary Lua code strings
- Full Lua 5.4 standard library available (no sandboxing yet)
- Syntax and runtime errors are captured and reported

#### Get/Set Global Variables

```zig
// Set global number
try vm.setGlobalNumber("energy", 100.0);

// Get global number
const energy = try vm.getGlobalNumber("energy"); // returns f64

// Set global string
try vm.setGlobalString("role", "worker");

// Get global string
const role = try vm.getGlobalString("role"); // returns []const u8 (must free)
defer allocator.free(role);
```

**Limitations**:
- Only number (f64) and string types supported for globals
- Tables, functions, and other types not yet exposed
- No type checking (returns error if wrong type)

---

## Example: Current Capabilities

### What Works Now

```zig
const std = @import("std");
const LuaVM = @import("scripting/lua_vm.zig").LuaVM;
const entity_api = @import("scripting/entity_api.zig");
const Entity = @import("entities/entity.zig").Entity;
const HexCoord = @import("world/hex_grid.zig").HexCoord;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var vm = try LuaVM.init(allocator);
    defer vm.deinit();

    // Basic Lua execution
    try vm.doString("result = 10 + 20 * 3");
    const result = try vm.getGlobalNumber("result");
    std.debug.print("Result: {d}\n", .{result}); // Prints: 70

    // Entity API usage
    var my_entity = Entity.init(42, HexCoord{.q = 5, .r = 3}, .worker);

    // Set up entity context and API
    entity_api.setEntityContext(vm.L, &my_entity);
    entity_api.registerEntityAPI(vm.L);
    entity_api.createSelfTable(vm.L, &my_entity);
    lua.setGlobal(vm.L, "self");

    // Now Lua scripts can access entity!
    try vm.doString(
        \\print("My ID: " .. self.id)
        \\print("Position: " .. self.position.q .. ", " .. self.position.r)
        \\print("Role: " .. self.role)
        \\
        \\local energy = entity.getEnergy()
        \\print("Energy: " .. energy)
        \\
        \\if entity.isActive() then
        \\    print("I'm active!")
        \\end
    );
}
```

### What Doesn't Work Yet

```lua
-- ❌ No entity actions yet
entity.moveTo({q=5, r=5})  -- ERROR: moveTo not implemented yet
entity.harvest({q=3, r=2})  -- ERROR: harvest not implemented yet

-- ❌ No world query API yet
local tile = world.getTileAt(0, 0)  -- ERROR: 'world' is undefined

-- ❌ No memory persistence yet
memory.state = "idle"  -- ERROR: 'memory' is undefined

-- ❌ No sandboxing yet (infinite loop will hang)
while true do end  -- Will hang forever (no CPU limit)

-- ❌ Can't call Lua functions from Zig yet
function update() return 42 end  -- Function defined, but no way to call from Zig
```

---

## Technical Implementation Details

### Architecture

```
Zig Code
    ↓
src/scripting/lua_vm.zig (Zig-friendly wrapper)
    ↓
src/scripting/lua_c.zig (Raw C API bindings)
    ↓
vendor/lua-5.4.8/ (Lua 5.4.8 C source, compiled directly)
```

### Key Modules

**`src/scripting/lua_c.zig`** (~220 lines):
- Raw C API bindings to Lua 5.4
- Direct `extern fn` declarations
- Zig-friendly helper functions (pop, remove, isBoolean, etc.)
- Table operations (createTable, getI/setI)
- Light userdata support (pushLightuserdata)
- Error message extraction

**`src/scripting/lua_vm.zig`** (~170 lines, 5 tests):
- High-level Zig API
- `LuaVM` struct with lifecycle management
- Memory-safe string handling with allocators
- Error types (`LuaError.OutOfMemory`, `LuaError.RuntimeError`, etc.)

**`src/scripting/entity_api.zig`** (~350 lines, 8 tests):
- Entity context management (light userdata pattern)
- Self table creation with entity properties
- 7 entity query functions (getId, getPosition, getEnergy, getRole, etc.)
- Module registration (registerEntityAPI)
- Comprehensive integration tests

### Build Integration

Lua 5.4.8 is compiled directly into the executable:

```zig
// build.zig lines 38-80
exe.addCSourceFiles(.{
    .files = &.{
        "vendor/lua-5.4.8/src/lapi.c",
        "vendor/lua-5.4.8/src/lcode.c",
        // ... 32 more C files
    },
    .flags = &.{
        "-std=c99",
        "-DLUA_USE_LINUX",
    },
});
exe.addIncludePath(b.path("vendor/lua-5.4.8/src"));
exe.linkLibC();
```

**Rationale**: Raw C bindings provide full control without dependency on third-party bindings like ziglua (which had Zig 0.15.1 compatibility issues).

---

## Tests

**Current Test Coverage**:

**Lua VM Tests** (`src/scripting/lua_vm.zig` - 5 tests):
1. ✅ **VM Lifecycle** - Create and destroy VM without leaks
2. ✅ **Execute Simple Code** - Run `x = 42` and verify
3. ✅ **Global Variables** - Set/get numbers and strings
4. ✅ **Lua Math** - Verify `10 + 20 * 3 = 70`
5. ✅ **Lua Strings** - Verify `'Hello' .. ' ' .. 'World'`

**Entity API Tests** (`src/scripting/entity_api.zig` - 8 tests):
1. ✅ **Entity Context** - Set/get entity context via registry
2. ✅ **Self Table Creation** - Verify table structure and properties
3. ✅ **getId from Lua** - Call entity.getId() and verify result
4. ✅ **getPosition from Lua** - Verify {q, r} table returned
5. ✅ **getEnergy from Lua** - Verify energy value
6. ✅ **getRole from Lua** - Verify role string
7. ✅ **isActive from Lua** - Verify boolean result
8. ✅ **Complete Workflow** - Self table + API functions together

**All 13 tests passing**, 0 memory leaks (verified with test allocator).

---

## Next Steps (Phase 2 Continuation)

See [LUA_API_PLANNED.md](LUA_API_PLANNED.md) for complete planned API.

**Immediate Next Steps (Phase 2A Step 2)**:
1. **Action Queue System** (`src/core/action_queue.zig`):
   - Define EntityAction union type
   - Implement action queueing and processing

2. **Entity Action API** (extend `entity_api.zig`):
   - `entity.moveTo(position)` - Queue movement
   - `entity.harvest(position)` - Queue harvesting
   - `entity.consume(resource, amount)` - Queue consumption

**Short-Term (Phase 2B-D)**:
3. **World Query API** (`src/scripting/world_api.zig`):
   - `world.getTileAt(q, r)`, `world.distance()`, `world.neighbors()`
   - `world.findNearbyEntities()`, `world.findEntitiesAt()`

4. **Script Integration**:
   - Integrate scripts into tick system (processTick)
   - Memory table persistence
   - Load scripts from files

5. **Sandboxing**:
   - CPU instruction limits (lua_sethook)
   - Memory limits (lua_setallocf with tracking)
   - Restrict stdlib (remove io, os, debug)

---

## References

- **Implementation**: `src/scripting/lua_vm.zig`, `src/scripting/lua_c.zig`
- **Tests**: `zig build test` (5 Lua VM tests)
- **Lua 5.4 Manual**: https://www.lua.org/manual/5.4/
- **Session 5 Handoff**: `CONTEXT_HANDOFF_PROTOCOL.md` for integration details

---

**Document Version**: 1.1
**Last Updated**: 2025-11-23 (Session 6 - Phase 2 at 45%)
**Phase**: Phase 2 (Lua Integration) - 45% Complete
