const std = @import("std");
const Builder = std.build.Builder;
const Pkg = std.build.Pkg;

fn addPackageTests(
    builder: *Builder,
    target: std.zig.CrossTarget,
    mode: std.builtin.Mode,
    package: Pkg,
) !void {
    const tests = builder.addTestExe(
        try std.fmt.allocPrint(builder.allocator, "{s}-tests", .{package.name}),
        package.path.path,
    );
    tests.setTarget(target);
    tests.setBuildMode(mode);
    if (package.dependencies) |deps| {
        for (deps) |dep| {
            tests.addPackage(dep);
        }
    }

    const test_cmd = tests.run();
    test_cmd.step.dependOn(builder.getInstallStep());
    if (builder.args) |args| {
        test_cmd.addArgs(args);
    }

    const test_step = builder.step(
        try std.fmt.allocPrint(builder.allocator, "test-{s}", .{package.name}),
        try std.fmt.allocPrint(builder.allocator, "Test '{s}' package.", .{package.name}),
    );
    test_step.dependOn(&test_cmd.step);
}

pub fn build(builder: *Builder) !void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = builder.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = builder.standardReleaseOptions();

    const util = Pkg{ .name = "util", .path = .{ .path = "src/util/package.zig" } };
    const web = Pkg{ .name = "web", .path = .{ .path = "src/web/package.zig" }, .dependencies = &[_]Pkg{util} };
    const dnd = Pkg{ .name = "dnd", .path = .{ .path = "src/dnd/package.zig" }, .dependencies = &[_]Pkg{ util, web } };

    const packages = [_]Pkg{
        util,
        web,
        dnd,
    };

    //
    // main executable
    //

    const exe = builder.addExecutable("main", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.addPackage(dnd);
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(builder.getInstallStep());
    if (builder.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = builder.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    //
    // tests
    //

    for (packages) |package| {
        try addPackageTests(builder, target, mode, package);
    }
}
