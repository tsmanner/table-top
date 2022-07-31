const std = @import("std");
const dnd = @import("dnd");
const web = @import("web");

pub fn main() !void {
    const turminder_xuss = dnd.Character{
        .name = "Turminder Xuss",
        .str = 10,
        .dex = 16,
        .con = 10,
        .int = 16,
        .wis = 12,
        .cha = 10,
        .levels = &[_]dnd.CharacterLevel{
            .{ .dex = 2 },
            .{ .dex = 1 },
            .{ .dex = 1 },
        },
        .armor = dnd.armors.studded_leather,
        .shield = dnd.armors.shield,
    };
    var out_buf: [1024]u8 = undefined;
    var slice_stream = std.io.fixedBufferStream(&out_buf);
    try std.json.stringify(turminder_xuss, std.json.StringifyOptions{}, slice_stream.writer());
    std.log.info("{s}", .{slice_stream.getWritten()});
    std.log.info("{}", .{turminder_xuss.ac()});
    std.log.info("{}", .{turminder_xuss.dexScore()});

    var html = try dnd.char.charToHtml(&turminder_xuss, std.testing.allocator);
    defer html.deinit();
    std.log.info("{html}", .{html});

    // std.log.info("{s}", .{dnd.char.sql.Table(dnd.Character).create()});
}
