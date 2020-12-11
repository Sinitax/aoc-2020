const std = @import("std");
const aoc = @import("aoc");

fn part1(allocator: *std.mem.Allocator, input: []u8, args: [][]u8) !void {
    var target: u32 = 0;

    var intlist = std.ArrayList(u32).init(allocator);
    defer intlist.deinit();

    var lineit = std.mem.tokenize(input, "\n");
    while (lineit.next()) |line| {
        var val = try std.fmt.parseInt(u32, line, 10);
        if (val > target) {
            target = val;
        }
        try intlist.append(val);
    }

    target += 3;
    try intlist.append(target);

    if (intlist.items.len == 0) return;

    std.sort.sort(u32, intlist.items, {}, comptime std.sort.asc(u32));

    var diffs = [_]u32{ 0, 0, 0, 0 };
    var last: u32 = 0;
    for (intlist.items) |ov| {
        if (ov - last > 3 or ov == last) {
            std.debug.print("Unable to find a suitable adapter for {} output jolts (next: {} jolts)\n", .{ last, ov });
            return aoc.Error.InvalidInput;
        }
        diffs[ov - last] += 1;
        last = ov;
    }

    std.debug.print("{}\n", .{diffs[1] * diffs[3]});
}

fn countArrangements(arrangement: []u32, adapters: []const u32, adaptermask: []u1, target: u32, fillcount: u32, searchstart: u32, count: *u32) void {
    var last: u32 = 0;
    if (fillcount > 0) {
        last = arrangement[fillcount - 1];
    }

    if (last == target) {
        count.* += 1;
        return;
    }

    for (adapters[searchstart..]) |adap, i| {
        if (adaptermask[searchstart + i] == 1) continue;
        if (adap > last + 3) break;

        adaptermask[searchstart + i] = 1;
        arrangement[fillcount] = adap;
        countArrangements(arrangement, adapters, adaptermask, target, fillcount + 1, searchstart + @intCast(u32, i) + 1, count);
        adaptermask[searchstart + i] = 0;
    }
}

fn part2Recursive(allocator: *std.mem.Allocator, input: []u8, args: [][]u8) !void {
    var target: u32 = 0;

    var intlist = std.ArrayList(u32).init(allocator);
    defer intlist.deinit();

    var lineit = std.mem.tokenize(input, "\n");
    while (lineit.next()) |line| {
        var val = try std.fmt.parseInt(u32, line, 10);
        if (val > target) {
            target = val;
        }
        try intlist.append(val);
    }

    target += 3;
    try intlist.append(target);

    if (intlist.items.len == 0) return;

    std.sort.sort(u32, intlist.items, {}, comptime std.sort.asc(u32));

    var count: u32 = 0;

    var arrangements = try allocator.alloc(u32, intlist.items.len);
    defer allocator.free(arrangements);

    var adaptermask = try allocator.alloc(u1, intlist.items.len);
    defer allocator.free(adaptermask);

    countArrangements(arrangements, intlist.items, adaptermask, target, 0, 0, &count);

    std.debug.print("{}\n", .{count});
}

fn groupPermutations(adapters: []const u32) u64 {
    if (adapters.len == 1) return 1;
    var count: u64 = 0;
    for (adapters) |v, i| {
        if (i == 0) continue;
        if (adapters[i] <= adapters[0] + 3) {
            count += groupPermutations(adapters[i..]);
        }
    }
    return count;
}

fn part2Iterative(allocator: *std.mem.Allocator, input: []u8, args: [][]u8) !void {
    var target: u32 = 0;

    var intlist = std.ArrayList(u32).init(allocator);
    defer intlist.deinit();

    try intlist.append(0);

    var lineit = std.mem.tokenize(input, "\n");
    while (lineit.next()) |line| {
        var val = try std.fmt.parseInt(u32, line, 10);
        if (val > target) {
            target = val;
        }
        try intlist.append(val);
    }

    target += 3;
    try intlist.append(target);

    if (intlist.items.len == 0) return aoc.Error.InvalidInput;

    std.sort.sort(u32, intlist.items, {}, comptime std.sort.asc(u32));

    var gapstart: u32 = 0;
    var multiplier: u128 = 1;

    var i: u32 = 0;
    while (i < intlist.items.len - 1) : (i += 1) {
        // whenever we encounter a 3 jolt gap, we can calc permutations of group before
        if (i + 1 < intlist.items.len and intlist.items[i + 1] == intlist.items[i] + 3) {
            multiplier *= groupPermutations(intlist.items[gapstart .. i + 1]);
            std.debug.print("gap from {} to {} => {}\n", .{ intlist.items[i], intlist.items[i + 1], multiplier });
            std.debug.print("group size: {}\n", .{i + 1 - gapstart});
            gapstart = i + 1;
        }
    }

    std.debug.print("{}\n", .{multiplier});
}

fn part2(allocator: *std.mem.Allocator, input: []u8, args: [][]u8) !void {
    try part2Iterative(allocator, input, args);
}

pub const main = aoc.gen_main(part1, part2);
