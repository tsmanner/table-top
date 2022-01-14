const std = @import("std");
const tt = @import("root");
const Parser = @This();

const State = enum {
    text,
    spec,
};

const Token = enum {
    text,
    start_spec,
    end_spec,
};

const TransitionCombinator = tt.util.enums.Combinator(State, Token);
const Transition = TransitionCombinator.Cross;
const transition = TransitionCombinator.cross;

state: State = .text,

pub fn parse(self: *Parser, tokens: []const Token) !void {
    for (tokens) |token| {
        switch (transition(self.state, token)) {
            transition(.text, .text) => {
                std.info.log("concatenating normal text", .{});
                std.debug.print("concatenating normal text\n", .{});
            },
            transition(.text, .start_spec) => {
                std.info.log("starting a spec", .{});
                std.debug.print("starting a spec\n", .{});
                self.state = .spec;
            },
            transition(.spec, .text) => {
                std.info.log("concatenating spec text", .{});
                std.debug.print("concatenating spec text\n", .{});
            },
            transition(.spec, .end_spec) => {
                std.info.log("ending a spec", .{});
                std.debug.print("ending a spec\n", .{});
                self.state = .text;
            },
            else => {
                std.err.log("invalid transition {s} -> {s}", .{ @tagName(self.state), @tagName(token) });
                return error.InvalidTransition;
            },
        }
    }
}

test "parse" {
    var parser = Parser{};
    std.debug.print("\ntesting parser\n", .{});
    try parser.parse(&[_]Token{
        .text,
        .start_spec,
        .text,
        .end_spec,
        .text,
        .text,
        .text,
    });
}

const Tokenizer = struct {
    pub fn parse(iterator: anytype) !void {
        while (iterator.next()) |c| {
            std.debug.print("{c}", .{c});
        }
        std.debug.print("\n", .{});
    }
};

test "Tokenizer" {
    const filename = "tests/foo.weeb";
    @compileLog(@typeInfo(tt).Struct.fields.len);
    try Tokenizer.parse(&tt.util.SliceIterator(u8).init(filename));
    // std.testing.expectEqualStrings(filename, p.filename);
}
