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
        }),
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    // Test step for user
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}
