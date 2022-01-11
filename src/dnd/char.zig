//! Backend Data Model
//!     Character
//!         Proficiency
//!         Abilities (score, bonuses)
//!             Strength
//!             Dexterity
//!             Constitution
//!             Intelligence
//!             Wisdom
//!             Charisma
//!     Modifiers
//!         Spells and Effects
//!         Equipment
//!             Armor
//!             Weapons
//! Frontend
//!     Character
//!         Proficiency ?
//!         u32 Checks (adv, dadv)
//!             Strength
//!             Dexterity
//!             Constitution
//!             Intelligence
//!             Wisdom
//!             Charisma
//!         u32 Saves (adv, dadv)
//!             Strength
//!             Dexterity
//!             Constitution
//!             Intelligence
//!             Wisdom
//!             Charisma
//!         Skills (modifier)
//!             Athletics
//!             ...
//!         Equipment
//!             Armor
//!             Weapon(s)
//!             Footwear
//!             Jewelery
//!             Rod / Wand / Etc
//!             Misc
//!         Armor Class
//!             - 8 + Dexterity Modifier
//!             - Armor
//!             - Class Feature (e.g. Unarmored Defense)
//!             - Spell Effect (e.g. Mage Armor)
//!         Spell Save DC

const std = @import("std");
const Currency = @import("Currency.zig");
const armors = @import("armors.zig");
const Armor = armors.Armor;
const Shield = armors.Shield;
const weapons = @import("weapons.zig");
const Weapon = weapons.Weapon;
const tools = @import("tools.zig");
const Tool = tools.Tool;

const Element = @import("root").web.html.Element;

pub const CharacterLevel = struct {
    str: u32 = 0,
    dex: u32 = 0,
    con: u32 = 0,
    int: u32 = 0,
    wis: u32 = 0,
    cha: u32 = 0,
};

fn modify(value: u32, mod: i32) u32 {
    const result = @intCast(u32, @intCast(i32, value) + mod);
    if (result < 0) return 0;
    return result;
}

fn abilityModifier(score: u32) i32 {
    return @divFloor(@intCast(i32, score) - 10, 2);
}

test "abilityModifier" {
    try std.testing.expectEqual(abilityModifier(1), -5);
    try std.testing.expectEqual(abilityModifier(2), -4);
    try std.testing.expectEqual(abilityModifier(3), -4);
    try std.testing.expectEqual(abilityModifier(4), -3);
    try std.testing.expectEqual(abilityModifier(5), -3);
    try std.testing.expectEqual(abilityModifier(6), -2);
    try std.testing.expectEqual(abilityModifier(7), -2);
    try std.testing.expectEqual(abilityModifier(8), -1);
    try std.testing.expectEqual(abilityModifier(9), -1);
    try std.testing.expectEqual(abilityModifier(10), 0);
    try std.testing.expectEqual(abilityModifier(11), 0);
    try std.testing.expectEqual(abilityModifier(12), 1);
    try std.testing.expectEqual(abilityModifier(13), 1);
    try std.testing.expectEqual(abilityModifier(14), 2);
    try std.testing.expectEqual(abilityModifier(15), 2);
    try std.testing.expectEqual(abilityModifier(16), 3);
    try std.testing.expectEqual(abilityModifier(17), 3);
    try std.testing.expectEqual(abilityModifier(18), 4);
    try std.testing.expectEqual(abilityModifier(19), 4);
    try std.testing.expectEqual(abilityModifier(20), 5);
}

pub const Character = struct {
    name: []const u8,
    str: u32,
    dex: u32,
    con: u32,
    int: u32,
    wis: u32,
    cha: u32,
    levels: []const CharacterLevel = &[_]CharacterLevel{},
    armor: ?Armor = null,
    shield: ?Shield = null,
    // weapons: []const Weapon = &[_]Weapon{},

    pub fn dexScore(self: Character) u32 {
        var score: u32 = self.dex;
        for (self.levels) |level| {
            score = std.math.min(20, score + level.dex);
        }
        return score;
    }

    pub fn ac(self: Character) u32 {
        var value: u32 = undefined;
        if (self.armor) |armor| {
            if (armor.ac.max_dex) |max_dex| {
                value = modify(armor.ac.base, std.math.min(abilityModifier(self.dexScore()), max_dex));
            } else {
                value = armor.ac.base;
            }
        } else {
            value = modify(10, abilityModifier(self.dexScore()));
        }
        if (self.shield) |s| {
            value += s.ac;
        }
        return value;
    }
};

test "Character.ac" {
    const char = Character{
        .name = "foo",
        .str = 10,
        .dex = 20,
        .con = 10,
        .int = 16,
        .wis = 12,
        .cha = 10,
        .armor = armors.studded_leather,
        .shield = armors.shield,
    };
    try std.testing.expectEqual(char.ac(), 19);
}

pub fn charToHtml(char: *const Character, allocator: std.mem.Allocator) !Element {
    var root = Element.init(null, .div, allocator);
    _ = try (try root.addElement(.h1)).addText(char.name);
    var ability_table = try root.addElement(.table);
    var thead = try ability_table.addElement(.thead);
    _ = try (try thead.addElement(.td)).addText("Str");
    _ = try (try thead.addElement(.td)).addText("Dex");
    _ = try (try thead.addElement(.td)).addText("Con");
    _ = try (try thead.addElement(.td)).addText("Int");
    _ = try (try thead.addElement(.td)).addText("Wis");
    _ = try (try thead.addElement(.td)).addText("Cha");
    var tr = try ability_table.addElement(.tr);
    _ = try (try tr.addElement(.td)).addText(try std.fmt.allocPrintZ(allocator, "{}", .{char.str}));
    _ = try (try tr.addElement(.td)).addText(try std.fmt.allocPrintZ(allocator, "{}", .{char.dex}));
    _ = try (try tr.addElement(.td)).addText(try std.fmt.allocPrintZ(allocator, "{}", .{char.con}));
    _ = try (try tr.addElement(.td)).addText(try std.fmt.allocPrintZ(allocator, "{}", .{char.int}));
    _ = try (try tr.addElement(.td)).addText(try std.fmt.allocPrintZ(allocator, "{}", .{char.wis}));
    _ = try (try tr.addElement(.td)).addText(try std.fmt.allocPrintZ(allocator, "{}", .{char.cha}));
    return root;
}
