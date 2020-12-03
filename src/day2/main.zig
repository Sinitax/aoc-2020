const std = @import("std");
const aoc = @import("aoc");

const Entry = struct {
    a: u16, b: u16, char: u8, pass: []u8
};

fn freeEntries(allocator: *std.mem.Allocator, entries: *const std.ArrayList(Entry)) void {
    for (entries.items) |item|
        allocator.free(item.pass);
    entries.deinit();
}

fn parse(allocator: *std.mem.Allocator, input: []u8) !std.ArrayList(Entry) {
    var entries = std.ArrayList(Entry).init(allocator);
    errdefer freeEntries(allocator, &entries);

    var lineit = std.mem.tokenize(input, "\n");
    while (lineit.next()) |line| {
        var entry: Entry = undefined;
        var it = std.mem.tokenize(line, " -");
        entry.a = try std.fmt.parseInt(u16, it.next().?, 10);
        entry.b = try std.fmt.parseInt(u16, it.next().?, 10);
        entry.char = it.next().?[0];
        entry.pass = try allocator.dupe(u8, it.next().?);
        try entries.append(entry);
    }

    return entries;
}

fn part1(allocator: *std.mem.Allocator, input: []u8, args: [][]u8) !void {
    const entries = try parse(allocator, input);
    defer freeEntries(allocator, &entries);

    var valid: u32 = 0;
    for (entries.items) |entry| {
        var count: u16 = 0;
        for (entry.pass) |c| count += @boolToInt(c == entry.char);
        valid += @boolToInt(count >= entry.a and count <= entry.b);
    }
    std.debug.print("{}\n", .{valid});
}

fn part2(allocator: *std.mem.Allocator, input: []u8, args: [][]u8) !void {
    const entries = try parse(allocator, input);
    defer freeEntries(allocator, &entries);

    var valid: u32 = 0;
    for (entries.items) |entry| {
        valid += @boolToInt((entry.pass[entry.a - 1] == entry.char) !=
            (entry.pass[entry.b - 1] == entry.char));
    }
    std.debug.print("{}\n", .{valid});
}

pub const main = aoc.gen_main(part1, part2);
