const std = @import("std");
const aoc = @import("aoc");

const Range = struct { min: u16, max: u16 };

const row_count = 128;
const col_count = 8;

fn binarySearch(code: []const u8, max: u16, comptime front_id: u8, comptime back_id: u8) !u16 {
    var possible = Range{ .min = 0, .max = max - 1 };
    for (code) |b| {
        _ = switch (b) {
            front_id => possible.max = @floatToInt(u16, //
                std.math.floor(@intToFloat(f32, possible.min + possible.max) / 2.0)),
            back_id => possible.min = @floatToInt(u16, //
                std.math.ceil(@intToFloat(f32, possible.min + possible.max) / 2.0)),
            else => return aoc.Error.InvalidInput,
        };
    }
    if (possible.min != possible.max)
        return aoc.Error.InvalidInput;
    return possible.min;
}

fn part1(allocator: *std.mem.Allocator, input: []u8, args: [][]u8) !void {
    var lineit = std.mem.tokenize(input, "\n");
    var answer: ?u32 = null;
    while (lineit.next()) |line| {
        const row = try binarySearch(line[0..7], row_count, 'F', 'B');
        const col = try binarySearch(line[7..10], col_count, 'L', 'R');
        const id = row * 8 + col;
        if (answer == null or id > answer.?)
            answer = id;
    }
    std.debug.print("{}\n", .{answer.?});
}

fn part2(allocator: *std.mem.Allocator, input: []u8, args: [][]u8) !void {
    var lineit = std.mem.tokenize(input, "\n");
    var seats = [_]u1{0} ** (row_count * col_count);
    while (lineit.next()) |line| {
        const row = try binarySearch(line[0..7], row_count, 'F', 'B');
        const col = try binarySearch(line[7..10], col_count, 'L', 'R');
        const id = row * 8 + col;
        seats[id] = 1;
    }

    for (seats) |b, i| {
        if ((i == 0 or seats[i - 1] == 1) and
            (i == seats.len - 1 or seats[i + 1] == 1) and seats[i] == 0)
        {
            std.debug.print("{}\n", .{i});
            break;
        }
    }
}

pub const main = aoc.gen_main(part1, part2);
