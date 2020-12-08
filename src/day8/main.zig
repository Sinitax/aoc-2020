const std = @import("std");
const aoc = @import("aoc");
const Console = @import("console8").Console;

fn runTillRepeat(console: *Console, instlist: *std.ArrayList(u64), swapon: ?u64) !void {
    while (try console.parseNext()) |*inst| {
        // std.debug.print("{:<5}: {} {}\n", .{ console.instructptr, inst.opcode, inst.argval });
        if (std.mem.indexOfScalar(u64, instlist.items, console.instructptr) != null) {
            return;
        }
        if (swapon != null and swapon.? == console.instructptr) {
            inst.opfunc = switch (inst.opfunc) {
                Console.jumpInstruction => Console.nopInstruction,
                Console.nopInstruction => Console.jumpInstruction,
                else => unreachable,
            };
        }
        try instlist.append(console.instructptr);
        try console.exec(inst);
    }
}

fn part1(allocator: *std.mem.Allocator, input: []u8, args: [][]u8) !void {
    var console = try Console.init(input, allocator);
    defer console.deinit();

    var instlist = std.ArrayList(u64).init(allocator);
    defer instlist.deinit();

    try runTillRepeat(&console, &instlist, null);
    std.debug.print("{}\n", .{console.accumulator});
}

fn part2(allocator: *std.mem.Allocator, input: []u8, args: [][]u8) !void {
    var console = try Console.init(input, allocator);
    defer console.deinit();

    var instlist = std.ArrayList(u64).init(allocator);
    defer instlist.deinit();

    try runTillRepeat(&console, &instlist, null);

    for (instlist.items) |inst| {
        if (std.mem.eql(u8, "acc"[0..3], console.instlist[inst][0..3]))
            continue;

        var sim_seen = std.ArrayList(u64).init(allocator);
        defer sim_seen.deinit();

        console.reset();
        //std.debug.print("Swapping instruction: {:<5}: {}\n", .{ inst, console.instlist[inst] });
        runTillRepeat(&console, &sim_seen, inst) catch {};
        if (console.jumpAddr == console.instlist.len or console.instructptr == console.instlist.len) {
            std.debug.print("{}\n", .{console.accumulator});
            break;
        }
    }
}

pub const main = aoc.gen_main(part1, part2);
