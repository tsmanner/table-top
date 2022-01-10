const std = @import("std");
const Currency = @import("Currency.zig");

pub const WeaponType = enum {
    Simple,
    Martial,
    Improvised,
    Lance,
    Net,

    pub fn jsonStringify(
        self: WeaponType,
        _: std.json.StringifyOptions,
        out_stream: anytype,
    ) !void {
        try out_stream.writeByte('\"');
        try out_stream.writeAll(@tagName(self));
        try out_stream.writeByte('\"');
    }
};

pub const AttackType = enum {
    Melee,
    Ranged,
};

pub const Weapon = struct {
    @"type": WeaponType,
    cost: Currency,
    attack_type: AttackType,
    // TODO
};
