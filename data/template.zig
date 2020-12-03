const std = @import("std");
const aoc = @import("aoc");

const Entry = u16;

fn free_entries(allocator: *std.mem.Allocator, entries: std.ArrayList(Entry)) void {
    entries.deinit();
}

fn parse(allocator: *std.mem.Allocator, input: []u8) !std.ArrayList(Entry) {
    var entries = std.ArrayList(int).init(allocator);
    errdefer free_entries(allocator, entries);

    // ...

    return entries;
}

fn part1(allocator: *std.mem.Allocator, input: []u8, args: [][]u8) !void {
    const entries = try parse(allocator, input);
    defer free_entries(allocator, entries);

    var answer: u32 = 0;

    std.debug.print("{}\n", .{answer});
}

fn part2(allocator: *std.mem.Allocator, input: []u8, args: [][]u8) !void {
    const entries = try parse(allocator, input);
    defer free_entries(allocator, entries);

    var answer: u32 = 0;

    std.debug.print("{}\n", .{answer});
}

pub const main = aoc.gen_main(part1, part2);
