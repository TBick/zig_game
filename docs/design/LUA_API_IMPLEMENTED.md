# Lua API - Currently Implemented

**Status**: Phase 2 at 30% complete - Basic Lua VM operational, game APIs not yet implemented.

This document describes the **currently working** Lua integration. For planned API functions, see [LUA_API_PLANNED.md](LUA_API_PLANNED.md).

---

## Implementation Status

### ✅ Implemented (Phase 2 - 30%)

**Lua VM Foundation** (`src/scripting/`):
- ✅ Lua 5.4.8 integrated with raw C bindings
- ✅ VM lifecycle management (init, deinit)
- ✅ Script execution (`doString`)
- ✅ Global variable access (get/set for numbers and strings)
- ✅ 5 comprehensive tests covering VM operations

### ⏳ In Progress / Not Yet Implemented

- ⏳ Entity API (entity.*, see LUA_API_PLANNED.md)
- ⏳ World API (world.*, see LUA_API_PLANNED.md)
- ⏳ Sandboxing (CPU/memory limits)
- ⏳ Per-entity script execution
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

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var vm = try LuaVM.init(allocator);
    defer vm.deinit();

    // Execute Lua math
    try vm.doString("result = 10 + 20 * 3");
    const result = try vm.getGlobalNumber("result");
    std.debug.print("Result: {d}\n", .{result}); // Prints: 70

    // Execute Lua string operations
    try vm.doString("greeting = 'Hello' .. ' ' .. 'World'");
    const greeting = try vm.getGlobalString("greeting");
    defer allocator.free(greeting);
    std.debug.print("{s}\n", .{greeting}); // Prints: Hello World
}
```

### What Doesn't Work Yet

```zig
// ❌ No entity API yet
try vm.doString("entity.move('north')"); // ERROR: 'entity' is undefined

// ❌ No world query API yet
try vm.doString("local tile = world.getTileAt(0, 0)"); // ERROR: 'world' is undefined

// ❌ No sandboxing yet
try vm.doString("while true do end"); // Will hang forever (no CPU limit)

// ❌ Can't pass Zig structs to Lua yet
const entity = Entity{ .id = 1, .role = .worker };
// No way to expose 'entity' to Lua

// ❌ Can't call Lua functions from Zig yet
try vm.doString("function update() return 42 end");
// No way to call update() and get the return value
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

**`src/scripting/lua_c.zig`** (~200 lines):
- Raw C API bindings to Lua 5.4
- Direct `extern fn` declarations
- Zig-friendly helper functions (pop, remove, isBoolean, etc.)
- Error message extraction

**`src/scripting/lua_vm.zig`** (~170 lines, 5 tests):
- High-level Zig API
- `LuaVM` struct with lifecycle management
- Memory-safe string handling with allocators
- Error types (`LuaError.OutOfMemory`, `LuaError.RuntimeError`, etc.)

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

**Current Test Coverage** (`src/scripting/lua_vm.zig`):

1. ✅ **VM Lifecycle** - Create and destroy VM without leaks
2. ✅ **Execute Simple Code** - Run `x = 42` and verify
3. ✅ **Global Variables** - Set/get numbers and strings
4. ✅ **Lua Math** - Verify `10 + 20 * 3 = 70`
5. ✅ **Lua Strings** - Verify `'Hello' .. ' ' .. 'World'`

**All 5 tests passing**, 0 memory leaks (verified with test allocator).

---

## Next Steps (Phase 2 Continuation)

See [LUA_API_PLANNED.md](LUA_API_PLANNED.md) for complete planned API.

**Immediate Next Steps**:
1. **Entity Lua API** (`src/scripting/entity_api.zig`):
   - Expose `entity` table to scripts
   - Implement `entity.getPosition()`, `entity.move()`, etc.
   - Pass entity pointer via Lua userdata

2. **World Query API** (`src/scripting/world_api.zig`):
   - Expose `world` table to scripts
   - Implement `world.getTileAt()`, `world.findEntities()`, etc.

3. **Sandboxing**:
   - CPU instruction limits (lua_sethook)
   - Memory limits (lua_setallocf with tracking)
   - Restrict stdlib (remove io, os, debug)

4. **Script Integration**:
   - Load scripts from files
   - Per-entity script execution in tick loop
   - Error handling and recovery

---

## References

- **Implementation**: `src/scripting/lua_vm.zig`, `src/scripting/lua_c.zig`
- **Tests**: `zig build test` (5 Lua VM tests)
- **Lua 5.4 Manual**: https://www.lua.org/manual/5.4/
- **Session 5 Handoff**: `CONTEXT_HANDOFF_PROTOCOL.md` for integration details

---

**Document Version**: 1.0
**Last Updated**: 2025-11-12 (Session 6 - Phase 2 at 30%)
**Phase**: Phase 2 (Lua Integration) - 30% Complete
