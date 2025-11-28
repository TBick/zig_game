/// Raw Lua 5.4 C API bindings
/// Direct imports from the Lua C library with minimal wrapping.
/// For a Zig-friendly API, use lua_vm.zig instead.

const std = @import("std");

// Opaque Lua state type
pub const lua_State = opaque {};

// Lua basic types
pub const LUA_TNONE = -1;
pub const LUA_TNIL = 0;
pub const LUA_TBOOLEAN = 1;
pub const LUA_TLIGHTUSERDATA = 2;
pub const LUA_TNUMBER = 3;
pub const LUA_TSTRING = 4;
pub const LUA_TTABLE = 5;
pub const LUA_TFUNCTION = 6;
pub const LUA_TUSERDATA = 7;
pub const LUA_TTHREAD = 8;

// Lua number and integer types
pub const lua_Number = f64;
pub const lua_Integer = i64;

// Lua special stack indices
pub const LUA_REGISTRYINDEX = -1001000;
pub const LUA_RIDX_GLOBALS = 2;

// Lua status codes
pub const LUA_OK = 0;
pub const LUA_YIELD = 1;
pub const LUA_ERRRUN = 2;
pub const LUA_ERRSYNTAX = 3;
pub const LUA_ERRMEM = 4;
pub const LUA_ERRERR = 5;

// C function type for Lua
pub const lua_CFunction = *const fn (?*lua_State) callconv(.c) c_int;

// === State manipulation ===
extern fn luaL_newstate() ?*lua_State;
extern fn lua_close(L: ?*lua_State) void;

pub const newState = luaL_newstate;
pub const close = lua_close;

// === Basic stack manipulation ===
extern fn lua_gettop(L: ?*lua_State) c_int;
extern fn lua_settop(L: ?*lua_State, idx: c_int) void;
extern fn lua_pushvalue(L: ?*lua_State, idx: c_int) void;
extern fn lua_rotate(L: ?*lua_State, idx: c_int, n: c_int) void;
extern fn lua_copy(L: ?*lua_State, fromidx: c_int, toidx: c_int) void;

pub const getTop = lua_gettop;
pub const setTop = lua_settop;
pub const pushValue = lua_pushvalue;
pub const rotate = lua_rotate;
pub const copy = lua_copy;

/// Removes element at idx
pub fn remove(L: ?*lua_State, idx: c_int) void {
    lua_rotate(L, idx, -1);
    lua_settop(L, -2);
}

/// Pops n elements from stack
pub fn pop(L: ?*lua_State, n: c_int) void {
    lua_settop(L, -n - 1);
}

// === Access functions (stack → Zig) ===
extern fn lua_isnumber(L: ?*lua_State, idx: c_int) c_int;
extern fn lua_isstring(L: ?*lua_State, idx: c_int) c_int;
extern fn lua_iscfunction(L: ?*lua_State, idx: c_int) c_int;
extern fn lua_isinteger(L: ?*lua_State, idx: c_int) c_int;
extern fn lua_isuserdata(L: ?*lua_State, idx: c_int) c_int;
extern fn lua_type(L: ?*lua_State, idx: c_int) c_int;
extern fn lua_typename(L: ?*lua_State, tp: c_int) [*c]const u8;

pub const isNumber = lua_isnumber;
pub const isString = lua_isstring;
pub const isCFunction = lua_iscfunction;
pub const isInteger = lua_isinteger;
pub const isUserdata = lua_isuserdata;
pub const typeOf = lua_type;
pub const typeName = lua_typename;

pub fn isTable(L: ?*lua_State, idx: c_int) bool {
    return lua_type(L, idx) == LUA_TTABLE;
}

pub fn isLightuserdata(L: ?*lua_State, idx: c_int) bool {
    return lua_type(L, idx) == LUA_TLIGHTUSERDATA;
}

pub fn isNoneOrNil(L: ?*lua_State, idx: c_int) bool {
    return lua_type(L, idx) <= 0;
}

pub fn isBoolean(L: ?*lua_State, idx: c_int) bool {
    return lua_type(L, idx) == LUA_TBOOLEAN;
}

// === Get values from stack ===
extern fn lua_tonumberx(L: ?*lua_State, idx: c_int, isnum: ?*c_int) lua_Number;
extern fn lua_tointegerx(L: ?*lua_State, idx: c_int, isnum: ?*c_int) lua_Integer;
extern fn lua_toboolean(L: ?*lua_State, idx: c_int) c_int;
extern fn lua_tolstring(L: ?*lua_State, idx: c_int, len: ?*usize) [*c]const u8;
extern fn lua_touserdata(L: ?*lua_State, idx: c_int) ?*anyopaque;

pub fn toNumber(L: ?*lua_State, idx: c_int) lua_Number {
    return lua_tonumberx(L, idx, null);
}

pub fn toInteger(L: ?*lua_State, idx: c_int) lua_Integer {
    return lua_tointegerx(L, idx, null);
}

pub fn toBoolean(L: ?*lua_State, idx: c_int) bool {
    return lua_toboolean(L, idx) != 0;
}

pub fn toString(L: ?*lua_State, idx: c_int, len: ?*usize) [*c]const u8 {
    return lua_tolstring(L, idx, len);
}

pub const toUserdata = lua_touserdata;

// === Push values onto stack ===
extern fn lua_pushnil(L: ?*lua_State) void;
extern fn lua_pushnumber(L: ?*lua_State, n: lua_Number) void;
extern fn lua_pushinteger(L: ?*lua_State, n: lua_Integer) void;
extern fn lua_pushlstring(L: ?*lua_State, s: [*c]const u8, len: usize) [*c]const u8;
extern fn lua_pushstring(L: ?*lua_State, s: [*c]const u8) [*c]const u8;
extern fn lua_pushcclosure(L: ?*lua_State, func: lua_CFunction, n: c_int) void;
extern fn lua_pushboolean(L: ?*lua_State, b: c_int) void;
extern fn lua_pushlightuserdata(L: ?*lua_State, p: ?*anyopaque) void;

pub const pushNil = lua_pushnil;
pub const pushNumber = lua_pushnumber;
pub const pushInteger = lua_pushinteger;
pub const pushLString = lua_pushlstring;
pub const pushString = lua_pushstring;
pub const pushCClosure = lua_pushcclosure;
pub const pushLightuserdata = lua_pushlightuserdata;

pub fn pushBoolean(L: ?*lua_State, b: bool) void {
    lua_pushboolean(L, if (b) 1 else 0);
}

pub fn pushCFunction(L: ?*lua_State, func: lua_CFunction) void {
    lua_pushcclosure(L, func, 0);
}

// === Get/Set operations ===
extern fn lua_getglobal(L: ?*lua_State, name: [*c]const u8) c_int;
extern fn lua_setglobal(L: ?*lua_State, name: [*c]const u8) void;
extern fn lua_gettable(L: ?*lua_State, idx: c_int) c_int;
extern fn lua_settable(L: ?*lua_State, idx: c_int) void;
extern fn lua_getfield(L: ?*lua_State, idx: c_int, k: [*c]const u8) c_int;
extern fn lua_setfield(L: ?*lua_State, idx: c_int, k: [*c]const u8) void;
extern fn lua_geti(L: ?*lua_State, idx: c_int, n: lua_Integer) c_int;
extern fn lua_seti(L: ?*lua_State, idx: c_int, n: lua_Integer) void;

pub const getGlobal = lua_getglobal;
pub const setGlobal = lua_setglobal;
pub const getTable = lua_gettable;
pub const setTable = lua_settable;
pub const getField = lua_getfield;
pub const setField = lua_setfield;
pub const getI = lua_geti;
pub const setI = lua_seti;

// === Table operations ===
extern fn lua_createtable(L: ?*lua_State, narr: c_int, nrec: c_int) void;
extern fn lua_rawgeti(L: ?*lua_State, idx: c_int, n: lua_Integer) c_int;

pub const createTable = lua_createtable;
pub const rawGetI = lua_rawgeti;

pub fn newTable(L: ?*lua_State) void {
    lua_createtable(L, 0, 0);
}

// === Load and call functions ===
extern fn luaL_loadstring(L: ?*lua_State, s: [*c]const u8) c_int;
extern fn lua_pcallk(L: ?*lua_State, nargs: c_int, nresults: c_int, msgh: c_int, ctx: isize, k: ?*const anyopaque) c_int;

pub const loadString = luaL_loadstring;

pub fn pcall(L: ?*lua_State, nargs: c_int, nresults: c_int, msgh: c_int) c_int {
    return lua_pcallk(L, nargs, nresults, msgh, 0, null);
}

// === Auxiliary library ===
extern fn luaL_openlibs(L: ?*lua_State) void;
extern fn luaL_requiref(L: ?*lua_State, modname: [*c]const u8, openf: lua_CFunction, glb: c_int) void;
extern fn luaL_ref(L: ?*lua_State, t: c_int) c_int;
extern fn luaL_unref(L: ?*lua_State, t: c_int, ref: c_int) void;

pub const openLibs = luaL_openlibs;
pub const requireF = luaL_requiref;
pub const ref = luaL_ref;
pub const unref = luaL_unref;

// === Utilities ===

/// Helper to run a Lua string and report errors
pub fn doString(L: ?*lua_State, str: [*c]const u8) !void {
    if (luaL_loadstring(L, str) != LUA_OK) {
        return error.LuaLoadError;
    }
    if (pcall(L, 0, 0, 0) != LUA_OK) {
        return error.LuaRuntimeError;
    }
}

/// Get error message from stack (assumes error is on top)
pub fn getErrorMessage(L: ?*lua_State, allocator: std.mem.Allocator) ![]const u8 {
    var len: usize = 0;
    const msg_ptr = lua_tolstring(L, -1, &len);
    if (msg_ptr == null or len == 0) {
        return allocator.dupe(u8, "Unknown Lua error");
    }
    return allocator.dupe(u8, msg_ptr[0..len]);
}
