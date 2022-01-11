const std = @import("std");
const Type = @import("ElementType.zig").Enum;
const Element = @This();

// TODO: There are some common types of attribute that aren't necessarily strings (e.g. class),
// this should probably become a union of string, integer, and list of string.
const AttributeMap = std.StringHashMap([]const u8);

pub const Child = union(enum) {
    text: []const u8,
    element: Element,
};

const Children = std.TailQueue(Child);

// TODO: Should element_type be a union enum instead of plain member?
element_type: Type,
allocator: std.mem.Allocator,
attributes: AttributeMap,
parent: ?*Element,
children: Children = .{},

pub fn init(
    parent: ?*Element,
    element_type: Type,
    allocator: std.mem.Allocator,
) Element {
    return .{
        .parent = parent,
        .element_type = element_type,
        .allocator = allocator,
        .attributes = AttributeMap.init(allocator),
    };
}

pub fn deinit(self: *Element) void {
    self.attributes.deinit();
    while (self.children.popFirst()) |child| {
        switch (child.data) {
            .element => child.data.element.deinit(),
            else => {},
        }
        self.allocator.destroy(child);
    }
}

pub fn addElement(self: *Element, child: Type) !*Element {
    var node = try self.allocator.create(Children.Node);
    self.children.append(node);
    node.data = .{ .element = Element.init(self, child, self.allocator) };
    return &node.data.element;
}

pub fn addText(self: *Element, child: []const u8) ![]const u8 {
    var node = try self.allocator.create(Children.Node);
    self.children.append(node);
    node.data = .{ .text = child };
    return node.data.text;
}

/// Returns the nesting depth of non-inline elements of self
fn getBlockDepth(self: *const Element) u8 {
    if (self.parent) |parent| {
        if (self.element_type.isInline()) {
            return parent.getBlockDepth();
        } else {
            return parent.getBlockDepth() + 1;
        }
    } else {
        return 0;
    }
}

fn formatIndentation(
    tab_count: usize,
    tab_width: usize,
    writer: anytype,
) !void {
    var i: usize = tab_count * tab_width;
    while (i > 0) : (i -= 1) {
        try writer.writeByte(' ');
    }
}

fn formatAttributes(
    self: *const Element,
    writer: anytype,
) !void {
    var iter = self.attributes.iterator();
    while (iter.next()) |attribute| {
        try writer.print(" {s}={s}", .{ attribute.key_ptr.*, attribute.value_ptr.* });
    }
}

fn formatChildren(
    self: *const Element,
    comptime fmt: []const u8,
    options: std.fmt.FormatOptions,
    writer: anytype,
) !void {
    var iter = self.children.first;
    while (iter) |node| : (iter = node.next) {
        switch (node.data) {
            .text => |t| {
                try writer.print("{s}", .{t});
            },
            .element => |e| {
                try e.format(fmt, options, writer);
            },
        }
    }
}

pub fn format(
    self: *const Element,
    comptime fmt: []const u8,
    options: std.fmt.FormatOptions,
    writer: anytype,
) @TypeOf(writer).Error!void {
    _ = options;
    const name = @tagName(self.element_type);
    if (fmt.len == 0) {
        try writer.writeByte('{');
        try writer.print("Element tag={s}", .{name});
        try self.formatAttributes(writer);
        try writer.writeAll(" children=");
        try self.formatChildren(fmt, options, writer);
        try writer.writeByte('}');
    } else if (comptime std.mem.eql(u8, "html", fmt)) {
        try writer.print("<{s}", .{name});
        try self.formatAttributes(writer);
        try writer.writeByte('>');
        if (!self.element_type.isInline()) {
            try writer.writeByte('\n');
            try Element.formatIndentation(self.getBlockDepth() + 1, options.width orelse 2, writer);
        }
        try self.formatChildren(fmt, options, writer);
        if (!self.element_type.isInline()) {
            try writer.writeByte('\n');
            try Element.formatIndentation(self.getBlockDepth(), options.width orelse 2, writer);
        }
        try writer.print("</{s}>", .{name});
    } else {
        @compileLog(fmt);
        @compileError("Element format must be {} or {html}");
    }
}

test "Element formatting as html" {
    var buf = [_]u8{0} ** 1024;

    var p1 = Element.init(null, .p, std.testing.allocator);
    defer p1.deinit();
    var p2 = try p1.addElement(.p);
    var a = try p2.addElement(.a);
    try a.attributes.put("class", "bold");
    _ = try a.addText("hello, ");
    _ = try p1.addText("world!");
    try std.testing.expectEqualStrings(
        \\<p>
        \\  <p>
        \\    <a class=bold>hello, </a>
        \\  </p>world!
        \\</p>
    , try std.fmt.bufPrint(&buf, "{html}", .{p1}));
}
