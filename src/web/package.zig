const std = @import("std");
pub const html = @import("html/package.zig");
pub const weeb = @import("weeb/package.zig");

test {
    std.testing.refAllDecls(@This());
}
