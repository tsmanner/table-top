const std = @import("std");

fn Module(comptime root: anytype) type {
    return struct {
        pub const char = @import("char.zig").Module(root);
        pub const Character = char.Character;
        pub const CharacterLevel = char.CharacterLevel;
        pub const Currency = @import("Currency.zig");
        pub const armors = @import("armors.zig");
        pub const Armor = armors.Armor;
        pub const Shield = armors.Shield;
        pub const weapons = @import("weapons.zig");
        pub const Weapon = weapons.Weapon;
        pub const tools = @import("tools.zig");
        pub const Tool = tools.Tool;
    };
}

test {
    std.testing.refAllDecls(@This());
}
