/// Lua VM wrapper with Zig-friendly interface
/// Provides safe, idiomatic Zig API for Lua script execution

const std = @import("std");
const lua = @import("lua_c.zig");

pub const LuaError = error{
    OutOfMemory,
    LoadError,
    RuntimeError,
    SyntaxError,
};

pub const LuaVM = struct {
    L: ?*lua.lua_State,
    allocator: std.mem.Allocator,

    /// Create a new Lua VM
    pub fn init(allocator: std.mem.Allocator) !LuaVM {
        const L = lua.newState() orelse return LuaError.OutOfMemory;

        // Open standard libraries
        lua.openLibs(L);

        return LuaVM{
            .L = L,
            .allocator = allocator,
        };
    }

    /// Close the Lua VM and free resources
    pub fn deinit(self: *LuaVM) void {
        if (self.L) |L| {
            lua.close(L);
            self.L = null;
        }
    }

    /// Execute a Lua string
    pub fn doString(self: *LuaVM, code: []const u8) !void {
        const L = self.L orelse return LuaError.RuntimeError;

        // Create null-terminated string for C API
        const code_z = try self.allocator.dupeZ(u8, code);
        defer self.allocator.free(code_z);

        // Load the string
        const load_status = lua.loadString(L, code_z.ptr);
        if (load_status != lua.LUA_OK) {
            const err_msg = try lua.getErrorMessage(L, self.allocator);
            defer self.allocator.free(err_msg);
            std.debug.print("Lua load error: {s}\n", .{err_msg});
            lua.pop(L, 1); // Pop error message
            return if (load_status == lua.LUA_ERRSYNTAX) LuaError.SyntaxError else LuaError.LoadError;
        }

        // Execute the loaded chunk
        const call_status = lua.pcall(L, 0, 0, 0);
        if (call_status != lua.LUA_OK) {
            const err_msg = try lua.getErrorMessage(L, self.allocator);
            defer self.allocator.free(err_msg);
            std.debug.print("Lua runtime error: {s}\n", .{err_msg});
            lua.pop(L, 1); // Pop error message
            return LuaError.RuntimeError;
        }
    }

    /// Get a global number value
    pub fn getGlobalNumber(self: *LuaVM, name: []const u8) !f64 {
        const L = self.L orelse return LuaError.RuntimeError;

        const name_z = try self.allocator.dupeZ(u8, name);
        defer self.allocator.free(name_z);

        _ = lua.getGlobal(L, name_z.ptr);
        defer lua.pop(L, 1);

        if (lua.isNumber(L, -1) == 0) {
            return error.NotANumber;
        }

        return lua.toNumber(L, -1);
    }

    /// Get a global string value
    pub fn getGlobalString(self: *LuaVM, name: []const u8) ![]const u8 {
        const L = self.L orelse return LuaError.RuntimeError;

        const name_z = try self.allocator.dupeZ(u8, name);
        defer self.allocator.free(name_z);

        _ = lua.getGlobal(L, name_z.ptr);
        defer lua.pop(L, 1);

        if (lua.isString(L, -1) == 0) {
            return error.NotAString;
        }

        var len: usize = 0;
        const str_ptr = lua.toString(L, -1, &len);
        return self.allocator.dupe(u8, str_ptr[0..len]);
    }

    /// Set a global number value
    pub fn setGlobalNumber(self: *LuaVM, name: []const u8, value: f64) !void {
        const L = self.L orelse return LuaError.RuntimeError;

        const name_z = try self.allocator.dupeZ(u8, name);
        defer self.allocator.free(name_z);

        lua.pushNumber(L, value);
        lua.setGlobal(L, name_z.ptr);
    }

    /// Set a global string value
    pub fn setGlobalString(self: *LuaVM, name: []const u8, value: []const u8) !void {
        const L = self.L orelse return LuaError.RuntimeError;

        const name_z = try self.allocator.dupeZ(u8, name);
        defer self.allocator.free(name_z);

        lua.pushLString(L, value.ptr, value.len);
        lua.setGlobal(L, name_z.ptr);
    }
};

// === Tests ===

test "LuaVM: create and destroy" {
    var vm = try LuaVM.init(std.testing.allocator);
    defer vm.deinit();
}

test "LuaVM: execute simple Lua code" {
    var vm = try LuaVM.init(std.testing.allocator);
    defer vm.deinit();

    try vm.doString("x = 42");
    const x = try vm.getGlobalNumber("x");
    try std.testing.expectEqual(@as(f64, 42.0), x);
}

test "LuaVM: set and get global values" {
    var vm = try LuaVM.init(std.testing.allocator);
    defer vm.deinit();

    try vm.setGlobalNumber("test_num", 123.456);
    const num = try vm.getGlobalNumber("test_num");
    try std.testing.expectApproxEqAbs(@as(f64, 123.456), num, 0.001);

    try vm.setGlobalString("test_str", "Hello from Zig!");
    const str = try vm.getGlobalString("test_str");
    defer std.testing.allocator.free(str);
    try std.testing.expectEqualStrings("Hello from Zig!", str);
}

test "LuaVM: Lua math operations" {
    var vm = try LuaVM.init(std.testing.allocator);
    defer vm.deinit();

    try vm.doString("result = 10 + 20 * 3");
    const result = try vm.getGlobalNumber("result");
    try std.testing.expectEqual(@as(f64, 70.0), result);
}

test "LuaVM: Lua string operations" {
    var vm = try LuaVM.init(std.testing.allocator);
    defer vm.deinit();

    try vm.doString("greeting = 'Hello' .. ' ' .. 'World'");
    const greeting = try vm.getGlobalString("greeting");
    defer std.testing.allocator.free(greeting);
    try std.testing.expectEqualStrings("Hello World", greeting);
}
