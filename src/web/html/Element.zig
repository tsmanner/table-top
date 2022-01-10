const std = @import("std");
const Element = @This();

pub const ElementType = enum {
    // Document metadata
    base,
    head,
    link,
    meta,
    style,
    title,
    // Sectioning root
    body,
    // Content sectioning
    address,
    article,
    aside,
    footer,
    header,
    h1,
    h2,
    h3,
    h4,
    h5,
    h6,
    main,
    nav,
    section,
    // Text content
    blockquote,
    dd,
    div,
    dl,
    dt,
    figcaption,
    figure,
    hr,
    li,
    ol,
    p,
    pre,
    ul,
    // Inline text semantics
    a,
    abbr,
    b,
    bdi,
    bdo,
    br,
    cite,
    code,
    data,
    dfn,
    em,
    i,
    kbd,
    mark,
    q,
    rp,
    rt,
    ruby,
    s,
    samp,
    small,
    span,
    strong,
    sub,
    sup,
    time,
    u,
    @"var",
    wbr,
    // Image and multimedia
    area,
    audio,
    img,
    map,
    track,
    video,
    // Embedded content
    embed,
    iframe,
    object,
    param,
    picture,
    portal,
    source,
    // SVG and MathML
    svg,
    math,
    // Scripting
    canvas,
    noscript,
    script,
    // Demarcating edits
    del,
    ins,
    // Table content
    caption,
    col,
    colgroup,
    table,
    tbody,
    td,
    tfoot,
    th,
    thead,
    tr,
    // Forms
    button,
    datalist,
    fieldset,
    form,
    input,
    label,
    legend,
    meter,
    optgroup,
    option,
    output,
    progress,
    select,
    textarea,
    // Interactive elements
    details,
    dialogue,
    menu,
    summary,
    // Web components
    slot,
    template,
    // Deprecated tags ignored.
};

pub const Attribute = struct {
    key: []const u8,
    value: []const u8,
};

pub const Content = union(enum) {
    text: []const u8,
    element: Element,
};

Type: ElementType,
attributes: []Attribute,  // TODO: HashMap this probably
children: []Content,

// TODO: Implement this as a format function instead, if the specifier is "html" then do this, otherwise print debug info
pub fn toHtml(self: Element, writer: anytype) !void {
    for (self.children) |child| {
        switch (child) {
            .text => |text| try writer.writeAll(text),
            .element => |element| {
                try writer.writeByte('<');
                try writer.writeAll(@tagName(element.Type));
                for (self.attributes) |attribute| {
                    try writer.writeByte(' ');
                    try writer.writeAll(attribute.key);
                    try writer.writeByte('=');
                    try writer.writeAll(attribute.value);
                }
                try writer.writeByte('>');
                try element.toHtml(writer);
                try writer.writeByte('<');
                try writer.writeAll(@tagName(element.Type));
                try writer.writeByte('>');
            ,
        }
    }
}
