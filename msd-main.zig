const std = @import("std");
const msd = @import("msd.zig");
const jis = @import("zig-cp932/cp932.zig");

pub fn panic(_: []const u8, _: ?*std.builtin.StackTrace, _: ?usize) noreturn {
    std.os.exit(255);
}

pub fn main() u8 {
    return real_main() catch return 255;
}

fn real_main() anyerror!u8 {
    const alloc = std.heap.page_allocator;
    const stderr = std.io.getStdErr().writer();
    // 1. get parameter
    var argv = try std.process.argsWithAllocator(alloc);
    defer argv.deinit();
    _ = argv.next();
    const keystring = argv.next();
    const infilename = argv.next();
    const outfilename = argv.next() orelse {
        _ = try stderr.write("usage: keystring inputfile outfile\n");
        return 1;
    };
    // 2. open input file
    const file = try std.fs.cwd().openFileZ(infilename.?, .{});
    defer file.close();
    const size: usize = @intCast(try file.getEndPos());
    const data = try alloc.alloc(u8, size + 32);
    defer alloc.free(data);
    _ = try file.readAll(data);
    const blks = @as([*][32]u8, @ptrCast(data))[0 .. data.len / 32];
    // 3. convert keystring
    const keybuffer = try alloc.alloc(u8, keystring.?.len * 2);
    defer alloc.free(keybuffer);
    var iter = (try std.unicode.Utf8View.init(keystring.?)).iterator();
    var keylen: usize = 0;
    while (iter.nextCodepoint()) |u| {
        if (u > 0xFFFF) return 2;
        switch (jis.encode(@intCast(u)) catch return 3) {
            .single => |c| {
                keybuffer[keylen] = c;
                keylen += 1;
            },
            .double => |b| {
                keybuffer[keylen + 0] = b[0];
                keybuffer[keylen + 1] = b[1];
                keylen += 2;
            },
        }
    }
    // 4. decrypt and write out
    msd.decryptInPlace(keybuffer[0..keylen], blks);
    try std.fs.cwd().writeFile(outfilename, data[0..size]);
    return 0;
}
