# Lua API - Currently Implemented

**Status**: Phase 2 at 70% complete - Lua VM operational, Entity API complete, World API complete!

This document describes the **currently working** Lua integration. For planned API functions, see [LUA_API_PLANNED.md](LUA_API_PLANNED.md).

---

## Implementation Status

### ✅ Implemented (Phase 2 - 70%)

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
- ✅ Action queue context injection (setActionQueueContext, getActionQueueContext)
- ✅ Self table creation with entity properties
- ✅ `entity.getId()` - Get entity ID
- ✅ `entity.getPosition()` - Get hex position as {q, r} table
- ✅ `entity.getEnergy()` - Get current energy
- ✅ `entity.getMaxEnergy()` - Get maximum energy
- ✅ `entity.getRole()` - Get role as string
- ✅ `entity.isAlive()` - Check if entity is alive
- ✅ `entity.isActive()` - Check if entity is active (alive && has energy)
- ✅ 8 comprehensive integration tests

**Entity Action API** (`src/scripting/entity_api.zig`, `src/core/action_queue.zig`):
- ✅ Action queue system (EntityAction union, ActionQueue data structure)
- ✅ `entity.moveTo(position)` - Queue move action to target hex
- ✅ `entity.harvest(position)` - Queue harvest action (stub for Phase 3)
- ✅ `entity.consume(resource, amount)` - Stub returning false (Phase 3)
- ✅ Command queue pattern - actions queued, then processed by engine
- ✅ 16 comprehensive tests (7 action_queue + 9 entity_api action tests)

**World Query API** (`src/scripting/world_api.zig`):
- ✅ Grid and EntityManager context injection (dual-context pattern)
- ✅ `world.getTileAt(q, r)` - Query tile at hex coordinate
- ✅ `world.distance(pos1, pos2)` - Calculate hex distance between positions
- ✅ `world.neighbors(position)` - Get all 6 neighboring hex coordinates
- ✅ `world.findEntitiesAt(position)` - Find entities at specific position
- ✅ `world.findNearbyEntities(pos, range, role?)` - Find entities within range with optional role filter
- ✅ 13 comprehensive integration tests

### ⏳ In Progress / Not Yet Implemented

- ⏳ World API integration into tick system
- ⏳ Memory persistence (memory table)
- ⏳ Sandboxing (CPU/memory limits)
- ⏳ Per-entity script execution in tick system
- ⏳ Script loading from files
- ⏳ Error handling and debugging
- ⏳ Action execution system (process queued actions)

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
    var action_queue = ActionQueue.init(allocator);
    defer action_queue.deinit();

    // Set up entity context, action queue, and API
    entity_api.setEntityContext(vm.L, &my_entity);
    entity_api.setActionQueueContext(vm.L, &action_queue);
    entity_api.registerEntityAPI(vm.L);
    entity_api.createSelfTable(vm.L, &my_entity);
    lua.setGlobal(vm.L, "self");

    // Now Lua scripts can access entity and queue actions!
    try vm.doString(
        \\-- Query entity state
        \\print("My ID: " .. self.id)
        \\print("Position: " .. self.position.q .. ", " .. self.position.r)
        \\print("Role: " .. self.role)
        \\
        \\local energy = entity.getEnergy()
        \\print("Energy: " .. energy)
        \\
        \\-- Queue actions
        \\if entity.isActive() then
        \\    local success = entity.moveTo({q = 10, r = 5})
        \\    if success then
        \\        print("Move action queued!")
        \\    end
        \\end
    );

    // Process queued actions
    const actions = action_queue.getActions();
    std.debug.print("Queued {d} actions\n", .{actions.len});
}
```

### What Works NOW (New in Session 6 & 7!)

```lua
-- ✅ Entity actions work! (queued for processing)
local success = entity.moveTo({q = 5, r = 5})  -- Returns true if queued
if success then
    print("Moving to (5, 5)")
end

entity.harvest({q = 3, r = 2})  -- Queues harvest action (stub for Phase 3)

-- Multiple actions can be queued
entity.moveTo({q = 1, r = 0})
entity.moveTo({q = 2, r = 0})
-- Both actions queued, engine will process them

-- ✅ World Query API works! (NEW in Session 7)
local tile = world.getTileAt(5, 3)  -- Returns {coord = {q=5, r=3}} or nil
if tile then
    print("Tile exists at " .. tile.coord.q .. ", " .. tile.coord.r)
end

-- ✅ Hex distance calculation
local dist = world.distance({q=0, r=0}, {q=3, r=0})  -- Returns 3

-- ✅ Get neighboring hex coordinates
local neighbors = world.neighbors({q=5, r=5})  -- Returns array of 6 positions
for i = 1, #neighbors do
    print("Neighbor " .. i .. ": " .. neighbors[i].q .. ", " .. neighbors[i].r)
end

-- ✅ Find entities at position
local entities_here = world.findEntitiesAt({q=10, r=10})
print("Found " .. #entities_here .. " entities at (10, 10)")

-- ✅ Find nearby entities (with optional role filter)
local nearby_workers = world.findNearbyEntities({q=0, r=0}, 5, "worker")
local nearby_all = world.findNearbyEntities({q=0, r=0}, 10)  -- All entities in range
```

### What Doesn't Work Yet

```lua
-- ❌ consume() is a stub (Phase 3 - needs resource system)
entity.consume("energy_cell", 5)  -- Always returns false currently

-- ❌ No memory persistence yet
memory.state = "idle"  -- ERROR: 'memory' is undefined

-- ❌ No sandboxing yet (infinite loop will hang)
while true do end  -- Will hang forever (no CPU limit)

-- ❌ Can't call Lua functions from Zig yet
function update() return 42 end  -- Function defined, but no way to call from Zig

-- ❌ Actions not automatically executed yet (Phase 2C)
-- Currently: scripts queue actions, but no automatic execution
-- Need to manually process action_queue.getActions() for now
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

**`src/scripting/entity_api.zig`** (~600 lines, 17 tests):
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

**Entity API Tests** (`src/scripting/entity_api.zig` - 17 tests):
1. ✅ **Entity Context** - Set/get entity context via registry
2. ✅ **Self Table Creation** - Verify table structure and properties
3. ✅ **getId from Lua** - Call entity.getId() and verify result
4. ✅ **getPosition from Lua** - Verify {q, r} table returned
5. ✅ **getEnergy from Lua** - Verify energy value
6. ✅ **getRole from Lua** - Verify role string
7. ✅ **isActive from Lua** - Verify boolean result
8. ✅ **Complete Workflow** - Self table + API functions together
9. ✅ **Action Queue Context** - Set/get action queue context
10. ✅ **moveTo from Lua** - Queue move action and verify
11. ✅ **harvest from Lua** - Queue harvest action and verify
12. ✅ **Multiple Actions** - Queue multiple actions
13. ✅ **Invalid Arguments** - Verify error handling
14. ✅ **Missing Fields** - Verify validation
15. ✅ **Missing Context** - Verify graceful failure
16. ✅ **Queue Clear and Requeue** - Test queue lifecycle
17. ✅ **consume Stub** - Verify stub returns false

**Action Queue Tests** (`src/core/action_queue.zig` - 7 tests):
1. ✅ **Init and Deinit** - Lifecycle management
2. ✅ **Add Move Action** - Queue move action
3. ✅ **Add Harvest Action** - Queue harvest action
4. ✅ **Add Consume Action** - Queue consume action with string
5. ✅ **Add Multiple Actions** - Queue multiple actions
6. ✅ **Clear Actions** - Clear queue
7. ✅ **Clear with Memory** - Verify string cleanup

**World API Tests** (`src/scripting/world_api.zig` - 13 tests):
1. ✅ **Grid Context** - Set/get grid context via registry
2. ✅ **EntityManager Context** - Set/get manager context
3. ✅ **getTileAt with Existing Tile** - Query tile and verify
4. ✅ **getTileAt with Non-Existent Tile** - Verify nil returned
5. ✅ **getTileAt with Table Argument** - Support {q, r} table format
6. ✅ **Distance Calculation** - Verify hex distance formula
7. ✅ **Neighbors Returns 6 Positions** - Verify array of neighbors
8. ✅ **findEntitiesAt with Entities** - Find entities at position
9. ✅ **findEntitiesAt with No Entities** - Verify empty array
10. ✅ **findNearbyEntities without Filter** - Range-based search
11. ✅ **findNearbyEntities with Role Filter** - Filter by entity role
12. ✅ **Complete Workflow** - Multiple queries together
13. ✅ **Edge Cases and Validation** - Invalid arguments handled gracefully

**All 42 tests passing** (5 VM + 17 Entity API + 7 Action Queue + 13 World API), 0 memory leaks (verified with test allocator).

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

**Document Version**: 1.2
**Last Updated**: 2025-11-24 (Session 7 - Phase 2 at 70%)
**Phase**: Phase 2 (Lua Integration) - 70% Complete
