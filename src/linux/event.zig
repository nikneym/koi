const std = @import("std");
const builtin = @import("builtin");
const linux = std.os.linux;
const EPOLL = linux.EPOLL;

// the code is directly from std.os.linux.epoll_event
pub const Event = switch (builtin.zig_backend) {
    // stage1 crashes with the align(4) field so we have this workaround
    .stage1 => switch (builtin.cpu.arch) {
        .x86_64 => packed struct {
            events: u32,
            data: linux.epoll_data,

            pub usingnamespace Mixin(Event);
        },
        else => extern struct {
            events: u32,
            data: linux.epoll_data,

            pub usingnamespace Mixin(Event);
        },
    },
    else => extern struct {
        events: u32,
        data: linux.epoll_data align(switch (builtin.cpu.arch) {
            .x86_64 => 4,
            else => @alignOf(linux.epoll_data),
        }),

        pub usingnamespace Mixin(Event);
    },
};

fn Mixin(comptime Self: type) type {
    return struct {
        /// get the underlying identifier of the event.
        pub fn token(self: Self) usize {
            return self.data.ptr;
        }

        /// check if any error is associated with underlying fd in current event.
        pub fn isError(self: Self) bool {
            return self.events & EPOLL.ERR != 0;
        }

        // "time goes by so slowly"
        pub fn isHungUp(self: Self) bool {
            return self.events & (EPOLL.HUP | EPOLL.RDHUP) != 0;
        }

        /// check if reading is possible in current event.
        pub fn isReadable(self: Self) bool {
            return self.events & EPOLL.IN != 0;
        }

        /// check if writing is possible in current event.
        pub fn isWritable(self: Self) bool {
            return self.events & EPOLL.OUT != 0;
        }
    };
}
