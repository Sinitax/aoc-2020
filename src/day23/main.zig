const std = @import("std");
const aoc = @import("aoc");

// Links in this list are arranges in a circle
const RingLink = struct {
    data: u32,
    next: *RingLink,
    const Self = @This();

    pub fn insertNext(self: *Self, link: *RingLink) void {
        link.next = self.next;
        self.next = link;
    }

    pub fn popNext(self: *Self) !*Self {
        const nlink = self.next;
        if (nlink == self) return error.EmptyRingList;
        self.next = nlink.next;
        return nlink;
    }

    pub fn length(self: *Self) usize {
        var count: usize = 1;
        var link = self.next;
        while (link != self) : (link = link.next) {
            count += 1;
        }
        return count;
    }

    pub fn advance(self: *Self, count: usize) *RingLink {
        var link = self;
        var counter: usize = 0;
        while (counter < count) : (link = link.next) {
            counter += 1;
        }
        return link;
    }
};

fn parseInput(input: []const u8, lookup: []RingLink, list: *?*RingLink) !u32 {
    var max: u32 = 0;
    var link: *RingLink = undefined;
    for (input) |c, i| {
        if (c == '\n') break;
        const v = try std.fmt.parseInt(u32, input[i .. i + 1], 10);
        if (v > max) max = v;
        if (list.* == null) {
            list.* = &lookup[v];
            link = list.*.?;
            link.next = link;
        } else {
            link.insertNext(&lookup[v]);
            link = link.next;
        }
    }
    return max;
}

fn doRound(list: *RingLink, len: u32, lookup: []RingLink, current: **RingLink, max: u32, round: usize) !void {
    if (aoc.debug) {
        std.debug.print("\n-- move {} --\ncups:", .{round});

        var start = current.*.advance(len - ((round - 1) % len));
        var link = start;
        while (true) {
            if (link == current.*) {
                std.debug.print(" ({})", .{link.data});
            } else {
                std.debug.print("  {} ", .{link.data});
            }
            link = link.next;
            if (link == start) break;
        }
        std.debug.print("\n", .{});
    }

    var target = (current.*.data + max - 2) % max + 1;
    var k: usize = 0;
    var check = current.*.next;
    while (k < 9) : (k += 1) {
        if (check.data == target)
            target = (target + max - 2) % max + 1;

        check = if (k % 3 == 0) current.*.next else check.next;
    }

    var closest = &lookup[target];
    var i: usize = 0;
    while (i < 3) : (i += 1) {
        const poplink = try current.*.popNext();
        closest.insertNext(poplink);
        closest = poplink;
    }

    current.* = current.*.next;
}

fn createLookup(allocator: *std.mem.Allocator, len: usize) ![]RingLink {
    var lookup = try allocator.alloc(RingLink, len + 1);
    errdefer allocator.free(lookup);

    var i: usize = 1;
    while (i <= len) : (i += 1) {
        lookup[i] = RingLink{ .data = @intCast(u32, i), .next = undefined };
    }

    return lookup;
}

fn part1(allocator: *std.mem.Allocator, input: []u8, args: [][]u8) !void {
    var lookup = try createLookup(allocator, 9);
    defer allocator.free(lookup);

    var list: ?*RingLink = null;
    const max = try parseInput(input, lookup, &list);
    if (list == null) return aoc.Error.InvalidInput;
    const real_len = @intCast(u32, list.?.length());

    var round: usize = 0;
    var current = list.?;
    while (round < 100) : (round += 1) {
        try doRound(list.?, real_len, lookup, &current, max, round + 1);
    }

    var start = &lookup[1];
    var link = start.next;
    while (link != start) : (link = link.next) {
        std.debug.print("{}", .{link.data});
    }
    std.debug.print("\n", .{});
}

fn part2(allocator: *std.mem.Allocator, input: []u8, args: [][]u8) !void {
    var lookup = try createLookup(allocator, 1000000);
    defer allocator.free(lookup);

    var list: ?*RingLink = null;
    const max = try parseInput(input, lookup, &list);
    if (list == null) return aoc.Error.InvalidInput;
    const real_len = list.?.length();

    var end = list.?.advance(real_len - 1);
    var i = real_len + 1;
    while (i <= 1000000) : (i += 1) {
        end.insertNext(&lookup[i]);
        end = end.next;
    }

    var round: usize = 0;
    var current = list.?;
    while (round < 10000000) : (round += 1) {
        if (round % 1000000 == 0) std.debug.print(".", .{});
        try doRound(list.?, 1000000, lookup, &current, max, round + 1);
    }
    std.debug.print("\n", .{});

    var link = (&lookup[1]).next;
    std.debug.print("{} * {} = {}\n", .{ @intCast(u64, link.data), @intCast(u64, link.next.data), @intCast(u64, link.data) * @intCast(u64, link.next.data) });
}

pub const main = aoc.gen_main(part1, part2);
