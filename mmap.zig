const std = @import("std");

pub const MMAP = struct {
    const Self = @This();
    const Error = std.os.MMapError || std.os.OpenError || error{FstatError};
    map: []align(std.mem.page_size) const u8,
    pub fn init(filename: []const u8) Error!Self {
        const fd = try std.os.open(filename, std.os.O.RDONLY, 0);
        defer std.os.close(fd);
        const stat: std.os.Stat = try std.os.fstat(fd);
        const map = try std.os.mmap(null, @intCast(stat.size), std.os.PROT.READ, std.os.MAP.PRIVATE, fd, 0);
        return .{ .map = map };
    }
    pub fn deinit(self: Self) void {
        std.os.munmap(self.map);
    }
};
