const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const app_mod = b.createModule(.{
        .root_source_file = b.path("src/App.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Bring Mach in and wire it into your app module.
    const mach_dep = b.dependency("mach", .{
        .target = target,
        .optimize = optimize,
    });
    app_mod.addImport("mach", mach_dep.module("mach"));

    // Mach creates the executable.
    const exe = @import("mach").addExecutable(mach_dep.builder, .{
        .name = "zong",
        .app = app_mod,
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(exe);

    // `zig build run`
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| run_cmd.addArgs(args);
    b.step("run", "Run Zong").dependOn(&run_cmd.step);

    // `zig build test`
    const app_tests = b.addTest(.{ .root_module = app_mod });
    const run_tests = b.addRunArtifact(app_tests);
    b.step("test", "Run tests").dependOn(&run_tests.step);

    // `zig build run-smoke`
    const smoke = b.addRunArtifact(exe);
    smoke.addArgs(&.{ "--smoke-frames", "600", "--max-dt-ms", "33" });
    b.step("run-smoke", "Run 600-frames smoke test").dependOn(&smoke.step);
}
