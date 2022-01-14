fn SliceIterator(comptime T: type) type {
    return struct {
        const Self = @This();
        slice: []const T,
        i: usize = 0,
        len: usize,

        pub fn init(ts: []const T) Self {
            return .{
                .slice = ts,
                .i = 0,
                .len = ts.len,
            };
        }

        pub fn next(self: *Self) ?T {
            if (self.i < self.slice.len) {
                const i = self.i;
                self.i += 1;
                return self.slice[i];
            } else {
                return null;
            }
        }

        pub fn previous(self: *Self) ?T {
            if (self.i > 0) {
                self.i -= 1;
                return self.slice[self.i];
            } else {
                return null;
            }
        }
    };
}
