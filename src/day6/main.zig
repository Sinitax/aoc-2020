const std = @import("std");
const aoc = @import("aoc");

fn part1(allocator: *std.mem.Allocator, input: []u8, args: [][]u8) !void {
    var entryit = std.mem.split(input, "\n\n");
    var answer: u32 = 0;
    while (entryit.next()) |group| {
        var seen = [_]u1{0} ** 256;
        for (group) |c| {
            if (c == ' ' or c == '\n') continue;
            answer += @boolToInt(seen[c] == 0);
            seen[c] = 1;
        }
    }
    std.debug.print("{}\n", .{answer});
}

fn part2(allocator: *std.mem.Allocator, input: []u8, args: [][]u8) !void {
    var entryit = std.mem.split(input, "\n\n");
    var answer: u32 = 0;
    while (entryit.next()) |group| {
        var count = [_]u16{0} ** 256;
        var members: u16 = 0;
        var memberit = std.mem.tokenize(group, "\n ");
        while (memberit.next()) |member| : (members += 1) {
            for (member) |c| count[c] += 1;
        }
        for (count) |v| answer += @boolToInt(v == members);
    }
    std.debug.print("{}\n", .{answer});
}

pub const main = aoc.gen_main(part1, part2);
