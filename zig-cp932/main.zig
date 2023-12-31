const std = @import("std");
const cp932 = @import("cp932.zig");

pub fn main() anyerror!void {
    const in_jis = [_]u8{
        130, 187, 130, 204, 137, 212, 130, 209, 130, 231, 130, 201, 130, 173,
        130, 191, 130, 195, 130, 175, 130, 240,
    };
    var decoder = cp932.decoder;
    for (in_jis) |byte|
        std.debug.print("{u}", .{try decoder.input(byte) orelse continue});
}
