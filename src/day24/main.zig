const std = @import("std");
const aoc = @import("aoc");

const Color = enum { BLACK, WHITE };
const Dir = enum { E, SE, SW, W, NW, NE };
const dirs = [_]aoc.Pos{
    aoc.Pos{ .x = 2, .y = 0 },
    aoc.Pos{ .x = 1, .y = -1 },
    aoc.Pos{ .x = -1, .y = -1 },
    aoc.Pos{ .x = -2, .y = 0 },
    aoc.Pos{ .x = -1, .y = 1 },
    aoc.Pos{ .x = 1, .y = 1 },
};
const tokens = [_][]const u8{
    "e",
    "se",
    "sw",
    "w",
    "nw",
    "ne",
};
const Tile = struct {
    color: Color,
};

fn parseInput(tiles: *std.AutoHashMap(aoc.Pos, Tile), input: []const u8) !void {
    var lineit = std.mem.tokenize(input, "\n");
    while (lineit.next()) |line| {
        var pos = aoc.Pos{ .x = 0, .y = 0 };

        var i: usize = 0;
        while (i < line.len) {
            var dir = for (tokens) |tok, ti| {
                if (i + tok.len > line.len) continue;
                if (std.mem.eql(u8, tok, line[i .. i + tok.len])) {
                    i += tok.len;
                    break @intToEnum(Dir, @intCast(u3, ti));
                }
            } else return aoc.Error.InvalidInput;
            if (aoc.debug) std.debug.print("{} ", .{dir});
            pos = pos.add(dirs[@enumToInt(dir)]);
        }
        if (aoc.debug) std.debug.print("=> {} {}\n", .{ pos.x, pos.y });

        var tile = tiles.getEntry(pos);
        if (tile != null) {
            tile.?.value.color = if (tile.?.value.color == Color.WHITE) Color.BLACK else Color.WHITE;
        } else {
            try tiles.put(pos, Tile{ .color = Color.BLACK });
        }
    }
}

fn applyRule(pos: aoc.Pos, before: *std.AutoHashMap(aoc.Pos, Tile), after: *std.AutoHashMap(aoc.Pos, Tile)) !void {
    if (after.contains(pos)) return;
    const old_tile = before.get(pos);
    const old_color = if (old_tile == null) Color.WHITE else old_tile.?.color;

    var adj: u32 = 0;
    for (dirs) |d| {
        const tile = before.get(pos.add(d));
        if (tile != null and tile.?.color == Color.BLACK) adj += 1;
    }

    if (adj == 2 and old_color == Color.WHITE) {
        try after.put(pos, Tile{ .color = Color.BLACK });
    } else if ((adj == 0 or adj > 2) and old_color == Color.BLACK) {
        try after.put(pos, Tile{ .color = Color.WHITE });
    } else {
        try after.put(pos, Tile{ .color = old_color });
    }
}

fn doRound(allocator: *std.mem.Allocator, tiles: *std.AutoHashMap(aoc.Pos, Tile)) !void {
    var result = std.AutoHashMap(aoc.Pos, Tile).init(allocator);
    defer result.deinit();

    var mapit = tiles.iterator();
    while (mapit.next()) |kv| {
        for (dirs) |d| {
            try applyRule(kv.key.add(d), tiles, &result);
        }
        try applyRule(kv.key, tiles, &result);
    }

    std.mem.swap(std.AutoHashMap(aoc.Pos, Tile), &result, tiles);
}

fn countBlack(tiles: *std.AutoHashMap(aoc.Pos, Tile)) u32 {
    var count: u32 = 0;
    var mapit = tiles.iterator();
    while (mapit.next()) |kv| {
        if (kv.value.color == Color.BLACK) count += 1;
    }
    return count;
}

fn part1(allocator: *std.mem.Allocator, input: []u8, args: [][]u8) !void {
    var tiles = std.AutoHashMap(aoc.Pos, Tile).init(allocator);
    defer tiles.deinit();

    try parseInput(&tiles, input);

    std.debug.print("{}\n", .{countBlack(&tiles)});
}

fn part2(allocator: *std.mem.Allocator, input: []u8, args: [][]u8) !void {
    var tiles = std.AutoHashMap(aoc.Pos, Tile).init(allocator);
    defer tiles.deinit();

    try parseInput(&tiles, input);

    var round: usize = 0;
    while (round < 100) : (round += 1) {
        try doRound(allocator, &tiles);
    }

    std.debug.print("{}\n", .{countBlack(&tiles)});
}

pub const main = aoc.gen_main(part1, part2);
