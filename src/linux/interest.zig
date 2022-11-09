const std = @import("std");
const linux = std.os.linux;
const EPOLL = linux.EPOLL;

pub const Interest = enum(u32) {
    read = EPOLL.IN | EPOLL.ET,
    write = EPOLL.OUT | EPOLL.ET,
    duplex = EPOLL.IN | EPOLL.OUT | EPOLL.ET,
};
