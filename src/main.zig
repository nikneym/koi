const std = @import("std");
const builtin = @import("builtin");

pub const Reactor = switch (builtin.os.tag) {
    .linux => @import("linux/reactor.zig").Reactor,

    else => @compileError("unsupported OS"),
};

pub const Interest = switch (builtin.os.tag) {
    .linux => @import("linux/interest.zig").Interest,

    else => @compileError("unsupported OS"),
};

pub const Event = switch (builtin.os.tag) {
    .linux => @import("linux/event.zig").Event,

    else => @compileError("unsupported OS"),
};

// this is platform independent
pub const Events = @import("events.zig").Events;

test "watch events of TCP Listener and a Connection" {
    // some tokens in order to identify events
    const Server = 0;
    const Client = 1;

    // create the reactor
    var reactor = try Reactor.init();
    defer reactor.deinit();

    // create our listener
    const net = std.net;
    const address = try net.Address.parseIp("127.0.0.1", 65535);

    var listener = net.StreamServer.init(.{ .reuse_address = true });
    defer listener.deinit();

    // start listening for incoming connections
    try listener.listen(address);

    // push listener to the reactor
    // watching for read is enough for accepting connections
    try reactor.insert(listener.sockfd.?, Server, .read);

    // create our client
    var stream = try net.tcpConnectToAddress(address);
    defer stream.close();

    // incoming events will be stored here
    var events = Events(128).init();

    // poll for new events
    reactor.poll(&events, null);

    while (events.next()) |event| switch (event.token()) {
        Server => {
            try std.testing.expect(!event.isError());
            try std.testing.expect(!event.isWritable());
            try std.testing.expect(event.isReadable());

            // accepted the connection that created earlier
            var connection = try listener.accept();

            // watch for write events on this socket
            try reactor.insert(connection.stream.handle, Client, .write);

            // do not watch for server events anymore
            try reactor.remove(listener.sockfd.?);
        },

        else => unreachable,
    };

    events.reset();

    reactor.poll(&events, null);

    // we'll expect our client to be writable
    while (events.next()) |event| switch (event.token()) {
        Client => {
            try std.testing.expect(!event.isError());
            try std.testing.expect(!event.isReadable());
            try std.testing.expect(event.isWritable());
        },

        else => unreachable,
    };
}
