const std = @import("std");
const aoc = @import("aoc");

const preamble_size = 25;

fn preambleHasSum(preamble: []u64, target: u64) bool {
    for (preamble) |v1| {
        for (preamble) |v2| {
            if (v1 != v2 and v1 + v2 == target)
                return true;
        }
    }
    return false;
}

fn getInvalid(allocator: *std.mem.Allocator, input: []u8) !u64 {
    var preamble = std.ArrayList(u64).init(allocator);
    defer preamble.deinit();

    var i: u64 = 0;
    var numit = std.mem.tokenize(input, "\n");
    while (numit.next()) |numstr| : (i += 1) {
        const num = try std.fmt.parseInt(u64, numstr, 10);
        if (i > preamble_size) {
            if (!preambleHasSum(preamble.items, num)) {
                return num;
            }
            preamble.items[(i - 1) % preamble_size] = num;
        } else {
            try preamble.append(num);
        }
    }

    return aoc.Error.InvalidInput;
}

fn listSum(items: []u64) u64 {
    var sum: u64 = 0;
    for (items) |i|
        sum += i;
    return sum;
}

fn part1(allocator: *std.mem.Allocator, input: []u8, args: [][]u8) !void {
    std.debug.print("{}\n", .{try getInvalid(allocator, input)});
}

fn part2(allocator: *std.mem.Allocator, input: []u8, args: [][]u8) !void {
    const invalid = try getInvalid(allocator, input);

    var numset = std.ArrayList(u64).init(allocator);
    defer numset.deinit();

    var numit = std.mem.tokenize(input, "\n");
    while (true) {
        const sum = listSum(numset.items);
        if (sum < invalid) {
            const numstr = numit.next();
            if (numstr == null) break;
            const num = try std.fmt.parseInt(u64, numstr.?, 10);
            try numset.append(num);
        } else if (sum > invalid) {
            _ = numset.orderedRemove(0);
        } else {
            break;
        }
    }

    if (numset.items.len > 0) {
        std.debug.print("{}\n", .{std.mem.min(u64, numset.items) + std.mem.max(u64, numset.items)});
    }
}

pub const main = aoc.gen_main(part1, part2);
