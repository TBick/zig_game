const std = @import("std");

pub fn main() void {
    std.debug.print("Zig Game - Phase 0 Setup\n", .{});
    std.debug.print("Project initialized successfully!\n", .{});
}

test "basic functionality" {
    try std.testing.expect(true);
}
