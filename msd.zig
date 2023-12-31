const std = @import("std");
const Md5 = std.crypto.hash.Md5;

pub fn decryptInPlace(keyPrefix: []const u8, blocks: [][32]u8) void {
    var numBuffer: [24]u8 = undefined;
    var md5Buffer: [16]u8 = undefined;
    var md5String: [32]u8 = undefined;
    for (blocks, 0..) |*block, i| {
        var fullMd5 = Md5.init(.{});
        fullMd5.update(keyPrefix);
        fullMd5.update(usizeToString(i, &numBuffer));
        fullMd5.final(&md5Buffer);
        bytes16toHex(md5Buffer, @ptrCast(&md5String));
        for (block, md5String) |*b, c| b.* ^= c;
    }
}

fn usizeToString(n: usize, buffer: *[24]u8) []const u8 {
    if (n == 0) return &.{'0'};
    var x = n;
    var i: usize = buffer.len - 1;
    var b: []u8 = buffer;
    while (x > 0) : ({
        i -= 1;
        x /= 10;
    }) b[i] = @as(u8, @intCast(x % 10)) + '0';
    return b[i + 1 ..];
}

fn bytes16toHex(in: [16]u8, out: *[16][2]u8) void {
    const table: [16]u8 = "0123456789abcdef".*;
    for (in, out) |i, *o| o.* = .{ table[i >> 4], table[i & 0xF] };
}
