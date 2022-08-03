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

fn notcurses(
    builder: *Builder,
    target: std.zig.CrossTarget,
    mode: std.builtin.Mode,
) !void {
    std.ChildProcess.init()

    const lib = builder.addStaticLibrary("notcurses", null);
    lib.setTarget(target);
    lib.setBuildMode(mode);
    lib.addCSourceFiles(
        &.{
            "../notcurses/src/lib/automaton.c",
            "../notcurses/src/lib/banner.c",
            "../notcurses/src/lib/blit.c",
            "../notcurses/src/lib/debug.c",
            "../notcurses/src/lib/direct.c",
            "../notcurses/src/lib/fade.c",
            "../notcurses/src/lib/fd.c",
            "../notcurses/src/lib/fill.c",
            "../notcurses/src/lib/gpm.c",
            "../notcurses/src/lib/in.c",
            "../notcurses/src/lib/kitty.c",
            "../notcurses/src/lib/layout.c",
            "../notcurses/src/lib/linux.c",
            "../notcurses/src/lib/menu.c",
            "../notcurses/src/lib/metric.c",
            "../notcurses/src/lib/mice.c",
            "../notcurses/src/lib/notcurses.c",
            "../notcurses/src/lib/plot.c",
            "../notcurses/src/lib/progbar.c",
            "../notcurses/src/lib/reader.c",
            "../notcurses/src/lib/reel.c",
            "../notcurses/src/lib/render.c",
            "../notcurses/src/lib/selector.c",
            "../notcurses/src/lib/sixel.c",
            "../notcurses/src/lib/sprite.c",
            "../notcurses/src/lib/stats.c",
            "../notcurses/src/lib/tabbed.c",
            "../notcurses/src/lib/termdesc.c",
            "../notcurses/src/lib/tree.c",
            "../notcurses/src/lib/unixsig.c",
            "../notcurses/src/lib/util.c",
            "../notcurses/src/lib/visual.c",
            "../notcurses/src/lib/windows.c",
        },
        &.{},
    );
    lib.addIncludeDir("../notcurses/src/lib");
    lib.linkLibC();
    lib.install();
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

    try notcurses(builder, target, mode);

    const util = Pkg{ .name = "util", .path = .{ .path = "src/util/package.zig" } };
    const web = Pkg{ .name = "web", .path = .{ .path = "src/web/package.zig" }, .dependencies = &[_]Pkg{util} };
    const tui = Pkg{ .name = "tui", .path = .{ .path = "src/tui/package.zig" }, .dependencies = &[_]Pkg{util} };
    const dnd = Pkg{ .name = "dnd", .path = .{ .path = "src/dnd/package.zig" }, .dependencies = &[_]Pkg{ util, web } };

    const packages = [_]Pkg{
        util,
        web,
        tui,
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
