const std = @import("std");
const lua = @import("lua_c.zig");
const HexCoord = @import("../world/hex_grid.zig").HexCoord;
const HexGrid = @import("../world/hex_grid.zig").HexGrid;
const Tile = @import("../world/hex_grid.zig").Tile;
const EntityManager = @import("../entities/entity_manager.zig").EntityManager;
const EntityRole = @import("../entities/entity.zig").EntityRole;

/// World API for Lua scripts
/// Provides functions for querying world state (tiles, entities, spatial queries)

// ============================================================================
// Context Management
// ============================================================================

/// Store HexGrid pointer in Lua registry for C functions to access
pub fn setGridContext(L: *lua.lua_State, grid: *HexGrid) void {
    lua.pushLightuserdata(L, grid);
    lua.setField(L, lua.LUA_REGISTRYINDEX, "zig_grid_ptr");
}

/// Retrieve HexGrid pointer from Lua registry
pub fn getGridContext(L: *lua.lua_State) ?*HexGrid {
    _ = lua.getField(L, lua.LUA_REGISTRYINDEX, "zig_grid_ptr");
    if (!lua.isLightuserdata(L, -1)) {
        lua.pop(L, 1);
        return null;
    }
    const ptr = lua.toUserdata(L, -1);
    lua.pop(L, 1);

    if (ptr == null) return null;
    return @ptrCast(@alignCast(ptr));
}

/// Store EntityManager pointer in Lua registry for C functions to access
pub fn setEntityManagerContext(L: *lua.lua_State, manager: *EntityManager) void {
    lua.pushLightuserdata(L, manager);
    lua.setField(L, lua.LUA_REGISTRYINDEX, "zig_entity_manager_ptr");
}

/// Retrieve EntityManager pointer from Lua registry
pub fn getEntityManagerContext(L: *lua.lua_State) ?*EntityManager {
    _ = lua.getField(L, lua.LUA_REGISTRYINDEX, "zig_entity_manager_ptr");
    if (!lua.isLightuserdata(L, -1)) {
        lua.pop(L, 1);
        return null;
    }
    const ptr = lua.toUserdata(L, -1);
    lua.pop(L, 1);

    if (ptr == null) return null;
    return @ptrCast(@alignCast(ptr));
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Read a position table from the Lua stack at the given index
/// Expected format: {q = number, r = number}
/// Returns null if the table is invalid
fn readPositionTable(L: ?*lua.lua_State, index: i32) ?HexCoord {
    if (!lua.isTable(L, index)) {
        return null;
    }

    // Get q field
    _ = lua.getField(L, index, "q");
    if (lua.isNumber(L, -1) == 0) {
        lua.pop(L, 1);
        return null;
    }
    const q: i32 = @intFromFloat(lua.toNumber(L, -1));
    lua.pop(L, 1);

    // Get r field
    _ = lua.getField(L, index, "r");
    if (lua.isNumber(L, -1) == 0) {
        lua.pop(L, 1);
        return null;
    }
    const r: i32 = @intFromFloat(lua.toNumber(L, -1));
    lua.pop(L, 1);

    return HexCoord.init(q, r);
}

/// Push a position as a Lua table {q = ..., r = ...}
fn pushPositionTable(L: ?*lua.lua_State, pos: HexCoord) void {
    lua.createTable(L, 0, 2);

    lua.pushNumber(L, @floatFromInt(pos.q));
    lua.setField(L, -2, "q");

    lua.pushNumber(L, @floatFromInt(pos.r));
    lua.setField(L, -2, "r");
}

// ============================================================================
// World Query API - C Functions Callable from Lua
// ============================================================================

/// world.getTileAt(q, r) -> table or nil
/// Get tile information at the given hex coordinate
/// Returns: {coord = {q, r}} or nil if no tile exists
export fn lua_world_getTileAt(L: ?*lua.lua_State) c_int {
    // Check arguments
    if (lua.getTop(L) < 1) {
        return 0; // Return nil (no tile)
    }

    // Read position argument (can be table {q, r} or two separate numbers)
    var coord: HexCoord = undefined;
    if (lua.isTable(L, 1)) {
        // Position passed as table {q, r}
        if (readPositionTable(L, 1)) |pos| {
            coord = pos;
        } else {
            return 0; // Invalid table format
        }
    } else if (lua.isNumber(L, 1) != 0 and lua.isNumber(L, 2) != 0) {
        // Position passed as two separate numbers (q, r)
        const q: i32 = @intFromFloat(lua.toNumber(L, 1));
        const r: i32 = @intFromFloat(lua.toNumber(L, 2));
        coord = HexCoord.init(q, r);
    } else {
        return 0; // Invalid arguments
    }

    // Get grid context
    const grid = getGridContext(L.?) orelse return 0;

    // Query tile
    if (grid.getTile(coord)) |tile| {
        // Return tile as table {coord = {q, r}}
        lua.createTable(L, 0, 1);
        pushPositionTable(L, tile.coord);
        lua.setField(L, -2, "coord");
        return 1;
    }

    return 0; // No tile found
}

/// world.distance(pos1, pos2) -> number
/// Calculate hex distance between two positions
/// Args: pos1 = {q, r}, pos2 = {q, r}
/// Returns: distance as number, or nil on error
export fn lua_world_distance(L: ?*lua.lua_State) c_int {
    if (lua.getTop(L) < 2) {
        return 0; // Not enough arguments
    }

    // Read both positions
    const pos1 = readPositionTable(L, 1) orelse return 0;
    const pos2 = readPositionTable(L, 2) orelse return 0;

    // Calculate distance
    const dist = pos1.distance(pos2);
    lua.pushNumber(L, @floatFromInt(dist));
    return 1;
}

/// world.neighbors(position) -> array of 6 positions
/// Get all 6 neighboring hex coordinates
/// Args: position = {q, r}
/// Returns: array of tables {{q, r}, {q, r}, ...} with 6 entries
export fn lua_world_neighbors(L: ?*lua.lua_State) c_int {
    if (lua.getTop(L) < 1) {
        return 0;
    }

    // Read position
    const pos = readPositionTable(L, 1) orelse return 0;

    // Get all neighbors
    const neighbor_coords = pos.neighbors();

    // Create array table with 6 entries
    lua.createTable(L, 6, 0);

    for (neighbor_coords, 0..) |neighbor, i| {
        pushPositionTable(L, neighbor);
        lua.setI(L, -2, @intCast(i + 1)); // Lua arrays are 1-indexed
    }

    return 1;
}

/// world.findEntitiesAt(position) -> array of entity IDs
/// Find all entities at a specific position
/// Args: position = {q, r}
/// Returns: array of entity IDs (numbers)
export fn lua_world_findEntitiesAt(L: ?*lua.lua_State) c_int {
    if (lua.getTop(L) < 1) {
        return 0;
    }

    // Read position
    const pos = readPositionTable(L, 1) orelse return 0;

    // Get entity manager context
    const manager = getEntityManagerContext(L.?) orelse return 0;

    // Query entities at position (use stack buffer for up to 100 entities)
    var buffer: [100]u32 = undefined;
    const count = manager.getEntitiesAt(pos, &buffer);

    // Create array table
    lua.createTable(L, @intCast(count), 0);

    for (0..count) |i| {
        lua.pushNumber(L, @floatFromInt(buffer[i]));
        lua.setI(L, -2, @intCast(i + 1)); // Lua arrays are 1-indexed
    }

    return 1;
}

/// world.findNearbyEntities(position, range, role) -> array of entity IDs
/// Find entities within range of a position, optionally filtered by role
/// Args:
///   - position = {q, r}
///   - range = number (hex distance)
///   - role = string (optional: "worker", "combat", "scout", "engineer")
/// Returns: array of entity IDs
export fn lua_world_findNearbyEntities(L: ?*lua.lua_State) c_int {
    if (lua.getTop(L) < 2) {
        return 0; // Need at least position and range
    }

    // Read position
    const pos = readPositionTable(L, 1) orelse return 0;

    // Read range
    if (lua.isNumber(L, 2) == 0) {
        return 0;
    }
    const range: u32 = @intFromFloat(lua.toNumber(L, 2));

    // Read optional role filter
    var role_filter: ?EntityRole = null;
    if (lua.getTop(L) >= 3 and lua.isString(L, 3) != 0) {
        var len: usize = 0;
        const role_str_ptr = lua.toString(L, 3, &len);
        const role_str = role_str_ptr[0..len];
        if (std.mem.eql(u8, role_str, "worker")) {
            role_filter = .worker;
        } else if (std.mem.eql(u8, role_str, "combat")) {
            role_filter = .combat;
        } else if (std.mem.eql(u8, role_str, "scout")) {
            role_filter = .scout;
        } else if (std.mem.eql(u8, role_str, "engineer")) {
            role_filter = .engineer;
        }
    }

    // Get entity manager context
    const manager = getEntityManagerContext(L.?) orelse return 0;

    // Find all alive entities and filter by distance and role
    const all_entities = manager.getAliveEntities();

    // Use stack buffer for results (up to 100 entities)
    var results: [100]u32 = undefined;
    var result_count: usize = 0;

    for (all_entities) |entity| {
        if (!entity.alive) continue;

        // Check distance
        const dist = pos.distance(entity.position);
        if (dist > range) continue;

        // Check role filter
        if (role_filter) |filter_role| {
            if (entity.role != filter_role) continue;
        }

        // Add to results
        if (result_count < results.len) {
            results[result_count] = entity.id;
            result_count += 1;
        }
    }

    // Create array table
    lua.createTable(L, @intCast(result_count), 0);

    for (0..result_count) |i| {
        lua.pushNumber(L, @floatFromInt(results[i]));
        lua.setI(L, -2, @intCast(i + 1)); // Lua arrays are 1-indexed
    }

    return 1;
}

// ============================================================================
// Module Registration
// ============================================================================

/// Register all world API functions in the global 'world' table
pub fn registerWorldAPI(L: *lua.lua_State) void {
    // Create 'world' table
    lua.createTable(L, 0, 5);

    // Register functions
    lua.pushCFunction(L, lua_world_getTileAt);
    lua.setField(L, -2, "getTileAt");

    lua.pushCFunction(L, lua_world_distance);
    lua.setField(L, -2, "distance");

    lua.pushCFunction(L, lua_world_neighbors);
    lua.setField(L, -2, "neighbors");

    lua.pushCFunction(L, lua_world_findEntitiesAt);
    lua.setField(L, -2, "findEntitiesAt");

    lua.pushCFunction(L, lua_world_findNearbyEntities);
    lua.setField(L, -2, "findNearbyEntities");

    // Set 'world' as global
    lua.setGlobal(L, "world");
}

// ============================================================================
// Tests
// ============================================================================

const testing = std.testing;
const LuaVM = @import("lua_vm.zig").LuaVM;

test "world_api: context set/get for grid" {
    var vm = try LuaVM.init(testing.allocator);
    defer vm.deinit();

    var grid = HexGrid.init(testing.allocator);
    defer grid.deinit();

    // Set and get grid context
    setGridContext(vm.L.?, &grid);
    const retrieved = getGridContext(vm.L.?);
    try testing.expect(retrieved != null);
    try testing.expectEqual(&grid, retrieved.?);
}

test "world_api: context set/get for entity manager" {
    var vm = try LuaVM.init(testing.allocator);
    defer vm.deinit();

    var manager = try EntityManager.init(testing.allocator);
    defer manager.deinit();

    // Set and get manager context
    setEntityManagerContext(vm.L.?, &manager);
    const retrieved = getEntityManagerContext(vm.L.?);
    try testing.expect(retrieved != null);
    try testing.expectEqual(&manager, retrieved.?);
}

test "world_api: getTileAt with existing tile" {
    var vm = try LuaVM.init(testing.allocator);
    defer vm.deinit();

    var grid = HexGrid.init(testing.allocator);
    defer grid.deinit();

    // Create a tile
    const coord = HexCoord.init(5, 3);
    try grid.setTile(coord);

    // Set context and register API
    setGridContext(vm.L.?, &grid);
    registerWorldAPI(vm.L.?);

    // Test getTileAt
    try vm.doString(
        \\local tile = world.getTileAt(5, 3)
        \\assert(tile ~= nil, "Tile should exist")
        \\assert(tile.coord.q == 5, "Tile q should be 5")
        \\assert(tile.coord.r == 3, "Tile r should be 3")
    );
}

test "world_api: getTileAt with non-existent tile" {
    var vm = try LuaVM.init(testing.allocator);
    defer vm.deinit();

    var grid = HexGrid.init(testing.allocator);
    defer grid.deinit();

    setGridContext(vm.L.?, &grid);
    registerWorldAPI(vm.L.?);

    // Test getTileAt on empty grid
    try vm.doString(
        \\local tile = world.getTileAt(10, 10)
        \\assert(tile == nil, "Tile should not exist")
    );
}

test "world_api: getTileAt with table argument" {
    var vm = try LuaVM.init(testing.allocator);
    defer vm.deinit();

    var grid = HexGrid.init(testing.allocator);
    defer grid.deinit();

    const coord = HexCoord.init(7, -2);
    try grid.setTile(coord);

    setGridContext(vm.L.?, &grid);
    registerWorldAPI(vm.L.?);

    // Test getTileAt with table argument
    try vm.doString(
        \\local tile = world.getTileAt({q = 7, r = -2})
        \\assert(tile ~= nil, "Tile should exist")
        \\assert(tile.coord.q == 7, "Tile q should be 7")
        \\assert(tile.coord.r == -2, "Tile r should be -2")
    );
}

test "world_api: distance calculation" {
    var vm = try LuaVM.init(testing.allocator);
    defer vm.deinit();

    var grid = HexGrid.init(testing.allocator);
    defer grid.deinit();

    setGridContext(vm.L.?, &grid);
    registerWorldAPI(vm.L.?);

    // Test distance calculation
    try vm.doString(
        \\local dist = world.distance({q = 0, r = 0}, {q = 3, r = 0})
        \\assert(dist == 3, "Distance should be 3")
        \\
        \\local dist2 = world.distance({q = 0, r = 0}, {q = 2, r = 2})
        \\assert(dist2 == 4, "Distance should be 4")
    );
}

test "world_api: neighbors returns 6 positions" {
    var vm = try LuaVM.init(testing.allocator);
    defer vm.deinit();

    var grid = HexGrid.init(testing.allocator);
    defer grid.deinit();

    setGridContext(vm.L.?, &grid);
    registerWorldAPI(vm.L.?);

    // Test neighbors
    try vm.doString(
        \\local neighbors = world.neighbors({q = 5, r = 5})
        \\assert(#neighbors == 6, "Should have 6 neighbors")
        \\
        \\-- Check that all neighbors are tables with q and r fields
        \\for i = 1, 6 do
        \\    assert(neighbors[i].q ~= nil, "Neighbor should have q")
        \\    assert(neighbors[i].r ~= nil, "Neighbor should have r")
        \\end
        \\
        \\-- Verify one specific neighbor (east: q+1, r+0)
        \\assert(neighbors[1].q == 6, "East neighbor q should be 6")
        \\assert(neighbors[1].r == 5, "East neighbor r should be 5")
    );
}

test "world_api: findEntitiesAt with entities" {
    var vm = try LuaVM.init(testing.allocator);
    defer vm.deinit();

    var grid = HexGrid.init(testing.allocator);
    defer grid.deinit();

    var manager = try EntityManager.init(testing.allocator);
    defer manager.deinit();

    // Spawn entities at position
    const pos = HexCoord.init(10, 10);
    const id1 = try manager.spawn(pos, .worker);
    const id2 = try manager.spawn(pos, .combat);

    setGridContext(vm.L.?, &grid);
    setEntityManagerContext(vm.L.?, &manager);
    registerWorldAPI(vm.L.?);

    // Test findEntitiesAt
    const script = std.fmt.allocPrint(testing.allocator,
        \\local entities = world.findEntitiesAt({{q = 10, r = 10}})
        \\assert(#entities == 2, "Should find 2 entities")
        \\assert(entities[1] == {d} or entities[2] == {d}, "Should find entity 1")
        \\assert(entities[1] == {d} or entities[2] == {d}, "Should find entity 2")
    , .{id1, id1, id2, id2}) catch unreachable;
    defer testing.allocator.free(script);

    try vm.doString(script);
}

test "world_api: findEntitiesAt with no entities" {
    var vm = try LuaVM.init(testing.allocator);
    defer vm.deinit();

    var grid = HexGrid.init(testing.allocator);
    defer grid.deinit();

    var manager = try EntityManager.init(testing.allocator);
    defer manager.deinit();

    setGridContext(vm.L.?, &grid);
    setEntityManagerContext(vm.L.?, &manager);
    registerWorldAPI(vm.L.?);

    // Test findEntitiesAt on empty position
    try vm.doString(
        \\local entities = world.findEntitiesAt({q = 5, r = 5})
        \\assert(#entities == 0, "Should find 0 entities")
    );
}

test "world_api: findNearbyEntities without role filter" {
    var vm = try LuaVM.init(testing.allocator);
    defer vm.deinit();

    var grid = HexGrid.init(testing.allocator);
    defer grid.deinit();

    var manager = try EntityManager.init(testing.allocator);
    defer manager.deinit();

    // Spawn entities at various distances
    _ = try manager.spawn(HexCoord.init(0, 0), .worker);  // distance 0
    _ = try manager.spawn(HexCoord.init(1, 0), .combat);  // distance 1
    _ = try manager.spawn(HexCoord.init(2, 0), .scout);   // distance 2
    _ = try manager.spawn(HexCoord.init(5, 0), .engineer); // distance 5

    setGridContext(vm.L.?, &grid);
    setEntityManagerContext(vm.L.?, &manager);
    registerWorldAPI(vm.L.?);

    // Test findNearbyEntities with range 2 (should find 3 entities)
    try vm.doString(
        \\local entities = world.findNearbyEntities({q = 0, r = 0}, 2)
        \\assert(#entities == 3, "Should find 3 entities within range 2")
    );
}

test "world_api: findNearbyEntities with role filter" {
    var vm = try LuaVM.init(testing.allocator);
    defer vm.deinit();

    var grid = HexGrid.init(testing.allocator);
    defer grid.deinit();

    var manager = try EntityManager.init(testing.allocator);
    defer manager.deinit();

    // Spawn entities with different roles
    _ = try manager.spawn(HexCoord.init(0, 0), .worker);
    _ = try manager.spawn(HexCoord.init(1, 0), .worker);
    _ = try manager.spawn(HexCoord.init(0, 1), .combat);
    _ = try manager.spawn(HexCoord.init(1, 1), .scout);

    setGridContext(vm.L.?, &grid);
    setEntityManagerContext(vm.L.?, &manager);
    registerWorldAPI(vm.L.?);

    // Test findNearbyEntities with role filter (workers only)
    try vm.doString(
        \\local workers = world.findNearbyEntities({q = 0, r = 0}, 5, "worker")
        \\assert(#workers == 2, "Should find 2 workers")
        \\
        \\local combats = world.findNearbyEntities({q = 0, r = 0}, 5, "combat")
        \\assert(#combats == 1, "Should find 1 combat unit")
    );
}

test "world_api: complete workflow with multiple queries" {
    var vm = try LuaVM.init(testing.allocator);
    defer vm.deinit();

    var grid = HexGrid.init(testing.allocator);
    defer grid.deinit();

    var manager = try EntityManager.init(testing.allocator);
    defer manager.deinit();

    // Setup world
    try grid.setTile(HexCoord.init(5, 5));
    try grid.setTile(HexCoord.init(6, 5));
    _ = try manager.spawn(HexCoord.init(5, 5), .worker);
    _ = try manager.spawn(HexCoord.init(6, 5), .combat);

    setGridContext(vm.L.?, &grid);
    setEntityManagerContext(vm.L.?, &manager);
    registerWorldAPI(vm.L.?);

    // Test complete workflow
    try vm.doString(
        \\-- Check current position has a tile
        \\local tile = world.getTileAt(5, 5)
        \\assert(tile ~= nil, "Current position should have a tile")
        \\
        \\-- Get neighbors
        \\local neighbors = world.neighbors(tile.coord)
        \\assert(#neighbors == 6, "Should have 6 neighbors")
        \\
        \\-- Calculate distance to neighbor
        \\local dist = world.distance(tile.coord, neighbors[1])
        \\assert(dist == 1, "Neighbor should be distance 1")
        \\
        \\-- Find entities at current position
        \\local here = world.findEntitiesAt({q = 5, r = 5})
        \\assert(#here == 1, "Should find 1 entity here")
        \\
        \\-- Find nearby entities
        \\local nearby = world.findNearbyEntities({q = 5, r = 5}, 1)
        \\assert(#nearby == 2, "Should find 2 entities within range 1")
    );
}
