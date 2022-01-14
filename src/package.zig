const std = @import("std");

pub const util = @import("util/package.zig").init(@This());
pub const dnd = @import("dnd/package.zig").init(@This());
pub const web = @import("web/package.zig").init(@This());

test {
    std.testing.refAllDecls(@This());
}
