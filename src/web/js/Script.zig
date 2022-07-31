const std = @import("std");
const Script = @This();

filename: []const u8,

pub fn init(comptime f: []const u8) Script {
    return .{
        .filename = f,
    };
}

pub fn inlineHtml(comptime self: Script) []const u8 {
    return "<script>" ++ @embedFile(self.filename) ++ "</script>";
}

pub fn referenceHtml(self: Script, allocator: anytype) ![]const u8 {
    return std.fmt.allocPrint(allocator, "<script src=\"/{s}\"></script>", .{self.filename});
}

test {
    const script = comptime init("test/foo.js");
    try std.testing.expectEqualStrings(script.inlineHtml(),
        \\<script>function foo() {
        \\  console.log("hello, world!")
        \\}
        \\
        \\foo()
        \\</script>
    );
}

test {
    const script = init("test/foo.js");
    const html = try script.referenceHtml(std.testing.allocator);
    defer std.testing.allocator.free(html);
    try std.testing.expectEqualStrings(html, "<script src=\"/test/foo.js\"></script>");
}
