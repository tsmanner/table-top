const std = @import("std");
const Parser = @import("Parser.zig");

test {
    std.testing.refAllDecls(@This());
}
