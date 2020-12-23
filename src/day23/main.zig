const std = @import("std");
const aoc = @import("aoc");

// totally overengineered..
const Ring = struct {
    list: std.ArrayList(u32),
    indeces: std.ArrayList(*usize),

    const Self = @This();

    fn init(allocator: *std.mem.Allocator) Self {
        return Ring{
            .list = std.ArrayList(u32).init(allocator),
            .indeces = std.ArrayList(*usize).init(allocator),
        };
    }

    fn deinit(self: *Self) void {
        self.list.deinit();
        self.indeces.deinit();
    }

    fn size(self: *Self) usize {
        return self.list.items.len;
    }

    fn track(self: *Self, p: *usize) !void {
        try self.indeces.append(p);
    }

    fn untrack(self: *Self, p: *usize) void {
        const ind = std.mem.indexOfScalar(*usize, self.indeces.items, p);
        if (ind != null) _ = self.indeces.swapRemove(ind.?);
    }

    fn advanceIndex(self: *Self, ind: usize, off: i64) usize {
        return (ind + @intCast(usize, @mod(off, @intCast(i64, self.list.items.len)) + @intCast(i64, self.list.items.len))) % self.list.items.len;
    }

    fn dist(self: *Self, a: usize, b: usize) usize { // a - b (wrapped)
        return ((a % self.size()) + self.size() - (b % self.size())) % self.size();
    }

    fn removeAt(self: *Self, ind: usize) u32 {
        for (self.indeces.items) |v, i| {
            if (v.* > ind) v.* -= 1;
        }
        return self.list.orderedRemove(ind);
    }

    fn insertAt(self: *Self, ind: usize, item: u32) !void {
        for (self.indeces.items) |v| {
            if (v.* >= ind) v.* += 1;
        }
        try self.list.insert(ind, item);
    }
};

fn parseInput(input: []u8, list: *std.ArrayList(u32)) !u32 {
    var max: u32 = 0;
    for (input) |c, i| {
        if (c == '\n') break;
        const v = try std.fmt.parseInt(u32, input[i .. i + 1], 10);
        if (v > max) max = v;
        try list.append(v);
    }
    return max;
}

fn part1(allocator: *std.mem.Allocator, input: []u8, args: [][]u8) !void {
    var ring = Ring.init(allocator);
    defer ring.deinit();

    var max = try parseInput(input, &ring.list);

    for (input) |c, i| {
        if (c == '\n') break;
        const v = try std.fmt.parseInt(u32, input[i .. i + 1], 10);
        if (v > max) max = v;
        try ring.list.append(v);
    }

    if (ring.size() < 5) return aoc.Error.InvalidInput;

    var current: usize = 0;
    try ring.track(&current);

    var round: u32 = 0;
    while (round < 100) : (round += 1) {
        var target = if (ring.list.items[current] == 0) max else ring.list.items[current] - 1;
        var closest: usize = current;
        for (ring.list.items) |v, i| {
            if (ring.dist(target, v) < ring.dist(target, ring.list.items[closest]) and ring.dist(i, current) > 3) {
                closest = i;
            }
        }

        if (aoc.debug) {
            std.debug.print("\n-- move {} --\ncups: ", .{round + 1});
            for (ring.list.items) |v, i| {
                if (i > 0) std.debug.print(" ", .{});
                if (i == current) {
                    std.debug.print("({})", .{v});
                } else {
                    std.debug.print(" {} ", .{v});
                }
            }
            std.debug.print("\npick up: ", .{});
        }

        try ring.track(&closest);
        var i: usize = 0;
        while (i < 3) : (i += 1) {
            if (aoc.debug) {
                if (i > 0) std.debug.print(" ", .{});
                std.debug.print("{}", .{ring.list.items[ring.advanceIndex(current, 1)]});
            }
            const v = ring.removeAt(ring.advanceIndex(current, 1));
            try ring.insertAt(ring.advanceIndex(closest, @intCast(i64, 1 + i)), v);
        }
        ring.untrack(&closest);

        if (aoc.debug) std.debug.print("\ndestination: {}\n", .{ring.list.items[closest]});
        current = (current + 1) % ring.list.items.len;
    }

    var start = std.mem.indexOfScalar(u32, ring.list.items, 1).?;
    var i: u32 = 0;
    while (i < ring.size() - 1) : (i += 1) {
        std.debug.print("{}", .{ring.list.items[ring.advanceIndex(start, 1 + i)]});
    }
    std.debug.print("\n", .{});
}

fn part2(allocator: *std.mem.Allocator, input: []u8, args: [][]u8) !void {}

pub const main = aoc.gen_main(part1, part2);
