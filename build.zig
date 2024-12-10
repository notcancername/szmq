// SPDX-License-Identifier: Unlicense
const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const szmq = b.addModule("szmq", .{
        .root_source_file = b.path("szmq.zig"),
        .target = target,
        .optimize = optimize,
    });
    const zlzmq = b.dependency("zlzmq", .{}).module("zlzmq");
    szmq.addImport("zmq", zlzmq);
}
