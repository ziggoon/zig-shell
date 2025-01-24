const std = @import("std");

fn getOsArchFromString(os_arch: []const u8) !std.Target.Cpu.Arch {
    if (std.mem.eql(u8, os_arch, "x86")) {
        return .x86_64;
    } else if (std.mem.eql(u8, os_arch, "arm")) {
        return .aarch64;
    }

    return error.UnsupportedArchitecture;
}

fn getOsTagFromString(os_str: []const u8) !std.Target.Os.Tag {
    if (std.mem.eql(u8, os_str, "windows")) {
        return .windows;
    } else if (std.mem.eql(u8, os_str, "linux")) {
        return .linux;
    } else if (std.mem.eql(u8, os_str, "macos")) {
        return .macos;
    }

    return error.UnsupportedOs;
}

fn getAbiForOs(os_tag: std.Target.Os.Tag) std.Target.Abi {
    return switch (os_tag) {
        .linux => .gnu,
        .windows => .gnu,
        .macos => .none,
        else => .gnu,
    };
}

pub fn build(b: *std.Build) void {
    const os = b.option([]const u8, "os", "target operating system (windows, linux, macos)") orelse "windows";
    const arch = b.option([]const u8, "arch", "cpu architecture (x86 or arm)") orelse "arm";
    const host = b.option([]const u8, "host", "callback ip / fqdn") orelse "127.0.0.1";
    const port = b.option(u16, "port", "port (1-65535 technically but dont be an idiot, just use 443 or sumn)") orelse 443;

    const os_tag = getOsTagFromString(os) catch {
        std.debug.print("Invalid target OS: {s}\n", .{os});
        std.debug.print("Valid options are: windows, linux, macos\n", .{});
        std.process.exit(1);
    };
    const os_arch = getOsArchFromString(arch) catch {
        std.debug.print("Valid options are: x86 or arm\n", .{});
        std.process.exit(1);
    };

    const target = b.standardTargetOptions(.{
        .default_target = .{
            .cpu_arch = os_arch,
            .os_tag = os_tag,
            .abi = getAbiForOs(os_tag),
        },
    });

    const exe = b.addExecutable(.{
        .name = "zig-shell",
        .root_source_file = b.path("src/shell.zig"),
        .target = target,
        .optimize = b.standardOptimizeOption(.{ .preferred_optimize_mode = .ReleaseSmall }),
    });

    const session_info = b.addOptions();
    session_info.addOption([]const u8, "host", host);
    session_info.addOption(u16, "port", port);

    exe.root_module.addOptions("session", session_info);

    if (std.mem.eql(u8, os, "linux")) {
        exe.linkLibC();
    }

    b.installArtifact(exe);

    const run_exe = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run the application");

    run_step.dependOn(&run_exe.step);
}
