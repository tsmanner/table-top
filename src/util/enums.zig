const std = @import("std");

pub fn Combinator(comptime Left: type, comptime Right: type) type {
    return struct {
        const Self = @This();

        /// Take two enum types and yield a new enum that contains the cross product of them.
        /// Enum values are ignored to guarantee there are no collisions.
        /// Names are directly concatenated, left ++ right.
        pub const Cross = blk: {
            const lefts = std.meta.fields(Left);
            const rights = std.meta.fields(Right);
            var enumFields: [lefts.len * rights.len]std.builtin.TypeInfo.EnumField = undefined;
            var decls = [_]std.builtin.TypeInfo.Declaration{};
            var i: usize = 0;
            inline for (lefts) |left, li| {
                if (left.value != li) {
                    @compileLog(Left, left.name, left.value);
                    @compileError("Enums must not override ordinal values");
                }
                inline for (rights) |right, ri| {
                    if (right.value != ri) {
                        @compileLog(Right, right.name, right.value);
                        @compileError("Enums must not override ordinal values");
                    }
                    enumFields[i] = .{
                        .name = left.name ++ right.name,
                        .value = i,
                    };
                    i += 1;
                }
            }
            break :blk @Type(.{
                .Enum = .{
                    .layout = .Auto,
                    .tag_type = std.math.IntFittingRange(0, i - 1),
                    .fields = &enumFields,
                    .decls = &decls,
                    .is_exhaustive = true,
                },
            });
        };

        /// Yield the cross-product value of two comptime-known enum values
        pub fn cross(left: Left, right: Right) Self.Cross {
            return @intToEnum(Self.Cross, @enumToInt(left) * std.meta.fields(Right).len + @enumToInt(right));
        }
    };
}

test "Cross" {
    const E1 = enum(u3) { x, y };
    const E2 = enum { a, b };
    const E1E2 = Combinator(E1, E2);
    const names = std.meta.fieldNames(E1E2.Cross);
    try std.testing.expectEqualStrings("xa", names[0]);
    try std.testing.expectEqualStrings("xb", names[1]);
    try std.testing.expectEqualStrings("ya", names[2]);
    try std.testing.expectEqualStrings("yb", names[3]);
    try std.testing.expectEqual(@enumToInt(E1E2.cross(.x, .b)), @enumToInt(E1E2.Cross.xb));
}
