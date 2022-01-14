const root = @import("root");

pub const M2 = struct {
    baz: i32,
    pub fn init(m1: root.module1.M1) M2 {
        return .{ .baz = m1.bar };
    }
};

test {
    const m1 = root.module1.M1{ .bar = 5 };
    const m2 = M2.init(m1);
    std.testing.expectEqual(m1.bar, m2.baz);
}
