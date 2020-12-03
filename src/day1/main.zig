const std = @import("std");
const aoc = @import("aoc");

const Parts = struct {
    a: u32, b: u32
};

fn findparts(intlist: *const std.ArrayList(u32), sum: u32) ?Parts {
    var start: usize = 0;
    const items = intlist.items;
    var end: usize = items.len - 1;
    while (start != end) {
        const csum = items[start] + items[end];
        if (csum == sum) {
            return Parts{ .a = items[start], .b = items[end] };
        } else if (csum > sum) {
            end -= 1;
        } else {
            start += 1;
        }
    }
    return null;
}

fn parse(allocator: *std.mem.Allocator, input: []u8) !std.ArrayList(u32) {
    var intlist = std.ArrayList(u32).init(allocator);
    errdefer intlist.deinit();

    var it = std.mem.tokenize(input, "\n");
    while (it.next()) |line| {
        try intlist.append(try std.fmt.parseInt(u32, line, 10));
    }

    return intlist;
}

fn part1(allocator: *std.mem.Allocator, input: []u8, args: [][]u8) !void {
    const intlist = try parse(allocator, input);
    defer intlist.deinit();

    std.sort.sort(u32, intlist.items, {}, comptime std.sort.asc(u32));

    if (findparts(&intlist, 2020)) |parts| {
        std.debug.print("{}\n", .{parts.a * parts.b});
    }
}

fn part2(allocator: *std.mem.Allocator, input: []u8, args: [][]u8) !void {
    const intlist = try parse(allocator, input);
    defer intlist.deinit();

    std.sort.sort(u32, intlist.items, {}, comptime std.sort.asc(u32));

    const target: u16 = 2020;
    var third: u32 = 0;
    while (third < intlist.items.len) : (third += 1) {
        const tmp = intlist.items[third];
        intlist.items[third] = target + 1;
        if (findparts(&intlist, target - tmp)) |parts| {
            std.debug.print("{}\n", .{parts.a * parts.b * tmp});
            return;
        }
        intlist.items[third] = tmp;
    }
}

pub const main = aoc.gen_main(part1, part2);
