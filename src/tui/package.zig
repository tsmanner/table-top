const std = @import("std");
const c = @cImport(@cInclude("notcurses/notcurses.h"));

pub const Notcurses = struct {
    pub const Handle = ?*c.notcurses;
    pub const Plane = ?*c.ncplane;

    pub const Options = extern struct {
        pub const LogLevel = enum(c_uint) {
            silent, // print nothing once fullscreen service begins
            panic, // default. print diagnostics before we crash/exit
            fatal, // we're hanging around, but we've had a horrible fault
            @"error", // we can't keep doing this, but we can do other things
            warning, // you probably don't want what's happening to happen
            info, // "standard information"
            verbose, // "detailed information"
            debug, // this is honestly a bit much
            trace, // there's probably a better way to do what you want
        };

        termtype: ?*const u8 = null,
        loglevel: LogLevel = .silent,
        margin_t: u32 = 0,
        margin_r: u32 = 0,
        margin_b: u32 = 0,
        margin_l: u32 = 0,
        flags: u64 = c.NCOPTION_SUPPRESS_BANNERS,

        pub fn asHandle(self: *const Options) *const c.notcurses_options {
            return @ptrCast(*const c.notcurses_options, self);
        }
    };

    handle: Handle = null,
    std_plane: Plane = null,

    pub fn init(options: Options) Notcurses {
        var nc = Notcurses{
            .handle = c.notcurses_init(options.asHandle(), null),
        };
        nc.std_plane = c.notcurses_stdplane(nc.handle);
        return nc;
    }

    pub fn deinit(self: *Notcurses) void {
        checkRc(self, c.notcurses_stop(self.handle)) catch @panic("Failed to stop notcurses!");
    }
};

fn checkRc(nc: *Notcurses, rc: c_int) !void {
    if (rc != 0) {
        nc.deinit();
        std.debug.print("expected rc=0, found rc={}\n", .{rc});
        return error.TestExpectedEqual;
    }
}

test {
    var nc = Notcurses.init(.{});

    const prog = c.ncprogbar_create(nc.std_plane, null);

    var pct: f64 = 0.0;
    while (pct < 1.0) {
        std.time.sleep(100000000);
        try checkRc(&nc, c.ncprogbar_set_progress(prog, pct));
        try checkRc(&nc, c.ncpile_render(nc.std_plane));
        try checkRc(&nc, c.notcurses_refresh(nc.handle, null, null));
        pct += 0.01;
    }
    nc.deinit();
}
