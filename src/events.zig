const std = @import("std");
const builtin = @import("builtin");

pub const Event = @import("main.zig").Event;

// it's easy to implement this on your own
// the Reactor will only make use of buffer, capacity and length
pub fn Events(comptime capacity: usize) type {
    return struct {
        const Self = @This();

        buffer: [capacity]Event = undefined,
        capacity: usize = capacity,
        len: usize = 0,

        pub fn init() Self {
            return Self{};
        }

        pub fn reset(self: *Self) void {
            self.buffer = undefined;
            self.len = 0;
        }

        fn slice(self: Self) []const Event {
            return self.buffer[0..self.len];
        }

        pub fn next(self: *Self) ?Event {
            if (self.len == 0) return null;

            const pos = self.len - 1;
            const item = self.slice()[pos];

            self.len -= 1;

            return item;
        }
    };
}
