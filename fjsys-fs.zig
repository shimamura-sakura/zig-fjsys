const std = @import("std");

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
    const infilename = argv.next() orelse {
        _ = try stderr.write("usage: inputfile [outputdir]\n");
        return 1;
    };
    const outdirname = argv.next() orelse ".";
    // 2. open input and output
    const infile = try std.fs.cwd().openFile(infilename, .{});
    defer infile.close();
    var outdir = try std.fs.cwd().makeOpenPath(outdirname, .{});
    defer outdir.close();
    const reader = infile.reader();
    // 3. read header
    const Header = extern struct {
        magic: [8]u8,
        data_offset: u32 align(1),
        name_length: u32 align(1),
        entry_count: u32 align(1),
        _: [64]u8,
    };
    var header: Header = undefined;
    try reader.readNoEof(std.mem.asBytes(&header));
    const MAGIC_1 = "FJSYS" ++ [_]u8{ 0, 0, 0 };
    const MAGIC_2 = "SM2MPX10";
    const MAGIC_3 = "MGCFILE" ++ [_]u8{0};
    if (!std.mem.eql(u8, &header.magic, MAGIC_1) and
        !std.mem.eql(u8, &header.magic, MAGIC_2) and
        !std.mem.eql(u8, &header.magic, MAGIC_3)) return 2;
    // 4. read entry and names
    const headRest = try alloc.alloc(u8, header.data_offset - @sizeOf(Header));
    defer alloc.free(headRest);
    try reader.readNoEof(headRest);
    const Entry = extern struct {
        name_offset: u32 align(1),
        file_length: u32 align(1),
        data_offset: u64 align(1),
    };
    const entries = @as([*]const Entry, @ptrCast(headRest))[0..header.entry_count];
    const nametbl = headRest[@sizeOf(Entry) * header.entry_count ..];
    // 5. write output files
    for (entries) |e| {
        const outfile = try outdir.createFileZ(@ptrCast(nametbl[e.name_offset..]), .{});
        defer outfile.close();
        _ = try infile.copyRangeAll(e.data_offset, outfile, 0, e.file_length);
    }
    return 0;
}
