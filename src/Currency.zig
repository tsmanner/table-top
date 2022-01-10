const std = @import("std");
const Currency = @This();

platinum: u32 = 0,
gold: u32 = 0,
silver: u32 = 0,
copper: u32 = 0,

pub fn init(platinum: u32, gold: u32, silver: u32, copper: u32) Currency {
    return .{
        .platinum = platinum,
        .gold = gold,
        .silver = silver,
        .copper = copper,
    };
}

/// Does not normalize the result
pub fn plus(lhs: Currency, rhs: Currency) Currency {
    return .{
        .platinum = lhs.platinum + rhs.platinum,
        .gold = lhs.gold + rhs.gold,
        .silver = lhs.silver + rhs.silver,
        .copper = lhs.copper + rhs.copper,
    };
}

/// Always normalizes the result
pub fn minus(lhs: Currency, rhs: Currency) ?Currency {
    const lhs_copper = lhs.asCopper();
    const rhs_copper = rhs.asCopper();
    if (lhs_copper >= rhs_copper) return fromCopper(lhs_copper - rhs_copper);
    return null;
}

pub fn normalize(self: Currency) Currency {
    const copper = self.copper;
    const silver = self.silver + copper / 10;
    const gold = self.gold + silver / 10;
    const platinum = self.platinum + gold / 10;
    return .{
        .platinum = platinum,
        .gold = gold % 10,
        .silver = silver % 10,
        .copper = copper % 10,
    };
}

pub fn asCopper(self: Currency) u32 {
    return self.platinum * 10 * 10 * 10 + self.gold * 10 * 10 + self.silver * 10 + self.copper;
}

pub fn fromCopper(copper: u32) Currency {
    return (Currency{ .copper = copper }).normalize();
}

pub fn format(
    self: Currency,
    comptime fmt: []const u8,
    _: std.fmt.FormatOptions,
    writer: anytype,
) !void {
    if (fmt.len == 0) {
        try writer.print("{}p {}g {}s {}c", .{ self.platinum, self.gold, self.silver, self.copper });
    } else if (comptime std.mem.eql(u8, "total", fmt)) {
        try writer.print("{}", .{self.normalize()});
    } else if (comptime std.mem.eql(u8, "copper", fmt)) {
        try writer.print("{}c", .{self.totalCopper()});
    } else {
        @compileLog(fmt);
        @compileError("Currency format must be {}, {total}, or {copper}");
    }
}

test "Currency.plus" {
    try std.testing.expectEqual((Currency{}).plus(Currency{}), Currency{});
    try std.testing.expectEqual(Currency.init(0, 1, 0, 1).plus(Currency.init(1, 0, 1, 0)), Currency.init(1, 1, 1, 1));
    try std.testing.expectEqual(Currency.init(5, 1, 8, 0).plus(Currency.init(1, 0, 1, 0)), Currency.init(6, 1, 9, 0));
}

test "Currency.minus" {
    try std.testing.expectEqual((Currency{}).minus(Currency{}), Currency{});
    try std.testing.expectEqual(Currency.init(0, 1, 0, 1).minus(Currency.init(1, 0, 1, 0)), null);
    try std.testing.expectEqual(Currency.init(5, 1, 8, 0).minus(Currency.init(1, 0, 1, 0)).?, Currency.init(4, 1, 7, 0));
    try std.testing.expectEqual(Currency.init(5, 0, 0, 0).minus(Currency.init(0, 0, 1, 0)).?, Currency.init(4, 9, 9, 0));
}

test "Currency.normalize" {
    for ([_][2]Currency{
        .{ Currency{}, Currency.init(0, 0, 0, 0) },
        .{ Currency.init(0, 0, 0, 10), Currency.init(0, 0, 1, 0) },
        .{ Currency.init(0, 0, 10, 10), Currency.init(0, 1, 1, 0) },
        .{ Currency.init(0, 10, 10, 10), Currency.init(1, 1, 1, 0) },
        .{ Currency.init(10, 10, 10, 10), Currency.init(11, 1, 1, 0) },
    }) |pair| {
        try std.testing.expectEqual(pair[0].normalize(), pair[1]);
    }
}

test "Currency.format" {
    var buf: [1024]u8 = undefined;
    for ([_]std.meta.Tuple(&[_]type{ Currency, []const u8 }){
        .{ Currency{}, "0p 0g 0s 0c" },
        .{ Currency.init(0, 0, 0, 10), "0p 0g 0s 10c" },
        .{ Currency.init(0, 0, 10, 10), "0p 0g 10s 10c" },
        .{ Currency.init(0, 10, 10, 10), "0p 10g 10s 10c" },
        .{ Currency.init(10, 10, 10, 10), "10p 10g 10s 10c" },
    }) |pair| {
        try std.testing.expectEqualStrings(try std.fmt.bufPrint(&buf, "{}", .{pair[0]}), pair[1]);
    }
    for ([_]std.meta.Tuple(&[_]type{ Currency, []const u8 }){
        .{ Currency{}, "0p 0g 0s 0c" },
        .{ Currency.init(0, 0, 0, 10), "0p 0g 1s 0c" },
        .{ Currency.init(0, 0, 10, 10), "0p 1g 1s 0c" },
        .{ Currency.init(0, 10, 10, 10), "1p 1g 1s 0c" },
        .{ Currency.init(10, 10, 10, 10), "11p 1g 1s 0c" },
    }) |pair| {
        try std.testing.expectEqualStrings(try std.fmt.bufPrint(&buf, "{total}", .{pair[0]}), pair[1]);
    }
}
