const std = @import("std");

pub fn ErrorsFrom(comptime fs: anytype) type {
    switch (@typeInfo(@TypeOf(fs))) {
        .Struct => |s| {
            if (!s.is_tuple) {
                @panic("ErrorsFrom argument must be a Tuple");
            }
        },
        else => {
            @panic("ErrorsFrom argument must be a Tuple");
        },
    }
    comptime var Errors = error{};
    inline for (fs) |f| {
        const t_info = @typeInfo(@TypeOf(f));
        switch (t_info) {
            .BoundFn, .Fn => |f_info| {
                if (f_info.return_type) |ret| {
                    Errors = Errors || @typeInfo(ret).ErrorUnion.error_set;
                }
            },
            else => {},
        }
    }
    return Errors;
}
