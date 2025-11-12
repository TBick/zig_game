const std = @import("std");

pub fn build(b: *std.Build) void {
    // Standard target options
    const target = b.standardTargetOptions(.{});

    // Standard optimization options
    const optimize = b.standardOptimizeOption(.{});

    // Optional custom install directory
    const install_dir = b.option([]const u8, "install-dir", "Custom installation directory") orelse null;

    // Get raylib-zig dependency
    const raylib_dep = b.dependency("raylib_zig", .{
        .target = target,
        .optimize = optimize,
    });

    const raylib = raylib_dep.module("raylib");
    const raylib_artifact = raylib_dep.artifact("raylib");

    // Create the executable
    const exe = b.addExecutable(.{
        .name = "zig_game",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "raylib", .module = raylib },
            },
        }),
    });

    // Link raylib
    exe.linkLibrary(raylib_artifact);

    // Add Lua 5.4 C source files directly
    exe.addCSourceFiles(.{
        .files = &.{
            "vendor/lua-5.4.8/src/lapi.c",
            "vendor/lua-5.4.8/src/lcode.c",
            "vendor/lua-5.4.8/src/lctype.c",
            "vendor/lua-5.4.8/src/ldebug.c",
            "vendor/lua-5.4.8/src/ldo.c",
            "vendor/lua-5.4.8/src/ldump.c",
            "vendor/lua-5.4.8/src/lfunc.c",
            "vendor/lua-5.4.8/src/lgc.c",
            "vendor/lua-5.4.8/src/llex.c",
            "vendor/lua-5.4.8/src/lmem.c",
            "vendor/lua-5.4.8/src/lobject.c",
            "vendor/lua-5.4.8/src/lopcodes.c",
            "vendor/lua-5.4.8/src/lparser.c",
            "vendor/lua-5.4.8/src/lstate.c",
            "vendor/lua-5.4.8/src/lstring.c",
            "vendor/lua-5.4.8/src/ltable.c",
            "vendor/lua-5.4.8/src/ltm.c",
            "vendor/lua-5.4.8/src/lundump.c",
            "vendor/lua-5.4.8/src/lvm.c",
            "vendor/lua-5.4.8/src/lzio.c",
            "vendor/lua-5.4.8/src/lauxlib.c",
            "vendor/lua-5.4.8/src/lbaselib.c",
            "vendor/lua-5.4.8/src/lcorolib.c",
            "vendor/lua-5.4.8/src/ldblib.c",
            "vendor/lua-5.4.8/src/liolib.c",
            "vendor/lua-5.4.8/src/lmathlib.c",
            "vendor/lua-5.4.8/src/loadlib.c",
            "vendor/lua-5.4.8/src/loslib.c",
            "vendor/lua-5.4.8/src/lstrlib.c",
            "vendor/lua-5.4.8/src/ltablib.c",
            "vendor/lua-5.4.8/src/lutf8lib.c",
            "vendor/lua-5.4.8/src/linit.c",
        },
        .flags = &.{
            "-std=c99",
            "-DLUA_USE_LINUX",
        },
    });
    exe.addIncludePath(b.path("vendor/lua-5.4.8/src"));
    exe.linkLibC();

    // Install the executable to default location (zig-out/bin/)
    b.installArtifact(exe);

    // If custom install directory specified, also copy there
    if (install_dir) |dir| {
        const install_file = b.addInstallFileWithDir(
            exe.getEmittedBin(),
            .{ .custom = dir },
            b.fmt("{s}{s}", .{ exe.name, target.result.exeFileExt() }),
        );
        b.getInstallStep().dependOn(&install_file.step);
    }

    // Create run step
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    // Allow passing arguments to the application
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // Create run step for user
    const run_step = b.step("run", "Run the application");
    run_step.dependOn(&run_cmd.step);

    // Create test step
    const exe_unit_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "raylib", .module = raylib },
            },
        }),
    });

    // Link raylib to test target
    exe_unit_tests.linkLibrary(raylib_artifact);

    // Add Lua 5.4 C source files to tests
    exe_unit_tests.addCSourceFiles(.{
        .files = &.{
            "vendor/lua-5.4.8/src/lapi.c",
            "vendor/lua-5.4.8/src/lcode.c",
            "vendor/lua-5.4.8/src/lctype.c",
            "vendor/lua-5.4.8/src/ldebug.c",
            "vendor/lua-5.4.8/src/ldo.c",
            "vendor/lua-5.4.8/src/ldump.c",
            "vendor/lua-5.4.8/src/lfunc.c",
            "vendor/lua-5.4.8/src/lgc.c",
            "vendor/lua-5.4.8/src/llex.c",
            "vendor/lua-5.4.8/src/lmem.c",
            "vendor/lua-5.4.8/src/lobject.c",
            "vendor/lua-5.4.8/src/lopcodes.c",
            "vendor/lua-5.4.8/src/lparser.c",
            "vendor/lua-5.4.8/src/lstate.c",
            "vendor/lua-5.4.8/src/lstring.c",
            "vendor/lua-5.4.8/src/ltable.c",
            "vendor/lua-5.4.8/src/ltm.c",
            "vendor/lua-5.4.8/src/lundump.c",
            "vendor/lua-5.4.8/src/lvm.c",
            "vendor/lua-5.4.8/src/lzio.c",
            "vendor/lua-5.4.8/src/lauxlib.c",
            "vendor/lua-5.4.8/src/lbaselib.c",
            "vendor/lua-5.4.8/src/lcorolib.c",
            "vendor/lua-5.4.8/src/ldblib.c",
            "vendor/lua-5.4.8/src/liolib.c",
            "vendor/lua-5.4.8/src/lmathlib.c",
            "vendor/lua-5.4.8/src/loadlib.c",
            "vendor/lua-5.4.8/src/loslib.c",
            "vendor/lua-5.4.8/src/lstrlib.c",
            "vendor/lua-5.4.8/src/ltablib.c",
            "vendor/lua-5.4.8/src/lutf8lib.c",
            "vendor/lua-5.4.8/src/linit.c",
        },
        .flags = &.{
            "-std=c99",
            "-DLUA_USE_LINUX",
        },
    });
    exe_unit_tests.addIncludePath(b.path("vendor/lua-5.4.8/src"));
    exe_unit_tests.linkLibC();

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    // Test step for user
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}
