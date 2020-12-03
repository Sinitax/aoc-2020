const std = @import("std");
const aoc = @import("aoc");

const Entry = []u1;
const Vector = struct {
    x: u16, y: u16
};

fn freeEntries(allocator: *std.mem.Allocator, entries: *const std.ArrayList(Entry)) void {
    for (entries.items) |entry| {
        allocator.free(entry);
    }
    entries.deinit();
}

fn parse(allocator: *std.mem.Allocator, input: []u8) !std.ArrayList(Entry) {
    var entries = std.ArrayList(Entry).init(allocator);
    errdefer freeEntries(allocator, &entries);

    var lineit = std.mem.tokenize(input, "\n");
    while (lineit.next()) |line| {
        var linemap: []u1 = try allocator.alloc(u1, line.len);
        errdefer allocator.free(linemap);

        for (line) |c, i| {
            linemap[i] = @boolToInt(c == '#');
        }
        try entries.append(linemap);
    }

    return entries;
}

fn treesHit(map: std.ArrayList(Entry), slope: Vector) u16 {
    var count: u16 = 0;
    var pos = Vector{ .x = 0, .y = 0 };
    while (pos.y < map.items.len - 1) {
        pos.x += slope.x;
        pos.y += slope.y;

        count += map.items[pos.y][pos.x % map.items[0].len];
    }
    return count;
}

fn part1(allocator: *std.mem.Allocator, input: []u8, args: [][]u8) !void {
    const map = try parse(allocator, input);
    defer freeEntries(allocator, &map);

    const answer = treesHit(map, Vector{ .x = 3, .y = 1 });
    std.debug.print("{}\n", .{answer});
}

fn part2(allocator: *std.mem.Allocator, input: []u8, args: [][]u8) !void {
    const map = try parse(allocator, input);
    defer freeEntries(allocator, &map);

    var answer: u32 = 1;
    const slopes = [_]Vector{
        Vector{ .x = 1, .y = 1 },
        Vector{ .x = 3, .y = 1 },
        Vector{ .x = 5, .y = 1 },
        Vector{ .x = 7, .y = 1 },
        Vector{ .x = 1, .y = 2 },
    };
    for (slopes) |slope| {
        answer *= treesHit(map, slope);
    }

    std.debug.print("{}\n", .{answer});
}

pub const main = aoc.gen_main(part1, part2);
