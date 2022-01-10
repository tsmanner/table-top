const std = @import("std");
const Currency = @import("Currency.zig");

pub const ToolType = enum {
    @"Alchemist's supplies",
    @"Brewer's supplies",
    @"Calligrapher's supplies",
    @"Carpenter's tools",
    @"Cartographer's tools",
    @"Cobbler's tools",
    @"Cook's utensils",
    @"Glassblower's tools",
    @"Jeweler's tools",
    @"Leatherworker's tools",
    @"Mason's tools",
    @"Painter's supplies",
    @"Potter's tools",
    @"Smith's tools",
    @"Tinker's tools",
    @"Weaver's tools",
    @"Woodcarver's tools",
    @"Disguise kit",
    @"Forgery kit",
    @"Dice set",
    @"Dragonchess set",
    @"Playing card set",
    @"Three-Dragon Ante set",
    @"Herbalism kit",
    @"Bagpipes",
    @"Drum",
    @"Dulcimer",
    @"Flute",
    @"Lute",
    @"Lyre",
    @"Horn",
    @"Pan flute",
    @"Shawm",
    @"Viol",
    @"Navigator's tools",
    @"Poisoner's kit",
    @"Thieves' tools",

    pub fn jsonStringify(
        self: ToolType,
        _: std.json.StringifyOptions,
        out_stream: anytype,
    ) !void {
        try out_stream.writeByte('\"');
        try out_stream.writeAll(@tagName(self));
        try out_stream.writeByte('\"');
    }
};

pub const Tool = struct {
    @"type": ToolType,
    cost: Currency,
    // TODO
};
