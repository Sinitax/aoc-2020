const std = @import("std");
const aoc = @import("aoc");

fn part1(allocator: *std.mem.Allocator, input: []u8, args: [][]u8) !void {
    var answer: u32 = 0;

    std.debug.print("{}\n", .{answer});
}

fn part2(allocator: *std.mem.Allocator, input: []u8, args: [][]u8) !void {
    var answer: u32 = 0;

    std.debug.print("{}\n", .{answer});
}

pub const main = aoc.gen_main(part1, part2);
