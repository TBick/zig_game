const std = @import("std");

/// Lua source files - shared between exe and test targets
const lua_sources = [_][]const u8{
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
};

/// Windows output directory (WSL path to D:\Projects\ZigGame\)
const windows_output_dir = "/mnt/d/Projects/ZigGame";

/// Configure Lua for a compile step
fn configureLua(step: *std.Build.Step.Compile, b: *std.Build, target: std.Build.ResolvedTarget) void {
    const lua_platform_define = switch (target.result.os.tag) {
        .windows => "-DLUA_USE_WINDOWS",
        .linux => "-DLUA_USE_LINUX",
        .macos => "-DLUA_USE_MACOSX",
        else => "-DLUA_USE_POSIX",
    };

    step.addCSourceFiles(.{
        .files = &lua_sources,
        .flags = &.{ "-std=c99", lua_platform_define },
    });
    step.addIncludePath(b.path("vendor/lua-5.4.8/src"));
    step.linkLibC();
}

/// Create an executable with raylib and Lua configured
fn createExe(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) *std.Build.Step.Compile {
    // Get raylib-zig dependency for this target
    const raylib_dep = b.dependency("raylib_zig", .{
        .target = target,
        .optimize = optimize,
    });
    const raylib = raylib_dep.module("raylib");
    const raylib_artifact = raylib_dep.artifact("raylib");

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

    exe.linkLibrary(raylib_artifact);
    configureLua(exe, b, target);

    return exe;
}

pub fn build(b: *std.Build) void {
    // Standard target options
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Optional custom install directory
    const install_dir = b.option([]const u8, "install-dir", "Custom installation directory") orelse null;

    // ========================================================================
    // Default build (native target)
    // ========================================================================
    const exe = createExe(b, target, optimize);

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

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the application");
    run_step.dependOn(&run_cmd.step);

    // ========================================================================
    // Windows cross-compile build: zig build windows
    // Outputs to D:\Projects\ZigGame\ (accessible as /mnt/d/Projects/ZigGame from WSL)
    // ========================================================================
    const windows_target = b.resolveTargetQuery(.{
        .cpu_arch = .x86_64,
        .os_tag = .windows,
        .abi = .gnu,
    });

    const windows_exe = createExe(b, windows_target, .ReleaseFast);

    // Copy to Windows directory using a system command (since Zig's install system
    // doesn't support absolute paths outside the build prefix)
    const copy_to_windows = b.addSystemCommand(&.{
        "cp",
        "-f",
    });
    copy_to_windows.addFileArg(windows_exe.getEmittedBin());
    copy_to_windows.addArg(windows_output_dir ++ "/zig_game.exe");

    const windows_step = b.step("windows", "Cross-compile for Windows and install to D:\\Projects\\ZigGame\\");
    windows_step.dependOn(&copy_to_windows.step);

    // ========================================================================
    // Test step (native target only)
    // ========================================================================
    const raylib_dep = b.dependency("raylib_zig", .{
        .target = target,
        .optimize = optimize,
    });

    const exe_unit_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "raylib", .module = raylib_dep.module("raylib") },
            },
        }),
    });

    exe_unit_tests.linkLibrary(raylib_dep.artifact("raylib"));
    configureLua(exe_unit_tests, b, target);

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}
