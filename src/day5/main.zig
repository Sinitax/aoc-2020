const std = @import("std");
const aoc = @import("aoc");

const row_count = 128;
const col_count = 8;

// Input is coded in a way that we can do an implicit binary search by replacing
// identifiers for the lower half with "0" and for the upper halb with "1"
// See commit <f1b717029cf3262c1fa2760124af258924d668da> for actual binary search

fn code2Id(input: []const u8) !u32 {
    var value: u32 = 0;
    for (input) |c|
        value = value * 2 + @boolToInt(c == 'B' or c == 'R');
    return value;
}

fn part1(allocator: *std.mem.Allocator, input: []u8, args: [][]u8) !void {
    var lineit = std.mem.tokenize(input, "\n");
    var answer: u32 = 0;
    while (lineit.next()) |line| {
        const id = try code2Id(line[0..10]);
        answer = std.math.max(answer, id);
    }
    std.debug.print("{}\n", .{answer});
}

fn part2(allocator: *std.mem.Allocator, input: []u8, args: [][]u8) !void {
    var lineit = std.mem.tokenize(input, "\n");
    var seats = [_]u1{0} ** (row_count * col_count);
    var min: u32 = std.math.inf_u32;
    while (lineit.next()) |line| {
        const id = try code2Id(line);
        min = std.math.min(min, id);
        seats[id] = 1;
    }

    for (seats[min..]) |b, i| {
        if (seats[min + i] == 0) {
            std.debug.print("{}\n", .{min + i});
            break;
        }
    }
}

pub const main = aoc.gen_main(part1, part2);
