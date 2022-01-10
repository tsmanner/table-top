const std = @import("std");

const Declaration = std.builtin.TypeInfo.Declaration;
const EnumField = std.builtin.TypeInfo.EnumField;
const Enum = std.builtin.TypeInfo.Enum;

pub fn EnumCat(comptime enums: []const type) type {
    const num_fields = blk: {
        var sum: usize = 0;
        inline for (enums) |T| {
            sum += std.meta.fields(T).len;
        }
        break :blk sum;
    };
    var fields: [num_fields]EnumField = undefined;
    var decls = [_]Declaration{};

    var i: usize = 0;
    inline for (enums) |T| {
        inline for (std.meta.fields(T)) |field| {
            fields[i] = .{
                .name = field.name,
                .value = i,
            };
            i += 1;
        }
    }
    return @Type(.{ .Enum = .{
        .layout = .Auto,
        .tag_type = std.math.IntFittingRange(0, num_fields),
        .fields = &fields,
        .decls = &decls,
        .is_exhaustive = true,
    } });
}
