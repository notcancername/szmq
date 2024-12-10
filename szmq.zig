const std = @import("std");
const zmq = @import("zlzmq");

pub fn Actor(comptime State: type) type {
    return struct {
        pair: *zmq.Socket,
        socket: *zmq.Socket,
        thread: std.Thread,
        arena: std.heap.ArenaAllocator,
        state: State,
    };
}

pub const multipart = struct {
    pub const Message = []zmq.Message;

    pub fn recv(s: *zmq.Socket, ally: std.mem.Allocator) !Message {
        const log = std.log.scoped(.szmq_recv_multipart);
        log.debug("enter {} {}", .{ s, ally.ptr });
        var fm: std.ArrayListUnmanaged(zmq.Message) = .{};
        errdefer fm.deinit(ally);
        errdefer for (fm.items) |*ms| {
            log.debug("deinit \"{s}\"", .{std.fmt.fmtSliceEscapeLower(ms.data())});
            ms.deinit();
        };

        var more = true;
        while (more) {
            var m = try fm.addOne(ally);
            errdefer _ = fm.pop();

            m.* = zmq.Message.init();
            errdefer m.deinit();

            try m.recv(s, .{});
            log.debug("\"{s}\" {}", .{ std.fmt.fmtSliceEscapeLower(m.data()), m.hasMore() });
            more = m.hasMore();
        }
        return try fm.toOwnedSlice(ally);
    }

    pub fn deinit(m: *Message, ally: std.mem.Allocator) void {
        const log = std.log.scoped(.szmq_deinit_multipart);
        for (m) |*ms| {
            log.debug("\"{s}\"", .{std.fmt.fmtSliceEscapeLower(ms.data())});
            ms.deinit();
        }
        ally.free(m);
    }
};
