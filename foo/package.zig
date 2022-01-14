pub const module1 = @import("module1/package.zig");
pub const module2 = @import("module2/package.zig");

test {
    std.testing.refAllDecls(@This());
}
