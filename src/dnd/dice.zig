//! Die representation, roll parser, and json serializer

const std = @import("std");

pub const RollType = enum {
    Normal,
    Advantage,
    Disadvantage,

    pub fn jsonStringify(
        self: RollType,
        _: std.json.StringifyOptions,
        out_stream: anytype,
    ) !void {
        try out_stream.writeByte('\"');
        try out_stream.writeAll(@tagName(self));
        try out_stream.writeByte('\"');
    }
};

pub const Die = struct {
    d: i32,
};

pub const d4 = Die{ .d = 4 };
pub const d6 = Die{ .d = 6 };
pub const d8 = Die{ .d = 8 };
pub const d10 = Die{ .d = 10 };
pub const d12 = Die{ .d = 12 };
pub const d20 = Die{ .d = 20 };

const Unary = struct {
    const Operation = enum {
        // Arithmetic
        negate,
        // Logical
        logical_not,

        pub fn jsonStringify(self: Operation, _: std.json.StringifyOptions, out_stream: anytype) @TypeOf(out_stream).Error!void {
            try out_stream.writeByte('"');
            try out_stream.writeAll(@tagName(self));
            try out_stream.writeByte('"');
        }
    };

    op: Operation,
    operand: *Value,

    pub fn get(self: Unary, random: std.rand.Random) Value.Result {
        return switch (self.op) {
            .negate => .{ .Integer = -self.operand.get(random).Integer },
            .logical_not => .{ .Bool = !self.operand.get(random).Bool },
        };
    }

    /// For operators, frees all operand pointers
    pub fn deinit(self: *Unary, allocator: std.mem.Allocator) void {
        switch (self.*.operand.*) {
            .Constant, .Bool, .Die => {},
            .Unary => |*operand| operand.*.deinit(allocator),
            .Binary => |*operand| operand.*.deinit(allocator),
        }
        allocator.destroy(self.*.operand);
    }
};

// TODO: Implement N-way binary ops as a List (ArrayList or SinglyLinkedList) of *Value
const Binary = struct {
    const Operation = enum {
        // Arithmetic
        add,
        subtract,
        multiply,
        divide,
        minimum,
        maximum,
        // Relational
        equal,
        less,
        less_equal,
        greater,
        greater_equal,
        // Logical
        logical_and,
        logical_or,

        pub fn jsonStringify(self: Operation, _: std.json.StringifyOptions, out_stream: anytype) @TypeOf(out_stream).Error!void {
            try out_stream.writeByte('"');
            try out_stream.writeAll(@tagName(self));
            try out_stream.writeByte('"');
        }
    };

    op: Operation,
    lhs: *Value,
    rhs: *Value,

    pub fn get(self: Binary, random: std.rand.Random) Value.Result {
        return switch (self.op) {
            // Arithmetic
            .add => .{ .Integer = self.lhs.get(random).Integer + self.rhs.get(random).Integer },
            .subtract => .{ .Integer = self.lhs.get(random).Integer - self.rhs.get(random).Integer },
            .multiply => .{ .Integer = self.lhs.get(random).Integer * self.rhs.get(random).Integer },
            .divide => .{ .Integer = divide(self.lhs.get(random).Integer, self.rhs.get(random).Integer) },
            .minimum => .{ .Integer = @minimum(self.lhs.get(random).Integer, self.rhs.get(random).Integer) },
            .maximum => .{ .Integer = @maximum(self.lhs.get(random).Integer, self.rhs.get(random).Integer) },
            // Relational
            .equal => .{ .Bool = self.lhs.get(random).Integer == self.rhs.get(random).Integer },
            .less => .{ .Bool = self.lhs.get(random).Integer < self.rhs.get(random).Integer },
            .less_equal => .{ .Bool = self.lhs.get(random).Integer <= self.rhs.get(random).Integer },
            .greater => .{ .Bool = self.lhs.get(random).Integer > self.rhs.get(random).Integer },
            .greater_equal => .{ .Bool = self.lhs.get(random).Integer >= self.rhs.get(random).Integer },
            // Logical
            .logical_and => .{ .Bool = self.lhs.get(random).Bool and self.rhs.get(random).Bool },
            .logical_or => .{ .Bool = self.lhs.get(random).Bool or self.rhs.get(random).Bool },
        };
    }

    /// D&D division always rounds up
    fn divide(lhs: i32, rhs: i32) i32 {
        if (@rem(lhs, rhs) == 0) {
            return @divFloor(lhs, rhs);
        }
        return @divFloor(lhs, rhs) + 1;
    }

    /// Deinit and free both operands
    pub fn deinit(self: *Binary, allocator: std.mem.Allocator) void {
        switch (self.*.lhs.*) {
            .Constant, .Bool, .Die => {},
            .Unary => |*lhs| lhs.*.deinit(allocator),
            .Binary => |*lhs| lhs.*.deinit(allocator),
        }
        switch (self.*.rhs.*) {
            .Constant, .Bool, .Die => {},
            .Unary => |*rhs| rhs.*.deinit(allocator),
            .Binary => |*rhs| rhs.*.deinit(allocator),
        }
        allocator.destroy(self.*.lhs);
        allocator.destroy(self.*.rhs);
    }
};

test "Binary to json to Binary" {
    var out_buf: [1024]u8 = undefined;
    var slice_stream = std.io.fixedBufferStream(&out_buf);
    const out = slice_stream.writer();
    var lhs = Value{ .Constant = 10 };
    var rhs = Value{ .Constant = 5 };
    const b1 = Binary{
        .op = .add,
        .lhs = &lhs,
        .rhs = &rhs,
    };
    try std.json.stringify(b1, .{}, out);
    try std.testing.expect(std.mem.eql(u8, "{\"op\":\"add\",\"lhs\":10,\"rhs\":5}", slice_stream.getWritten()));

    const options = std.json.ParseOptions{ .allocator = std.testing.allocator };
    const b2 = try std.json.parse(Binary, &std.json.TokenStream.init(slice_stream.getWritten()), options);
    defer std.json.parseFree(Binary, b2, options);
    try std.testing.expectEqual(b1.op, b2.op);
    try std.testing.expectEqual(b1.lhs.*, b2.lhs.*);
    try std.testing.expectEqual(b1.rhs.*, b2.rhs.*);
}

const Value = union(enum) {
    const Result = union(enum) {
        Integer: i32,
        Bool: bool,
    };

    Constant: i32,
    Bool: bool,
    Die: Die,
    Unary: Unary,
    Binary: Binary,

    pub fn get(self: Value, random: std.rand.Random) Result {
        return switch (self) {
            .Constant => |c| .{ .Integer = c },
            .Bool => |b| .{ .Bool = b },
            .Die => |die| .{ .Integer = random.intRangeAtMost(i32, 1, die.d) },
            .Unary => |op| op.get(random),
            .Binary => |op| op.get(random),
        };
    }

    /// For operators, frees all operand pointers.  Must be passed the same allocator that was used to allocate the Value tree.
    pub fn deinit(self: *Value, allocator: std.mem.Allocator) void {
        switch (self.*) {
            .Constant, .Bool, .Die => {},
            .Unary => |*op| op.*.deinit(allocator),
            .Binary => |*op| op.*.deinit(allocator),
        }
    }
};

test "get Constant" {
    var prng = std.rand.DefaultPrng.init(0);
    var rand = prng.random();
    const value = Value{ .Constant = 5 };
    try std.testing.expectEqual(value.get(rand).Integer, 5);
}

test "Binary Operation from json" {
    var j =
        \\{
        \\  "op": "multiply",
        \\  "lhs": 10,
        \\  "rhs": 5
        \\}
    ;
    var ten = Value{ .Constant = 10 };
    var five = Value{ .Constant = 5 };
    const expected = Binary{ .op = .multiply, .lhs = &ten, .rhs = &five };
    const options = std.json.ParseOptions{ .allocator = std.testing.allocator };
    const actual = try std.json.parse(Binary, &std.json.TokenStream.init(j), options);
    defer std.json.parseFree(Binary, actual, options);
    try std.testing.expectEqual(expected.op, actual.op);
    try std.testing.expectEqual(actual.lhs.*.Constant, 10);
    try std.testing.expectEqual(actual.rhs.*.Constant, 5);
    try std.testing.expectEqual(expected.lhs.*.Constant, actual.lhs.*.Constant);
    try std.testing.expectEqual(expected.rhs.*.Constant, actual.rhs.*.Constant);
}

test "Die from json" {
    var j =
        \\{
        \\  "d": 10
        \\}
    ;
    try std.testing.expectEqual(try std.json.parse(Die, &std.json.TokenStream.init(j), .{}), d10);
}

test "Die to json" {
    var out_buf: [9]u8 = undefined;
    var slice_stream = std.io.fixedBufferStream(&out_buf);
    const out = slice_stream.writer();
    try std.json.stringify(d10, .{}, out);
    try std.testing.expect(std.mem.eql(u8, "{\"d\":10}", slice_stream.getWritten()));
}

test "Dice from json" {
    var j =
        \\[
        \\  { "d": 10 },
        \\  { "d": 20 },
        \\  { "d":  6 }
        \\]
    ;
    const options = std.json.ParseOptions{ .allocator = std.testing.allocator };
    const dice = try std.json.parse([]Die, &std.json.TokenStream.init(j), options);
    defer std.json.parseFree([]Die, dice, options);
    try std.testing.expectEqual(dice[0], d10);
    try std.testing.expectEqual(dice[1], d20);
    try std.testing.expectEqual(dice[2], d6);
}

test "Dice to json" {
    var out_buf: [100]u8 = undefined;
    var slice_stream = std.io.fixedBufferStream(&out_buf);
    const out = slice_stream.writer();
    try std.json.stringify([_]Die{
        d10,
        d20,
        d6,
    }, .{}, out);
    try std.testing.expect(std.mem.eql(u8, "[{\"d\":10},{\"d\":20},{\"d\":6}]", slice_stream.getWritten()));
}

// TODO: Implement a roll parser that can take user-inputs and render them to operations on Dice.
// Format `XdY +- C` at minimum
// Ideally, any `XdY` term could be part of an operation, just like any constant C.
// Additionally, a compare operator should be supported and to render hit/miss equations
//   e.g. `1d20 + 5 >= 16` should be parsable and yield true or false, indicating that an attach hit or missed.
// Numeric operators:
//   +  plus, addition
//   -  minus, subtraction
//   *  times, multiplication
//   /  over, division
//   v  minimum (e.g. disadvantage `1d20 v 1d20`)
//   ^  maximum (e.g. advantage `1d20 ^ 1d20`)
// Compares / Relational operators
//   <   less
//   <=  less or equal
//   >   greater
//   >=  greater or equal
//   ==  equal
// Logical operators
//   &&  logical and
//   ||  logical or
// See: std.json for an example of a parser that should work well for this.
//
// The below code is just some random experiments, it's likely to be completely rewritten.

const Token = union(enum) {
    Nothing: struct {},
    Number: i32,
    Operation: OperationEnum,
    OpenParen: struct {},
    CloseParen: struct {},

    const OperationEnum = enum(u8) {
        add = '+',
        subtract = '-',
        multiply = '*',
        divide = '/',
        min = 'v',
        max = '^',
        less = '<',
        greater = '>',
        equal = '=',
        dice = 'd',
    };
};

pub fn TokenStream(comptime Stream: type) type {
    return struct {
        const Self = @This();

        reader: Stream.Reader,
        token: ?Token = Token{ .Nothing = .{} },

        pub fn init(stream: *Stream) Self {
            return .{ .reader = stream.reader() };
        }

        pub fn next(self: *Self) ?Token {
            while (true) {
                const c = self.*.reader.readByte() catch return self.replaceToken(null);
                switch (c) {
                    ' ' => continue,
                    '0'...'9' => {
                        switch (self.*.token.?) {
                            .Number => self.*.token.?.Number = self.*.token.?.Number * 10 + c - '0',
                            .Nothing => _ = self.replaceToken(Token{ .Number = c - '0' }),
                            else => return self.replaceToken(Token{ .Number = c - '0' }),
                        }
                    },
                    '+', '-', '*', '/', 'v', '^', '<', '>', '=', 'd' => {
                        switch (self.*.token.?) {
                            .Nothing => unreachable,
                            else => return self.replaceToken(Token{ .Operation = @intToEnum(Token.OperationEnum, c) }),
                        }
                    },
                    '(' => {
                        switch (self.*.token.?) {
                            .Nothing => _ = self.replaceToken(Token{ .OpenParen = .{} }),
                            else => return self.replaceToken(Token{ .OpenParen = .{} }),
                        }
                    },
                    ')' => {
                        switch (self.*.token.?) {
                            .Nothing => _ = self.replaceToken(Token{ .CloseParen = .{} }),
                            else => return self.replaceToken(Token{ .CloseParen = .{} }),
                        }
                    },
                    else => unreachable,
                }
            }
        }

        fn replaceToken(self: *Self, new_token: ?Token) ?Token {
            const old_token = self.*.token;
            self.*.token = new_token;
            return old_token;
        }
    };
}

pub fn tokenStream(stream: anytype) TokenStream(@TypeOf(stream.*)) {
    return TokenStream(@TypeOf(stream.*)).init(stream);
}

test "tokenStream" {
    var stream = std.io.fixedBufferStream("11 + 1 + 1d8");
    var tokens = tokenStream(&stream);
    try std.testing.expectEqual(tokens.next().?, Token{ .Number = 11 });
    try std.testing.expectEqual(tokens.next().?, Token{ .Operation = .add });
    try std.testing.expectEqual(tokens.next().?, Token{ .Number = 1 });
    try std.testing.expectEqual(tokens.next().?, Token{ .Operation = .add });
    try std.testing.expectEqual(tokens.next().?, Token{ .Number = 1 });
    try std.testing.expectEqual(tokens.next().?, Token{ .Operation = .dice });
    try std.testing.expectEqual(tokens.next().?, Token{ .Number = 8 });
    try std.testing.expectEqual(tokens.next(), null);
}

fn Tree(comptime T: type) type {
    return struct {
        const Self = @This();

        pub const Node = struct {
            children: std.ArrayList(*Node),
            data: T,

            pub const Data = T;

            pub fn init(allocator: std.mem.Allocator, data: T) Node {
                return .{
                    .children = std.ArrayList(*Node).init(allocator),
                    .data = data,
                };
            }

            pub fn addChild(node: *Node, child: *Node) void {
                node.children.append(child);
            }
        };

        root: ?*Node = null,
    };
}

pub fn parse(
    allocator: std.mem.Allocator,
    tokens: anytype,
) !?Value {
    _ = allocator; // TODO: Remove once it's referenced
    var value: ?Value = null;
    std.debug.print("\n", .{});
    while (tokens.*.next()) |token| {
        std.debug.print("{s}\n", .{token});
        switch (token) {
            .Nothing => unreachable, // TODO
            .Number => unreachable, // TODO
            .Operation => unreachable, // TODO
            .OpenParen => unreachable, // TODO: this code needs an explicit error set to handle the recursion: value = try parse(allocator, tokens),
            .CloseParen => return value,
        }
    }
    return value;
}

test "parse" {
    return error.SkipZigTest; // TODO: remove when working on the parser
    // var prng = std.rand.DefaultPrng.init(0);
    // const rand = prng.random();
    // var stream = std.io.fixedBufferStream("11 + 1 + 1d8");
    // var tokens = tokenStream(&stream);

    // var v = try parse(std.testing.allocator, &tokens);
    // if (v) |*value| {
    //     defer value.deinit(std.testing.allocator);
    //     const result = value.get(rand).Integer;

    //     try std.testing.expect(13 <= result);
    //     try std.testing.expect(result <= 20);
    // }
}
