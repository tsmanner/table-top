const std = @import("std");
const Currency = @import("Currency.zig");
const RollType = @import("dice.zig").RollType;

pub const ArmorType = enum {
    @"Light",
    @"Medium",
    @"Heavy",

    pub fn jsonStringify(
        self: ArmorType,
        _: std.json.StringifyOptions,
        out_stream: anytype,
    ) !void {
        try out_stream.writeByte('\"');
        try out_stream.writeAll(@tagName(self));
        try out_stream.writeByte('\"');
    }
};

pub const Armor = struct {
    @"type": ArmorType,
    cost: Currency,
    ac: struct { base: u32, max_dex: ?u32 },
    strength: ?u32 = null,
    stealth: RollType = .Normal,
    weight: f32, // Pounds
};

pub const Shield = struct {
    cost: Currency,
    ac: u32,
    weight: f32, // Pounds
};
