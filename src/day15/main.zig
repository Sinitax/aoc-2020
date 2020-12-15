const std = @import("std");
const aoc = @import("aoc");

const Occurance = struct { last: u32, beforelast: u32 };

fn getNthSpoken(allocator: *std.mem.Allocator, input: []u8, spoken: u32) !u32 {
    var occurances = std.AutoHashMap(u32, Occurance).init(allocator);
    defer occurances.deinit();

    var intlist = std.ArrayList(u32).init(allocator);
    defer intlist.deinit();

    var numit = std.mem.tokenize(input, "\n,");
    var i: u32 = 0;
    while (numit.next()) |numstr| : (i += 1) {
        const num = try std.fmt.parseInt(u32, numstr, 10);
        try intlist.append(num);
        try occurances.put(num, Occurance{ .last = i, .beforelast = i });
    }

    while (i < spoken) : (i += 1) {
        if (aoc.debug and i % 100000 == 0)
            std.debug.print("\r{}", .{i});

        const num = intlist.items[i - 1];
        var entry = occurances.getEntry(num);
        var diff: u32 = 0;
        if (entry) |occ_entry| {
            diff = occ_entry.value.last - occ_entry.value.beforelast;
        }
        entry = occurances.getEntry(diff);
        if (entry) |occ_entry| {
            occ_entry.value.beforelast = occ_entry.value.last;
            occ_entry.value.last = i;
        } else {
            try occurances.put(diff, Occurance{ .last = i, .beforelast = i });
        }
        try intlist.append(diff);
    }

    if (aoc.debug)
        std.debug.print("\r               \r", .{});

    return intlist.items[spoken - 1];
}

fn part1(allocator: *std.mem.Allocator, input: []u8, args: [][]u8) !void {
    std.debug.print("{}\n", .{try getNthSpoken(allocator, input, 2020)});
}

fn part2(allocator: *std.mem.Allocator, input: []u8, args: [][]u8) !void {
    std.debug.print("{}\n", .{try getNthSpoken(allocator, input, 30000000)});
}

pub const main = aoc.gen_main(part1, part2);
