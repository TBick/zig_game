/// Entity Lua API - Exposes entity queries and actions to Lua scripts
/// Provides C functions that can be called from Lua to interact with entities

const std = @import("std");
const lua = @import("lua_c.zig");
const Entity = @import("../entities/entity.zig").Entity;
const EntityRole = @import("../entities/entity.zig").EntityRole;
const HexCoord = @import("../world/hex_grid.zig").HexCoord;

/// Registry key for storing entity pointer
const ENTITY_REGISTRY_KEY = "zig_entity_ptr";

// ============================================================================
// Entity Context Management
// ============================================================================

/// Store entity pointer in Lua registry for C functions to access
pub fn setEntityContext(L: ?*lua.lua_State, entity: *Entity) void {
    lua.pushLightuserdata(L, entity);
    lua.setField(L, lua.LUA_REGISTRYINDEX, ENTITY_REGISTRY_KEY);
}

/// Retrieve entity pointer from Lua registry
/// Returns null if no entity context is set or invalid
pub fn getEntityContext(L: ?*lua.lua_State) ?*Entity {
    _ = lua.getField(L, lua.LUA_REGISTRYINDEX, ENTITY_REGISTRY_KEY);
    defer lua.pop(L, 1);

    if (lua.isNoneOrNil(L, -1)) {
        return null;
    }

    const ptr = lua.toUserdata(L, -1);
    return @ptrCast(ptr);
}

/// Create and populate the 'self' table with entity properties
/// Pushes the table onto the Lua stack
pub fn createSelfTable(L: ?*lua.lua_State, entity: *const Entity) void {
    lua.newTable(L); // Create empty table

    // self.id
    lua.pushInteger(L, @intCast(entity.id));
    lua.setField(L, -2, "id");

    // self.position = {q = ..., r = ...}
    lua.newTable(L);
    lua.pushInteger(L, @intCast(entity.position.q));
    lua.setField(L, -2, "q");
    lua.pushInteger(L, @intCast(entity.position.r));
    lua.setField(L, -2, "r");
    lua.setField(L, -2, "position");

    // self.role
    const role_str = getRoleString(entity.role);
    lua.pushLString(L, role_str.ptr, role_str.len);
    lua.setField(L, -2, "role");

    // self.energy
    lua.pushNumber(L, entity.energy);
    lua.setField(L, -2, "energy");

    // self.max_energy
    lua.pushNumber(L, entity.max_energy);
    lua.setField(L, -2, "max_energy");
}

/// Helper to convert EntityRole to string
fn getRoleString(role: EntityRole) []const u8 {
    return switch (role) {
        .worker => "worker",
        .combat => "combat",
        .scout => "scout",
        .engineer => "engineer",
    };
}

// ============================================================================
// Entity Query Functions (Lua-callable C functions)
// ============================================================================

/// entity.getId() -> number
/// Returns the entity's unique ID
pub fn lua_entity_getId(L: ?*lua.lua_State) callconv(.C) c_int {
    const entity = getEntityContext(L) orelse {
        lua.pushNil(L);
        return 1;
    };

    lua.pushInteger(L, @intCast(entity.id));
    return 1; // Return 1 value
}

/// entity.getPosition() -> {q: number, r: number}
/// Returns the entity's hex coordinate position
pub fn lua_entity_getPosition(L: ?*lua.lua_State) callconv(.C) c_int {
    const entity = getEntityContext(L) orelse {
        lua.pushNil(L);
        return 1;
    };

    // Create table {q = ..., r = ...}
    lua.newTable(L);

    lua.pushInteger(L, @intCast(entity.position.q));
    lua.setField(L, -2, "q");

    lua.pushInteger(L, @intCast(entity.position.r));
    lua.setField(L, -2, "r");

    return 1; // Return 1 value (table)
}

/// entity.getEnergy() -> number
/// Returns the entity's current energy level
pub fn lua_entity_getEnergy(L: ?*lua.lua_State) callconv(.C) c_int {
    const entity = getEntityContext(L) orelse {
        lua.pushNumber(L, 0.0);
        return 1;
    };

    lua.pushNumber(L, entity.energy);
    return 1; // Return 1 value
}

/// entity.getMaxEnergy() -> number
/// Returns the entity's maximum energy capacity
pub fn lua_entity_getMaxEnergy(L: ?*lua.lua_State) callconv(.C) c_int {
    const entity = getEntityContext(L) orelse {
        lua.pushNumber(L, 0.0);
        return 1;
    };

    lua.pushNumber(L, entity.max_energy);
    return 1; // Return 1 value
}

/// entity.getRole() -> string
/// Returns the entity's role as a string ("worker", "combat", "scout", "engineer")
pub fn lua_entity_getRole(L: ?*lua.lua_State) callconv(.C) c_int {
    const entity = getEntityContext(L) orelse {
        lua.pushNil(L);
        return 1;
    };

    const role_str = getRoleString(entity.role);
    lua.pushLString(L, role_str.ptr, role_str.len);
    return 1; // Return 1 value
}

/// entity.isAlive() -> boolean
/// Returns true if the entity is alive
pub fn lua_entity_isAlive(L: ?*lua.lua_State) callconv(.C) c_int {
    const entity = getEntityContext(L) orelse {
        lua.pushBoolean(L, false);
        return 1;
    };

    lua.pushBoolean(L, entity.alive);
    return 1; // Return 1 value
}

/// entity.isActive() -> boolean
/// Returns true if the entity is alive and has energy
pub fn lua_entity_isActive(L: ?*lua.lua_State) callconv(.C) c_int {
    const entity = getEntityContext(L) orelse {
        lua.pushBoolean(L, false);
        return 1;
    };

    lua.pushBoolean(L, entity.isActive());
    return 1; // Return 1 value
}

// ============================================================================
// Module Registration
// ============================================================================

/// Register all entity API functions in the 'entity' table
/// Call this after setting entity context, before executing scripts
pub fn registerEntityAPI(L: ?*lua.lua_State) void {
    // Create 'entity' table
    lua.newTable(L);

    // Register functions
    lua.pushCFunction(L, lua_entity_getId);
    lua.setField(L, -2, "getId");

    lua.pushCFunction(L, lua_entity_getPosition);
    lua.setField(L, -2, "getPosition");

    lua.pushCFunction(L, lua_entity_getEnergy);
    lua.setField(L, -2, "getEnergy");

    lua.pushCFunction(L, lua_entity_getMaxEnergy);
    lua.setField(L, -2, "getMaxEnergy");

    lua.pushCFunction(L, lua_entity_getRole);
    lua.setField(L, -2, "getRole");

    lua.pushCFunction(L, lua_entity_isAlive);
    lua.setField(L, -2, "isAlive");

    lua.pushCFunction(L, lua_entity_isActive);
    lua.setField(L, -2, "isActive");

    // Set as global 'entity' table
    lua.setGlobal(L, "entity");
}

// ============================================================================
// Tests
// ============================================================================

test "Entity API: setEntityContext and getEntityContext" {
    const LuaVM = @import("lua_vm.zig").LuaVM;

    var vm = try LuaVM.init(std.testing.allocator);
    defer vm.deinit();

    var test_entity = Entity.init(42, HexCoord{ .q = 5, .r = 3 }, .worker);

    // Set entity context
    setEntityContext(vm.L, &test_entity);

    // Get entity context
    const retrieved = getEntityContext(vm.L);
    try std.testing.expect(retrieved != null);
    try std.testing.expectEqual(@as(u32, 42), retrieved.?.id);
    try std.testing.expectEqual(@as(i32, 5), retrieved.?.position.q);
    try std.testing.expectEqual(@as(i32, 3), retrieved.?.position.r);
}

test "Entity API: createSelfTable" {
    const LuaVM = @import("lua_vm.zig").LuaVM;

    var vm = try LuaVM.init(std.testing.allocator);
    defer vm.deinit();

    const test_entity = Entity.init(123, HexCoord{ .q = -2, .r = 4 }, .scout);

    // Create self table
    createSelfTable(vm.L, &test_entity);

    // Verify it's on the stack as a table
    try std.testing.expectEqual(lua.LUA_TTABLE, lua.typeOf(vm.L, -1));

    // Check self.id
    _ = lua.getField(vm.L, -1, "id");
    try std.testing.expectEqual(@as(i64, 123), lua.toInteger(vm.L, -1));
    lua.pop(vm.L, 1);

    // Check self.role
    _ = lua.getField(vm.L, -1, "role");
    var len: usize = 0;
    const role_str = lua.toString(vm.L, -1, &len);
    try std.testing.expectEqualStrings("scout", role_str[0..len]);
    lua.pop(vm.L, 1);

    // Check self.energy
    _ = lua.getField(vm.L, -1, "energy");
    try std.testing.expectEqual(@as(f64, 80.0), lua.toNumber(vm.L, -1));
    lua.pop(vm.L, 1);

    // Clean up stack
    lua.pop(vm.L, 1);
}

test "Entity API: lua_entity_getId from Lua" {
    const LuaVM = @import("lua_vm.zig").LuaVM;

    var vm = try LuaVM.init(std.testing.allocator);
    defer vm.deinit();

    var test_entity = Entity.init(999, HexCoord{ .q = 0, .r = 0 }, .engineer);

    // Set entity context and register API
    setEntityContext(vm.L, &test_entity);
    registerEntityAPI(vm.L);

    // Call entity.getId() from Lua
    try vm.doString("result = entity.getId()");

    const id = try vm.getGlobalNumber("result");
    try std.testing.expectEqual(@as(f64, 999.0), id);
}

test "Entity API: lua_entity_getPosition from Lua" {
    const LuaVM = @import("lua_vm.zig").LuaVM;

    var vm = try LuaVM.init(std.testing.allocator);
    defer vm.deinit();

    var test_entity = Entity.init(1, HexCoord{ .q = 7, .r = -3 }, .worker);

    setEntityContext(vm.L, &test_entity);
    registerEntityAPI(vm.L);

    // Call entity.getPosition() from Lua
    try vm.doString("pos = entity.getPosition()");

    // Verify position table
    try vm.doString("q_val = pos.q; r_val = pos.r");
    const q = try vm.getGlobalNumber("q_val");
    const r = try vm.getGlobalNumber("r_val");

    try std.testing.expectEqual(@as(f64, 7.0), q);
    try std.testing.expectEqual(@as(f64, -3.0), r);
}

test "Entity API: lua_entity_getEnergy from Lua" {
    const LuaVM = @import("lua_vm.zig").LuaVM;

    var vm = try LuaVM.init(std.testing.allocator);
    defer vm.deinit();

    var test_entity = Entity.init(1, HexCoord{ .q = 0, .r = 0 }, .combat);
    test_entity.energy = 75.5;

    setEntityContext(vm.L, &test_entity);
    registerEntityAPI(vm.L);

    try vm.doString("energy = entity.getEnergy()");
    const energy = try vm.getGlobalNumber("energy");

    try std.testing.expectApproxEqAbs(@as(f64, 75.5), energy, 0.01);
}

test "Entity API: lua_entity_getRole from Lua" {
    const LuaVM = @import("lua_vm.zig").LuaVM;

    var vm = try LuaVM.init(std.testing.allocator);
    defer vm.deinit();

    var test_entity = Entity.init(1, HexCoord{ .q = 0, .r = 0 }, .scout);

    setEntityContext(vm.L, &test_entity);
    registerEntityAPI(vm.L);

    try vm.doString("role = entity.getRole()");
    const role = try vm.getGlobalString("role");
    defer std.testing.allocator.free(role);

    try std.testing.expectEqualStrings("scout", role);
}

test "Entity API: lua_entity_isActive from Lua" {
    const LuaVM = @import("lua_vm.zig").LuaVM;

    var vm = try LuaVM.init(std.testing.allocator);
    defer vm.deinit();

    var test_entity = Entity.init(1, HexCoord{ .q = 0, .r = 0 }, .worker);

    setEntityContext(vm.L, &test_entity);
    registerEntityAPI(vm.L);

    // Entity should be active (alive with energy)
    try vm.doString("active = entity.isActive()");
    try vm.doString("if active then result = 1 else result = 0 end");
    const active = try vm.getGlobalNumber("result");
    try std.testing.expectEqual(@as(f64, 1.0), active);

    // Kill entity and check again
    test_entity.kill();
    try vm.doString("active2 = entity.isActive()");
    try vm.doString("if active2 then result2 = 1 else result2 = 0 end");
    const inactive = try vm.getGlobalNumber("result2");
    try std.testing.expectEqual(@as(f64, 0.0), inactive);
}

test "Entity API: complete workflow with self table" {
    const LuaVM = @import("lua_vm.zig").LuaVM;

    var vm = try LuaVM.init(std.testing.allocator);
    defer vm.deinit();

    var test_entity = Entity.init(42, HexCoord{ .q = 10, .r = -5 }, .engineer);
    test_entity.energy = 90.0;

    // Set up entity context and API
    setEntityContext(vm.L, &test_entity);
    registerEntityAPI(vm.L);

    // Create and set 'self' table as global
    createSelfTable(vm.L, &test_entity);
    lua.setGlobal(vm.L, "self");

    // Execute Lua script that uses both self table and entity API
    try vm.doString(
        \\-- Access self table
        \\my_id = self.id
        \\my_pos_q = self.position.q
        \\my_role = self.role
        \\
        \\-- Call entity API functions
        \\api_energy = entity.getEnergy()
        \\api_max_energy = entity.getMaxEnergy()
        \\api_is_active = entity.isActive()
    );

    // Verify results
    const id = try vm.getGlobalNumber("my_id");
    try std.testing.expectEqual(@as(f64, 42.0), id);

    const pos_q = try vm.getGlobalNumber("my_pos_q");
    try std.testing.expectEqual(@as(f64, 10.0), pos_q);

    const role = try vm.getGlobalString("my_role");
    defer std.testing.allocator.free(role);
    try std.testing.expectEqualStrings("engineer", role);

    const api_energy = try vm.getGlobalNumber("api_energy");
    try std.testing.expectApproxEqAbs(@as(f64, 90.0), api_energy, 0.01);

    const api_max_energy = try vm.getGlobalNumber("api_max_energy");
    try std.testing.expectApproxEqAbs(@as(f64, 120.0), api_max_energy, 0.01);
}

test "Entity API: negative hex coordinates" {
    const LuaVM = @import("lua_vm.zig").LuaVM;

    var vm = try LuaVM.init(std.testing.allocator);
    defer vm.deinit();

    var test_entity = Entity.init(1, HexCoord{ .q = -100, .r = -50 }, .scout);

    setEntityContext(vm.L, &test_entity);
    registerEntityAPI(vm.L);

    // Test negative coordinates work correctly
    try vm.doString("pos = entity.getPosition()");
    try vm.doString("q_val = pos.q; r_val = pos.r");

    const q = try vm.getGlobalNumber("q_val");
    const r = try vm.getGlobalNumber("r_val");

    try std.testing.expectEqual(@as(f64, -100.0), q);
    try std.testing.expectEqual(@as(f64, -50.0), r);
}

test "Entity API: dead entity behavior" {
    const LuaVM = @import("lua_vm.zig").LuaVM;

    var vm = try LuaVM.init(std.testing.allocator);
    defer vm.deinit();

    var test_entity = Entity.init(1, HexCoord{ .q = 0, .r = 0 }, .worker);
    test_entity.kill(); // Kill the entity

    setEntityContext(vm.L, &test_entity);
    registerEntityAPI(vm.L);

    // Test dead entity properties
    try vm.doString(
        \\is_alive = entity.isAlive()
        \\is_active = entity.isActive()
        \\energy = entity.getEnergy()
    );

    // Verify dead state
    try vm.doString("if is_alive then alive_val = 1 else alive_val = 0 end");
    try vm.doString("if is_active then active_val = 1 else active_val = 0 end");

    const alive = try vm.getGlobalNumber("alive_val");
    const active = try vm.getGlobalNumber("active_val");
    const energy = try vm.getGlobalNumber("energy");

    try std.testing.expectEqual(@as(f64, 0.0), alive); // Not alive
    try std.testing.expectEqual(@as(f64, 0.0), active); // Not active
    try std.testing.expectEqual(@as(f64, 0.0), energy); // Energy is 0
}

test "Entity API: nested table access" {
    const LuaVM = @import("lua_vm.zig").LuaVM;

    var vm = try LuaVM.init(std.testing.allocator);
    defer vm.deinit();

    var test_entity = Entity.init(1, HexCoord{ .q = 7, .r = 3 }, .worker);

    setEntityContext(vm.L, &test_entity);
    registerEntityAPI(vm.L);
    createSelfTable(vm.L, &test_entity);
    lua.setGlobal(vm.L, "self");

    // Test nested table access and arithmetic
    try vm.doString(
        \\-- Access nested position table
        \\q_val = self.position.q
        \\r_val = self.position.r
        \\
        \\-- Arithmetic on nested values
        \\sum = self.position.q + self.position.r
        \\
        \\-- Store position in local variable
        \\local pos = self.position
        \\local_q = pos.q
    );

    const q = try vm.getGlobalNumber("q_val");
    const r = try vm.getGlobalNumber("r_val");
    const sum = try vm.getGlobalNumber("sum");
    const local_q = try vm.getGlobalNumber("local_q");

    try std.testing.expectEqual(@as(f64, 7.0), q);
    try std.testing.expectEqual(@as(f64, 3.0), r);
    try std.testing.expectEqual(@as(f64, 10.0), sum);
    try std.testing.expectEqual(@as(f64, 7.0), local_q);
}

test "Entity API: multiple entity context switches" {
    const LuaVM = @import("lua_vm.zig").LuaVM;

    var vm = try LuaVM.init(std.testing.allocator);
    defer vm.deinit();

    var entity1 = Entity.init(100, HexCoord{ .q = 1, .r = 2 }, .worker);
    var entity2 = Entity.init(200, HexCoord{ .q = 3, .r = 4 }, .scout);

    registerEntityAPI(vm.L);

    // Test entity 1
    setEntityContext(vm.L, &entity1);
    try vm.doString("id1 = entity.getId()");
    const id1 = try vm.getGlobalNumber("id1");
    try std.testing.expectEqual(@as(f64, 100.0), id1);

    // Switch to entity 2
    setEntityContext(vm.L, &entity2);
    try vm.doString("id2 = entity.getId()");
    const id2 = try vm.getGlobalNumber("id2");
    try std.testing.expectEqual(@as(f64, 200.0), id2);

    // Switch back to entity 1
    setEntityContext(vm.L, &entity1);
    try vm.doString("id3 = entity.getId()");
    const id3 = try vm.getGlobalNumber("id3");
    try std.testing.expectEqual(@as(f64, 100.0), id3);
}

test "Entity API: all entity roles" {
    const LuaVM = @import("lua_vm.zig").LuaVM;

    var vm = try LuaVM.init(std.testing.allocator);
    defer vm.deinit();

    registerEntityAPI(vm.L);

    const roles = [_]EntityRole{ .worker, .combat, .scout, .engineer };
    const role_names = [_][]const u8{ "worker", "combat", "scout", "engineer" };
    const max_energies = [_]f64{ 100.0, 150.0, 80.0, 120.0 };

    for (roles, role_names, max_energies) |role, expected_name, expected_max| {
        var test_entity = Entity.init(1, HexCoord{ .q = 0, .r = 0 }, role);

        setEntityContext(vm.L, &test_entity);

        // Test role name
        try vm.doString("role = entity.getRole()");
        const role_str = try vm.getGlobalString("role");
        defer std.testing.allocator.free(role_str);
        try std.testing.expectEqualStrings(expected_name, role_str);

        // Test max energy
        try vm.doString("max_e = entity.getMaxEnergy()");
        const max_e = try vm.getGlobalNumber("max_e");
        try std.testing.expectEqual(expected_max, max_e);
    }
}
