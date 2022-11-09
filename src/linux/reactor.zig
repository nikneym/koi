const std = @import("std");
const mem = std.mem;
const os = std.os;
const linux = std.os.linux;
const EPOLL = linux.EPOLL;

const Interest = @import("interest.zig").Interest;

pub const Reactor = struct {
    fd: os.fd_t,

    /// Create a new Reactor object.
    pub fn init() !Reactor {
        var flags: u32 = EPOLL.CLOEXEC;

        return Reactor{
            .fd = try os.epoll_create1(flags),
        };
    }

    /// Remove the Reactor object.
    pub fn deinit(self: Reactor) void {
        os.close(self.fd);
    }

    /// Add a file descriptor to the watch list.
    pub fn insert(self: Reactor, fd: os.fd_t, identifier: usize, interest: Interest) !void {
        const event = &linux.epoll_event{
            .events = @enumToInt(interest),
            .data = .{ .ptr = identifier },
        };

        return os.epoll_ctl(self.fd, EPOLL.CTL_ADD, fd, event);
    }

    /// Update a file descriptor in the watch list.
    pub fn update(self: Reactor, fd: os.fd_t, identifier: usize, interest: Interest) !void {
        const event = &linux.epoll_event{
            .events = @enumToInt(interest),
            .data = .{ .ptr = identifier },
        };

        return os.epoll_ctl(self.fd, EPOLL.CTL_MOD, fd, event) catch |e| switch (e) {
            error.FileDescriptorNotRegistered => os.epoll_ctl(self.fd, EPOLL.CTL_ADD, fd, event),
            else => e,
        };
    }

    /// Remove a file descriptor from the watch list.
    pub fn remove(self: Reactor, fd: os.fd_t) !void {
        return os.epoll_ctl(self.fd, EPOLL.CTL_DEL, fd, null);
    }

    /// Poll for possible events.
    pub fn poll(self: Reactor, events: anytype, timeout: ?u64) void {
        // thanks InKryption#4791
        const buffer = mem.bytesAsSlice(linux.epoll_event, mem.asBytes(&events.buffer));

        const num_events = os.epoll_wait(self.fd, buffer, if (timeout) |ms| @intCast(i32, ms) else -1);
        events.len = num_events;
    }
};
