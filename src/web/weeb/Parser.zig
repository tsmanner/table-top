const std = @import("std");
const util = @import("util");
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

const TransitionCombinator = util.enums.Combinator(State, Token);
const Transition = TransitionCombinator.Cross;
const transition = TransitionCombinator.cross;

state: State = .text,

pub fn parse(self: *Parser, tokens: []const Token) !void {
    for (tokens) |token| {
        switch (transition(self.state, token)) {
            transition(.text, .text) => {
                std.log.info("concatenating normal text", .{});
                std.debug.print("concatenating normal text\n", .{});
            },
            transition(.text, .start_spec) => {
                std.log.info("starting a spec", .{});
                std.debug.print("starting a spec\n", .{});
                self.state = .spec;
            },
            transition(.spec, .text) => {
                std.log.info("concatenating spec text", .{});
                std.debug.print("concatenating spec text\n", .{});
            },
            transition(.spec, .end_spec) => {
                std.log.info("ending a spec", .{});
                std.debug.print("ending a spec\n", .{});
                self.state = .text;
            },
            else => {
                std.log.err("invalid transition {s} -> {s}", .{ @tagName(self.state), @tagName(token) });
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
    try Tokenizer.parse(&util.SliceIterator(u8).init(filename));
    // std.testing.expectEqualStrings(filename, p.filename);
}
