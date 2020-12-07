const std = @import("std");
const aoc = @import("aoc");

const testv = @ptrToInt(&target);
const BagCount = struct {
    id: u64, count: u32
};

// null for 'not available' and errors for 'parsing failed'

const BagRule = struct {
    outer: u64,
    inner_striter: std.mem.SplitIterator,
    const Self = @This();

    fn from(line: []const u8) !Self {
        var partit = std.mem.split(line[0 .. line.len - 1], " bags contain ");
        var outer = std.hash.CityHash64.hash(partit.next().?);
        var innerit = std.mem.split(partit.next().?, ", ");
        return Self{ .outer = outer, .inner_striter = innerit };
    }

    fn nextInner(self: *Self) !?BagCount {
        if (self.inner_striter.next()) |bagstr| {
            if (std.mem.eql(u8, bagstr[0..2], "no")) return null;
            const lastsep = std.mem.lastIndexOfScalar(u8, bagstr, ' ').?;
            const firstsep = std.mem.indexOfScalar(u8, bagstr, ' ').?;
            const count = try std.fmt.parseInt(u32, bagstr[0..firstsep], 10);
            const id = std.hash.CityHash64.hash(bagstr[firstsep + 1 .. lastsep]);
            return BagCount{ .id = id, .count = count };
        } else {
            return null;
        }
    }
};

fn countBagsTotal(map: *std.AutoHashMap(u64, std.ArrayList(BagCount)), outer: u64) u64 {
    var sum: u64 = 0;
    if (map.get(outer)) |inner| {
        for (inner.items) |bag|
            sum += bag.count * (1 + countBagsTotal(map, bag.id));
    }
    return sum;
}

fn countParentTypes(map: *std.AutoHashMap(u64, std.ArrayList(u64)), inner: u64, seen: *std.ArrayList(u64)) anyerror!u64 {
    var sum: u64 = 0;
    if (map.get(inner)) |outer| {
        for (outer.items) |bagid| {
            if (std.mem.indexOfScalar(u64, seen.items, bagid) == null) {
                try seen.append(bagid);
                sum += 1 + try countParentTypes(map, bagid, seen);
            }
        }
    }
    return sum;
}

fn part1(allocator: *std.mem.Allocator, input: []u8, args: [][]u8) !void {
    var lineit = std.mem.tokenize(input, "\n");
    var map = std.AutoHashMap(u64, std.ArrayList(u64)).init(allocator);
    defer {
        var mapit = map.iterator();
        while (mapit.next()) |kv| kv.value.deinit();
        map.deinit();
    }

    while (lineit.next()) |line| {
        var rule = try BagRule.from(line);
        while (try rule.nextInner()) |inner| {
            if (map.get(inner.id) == null)
                try map.put(inner.id, std.ArrayList(u64).init(allocator));
            try map.getEntry(inner.id).?.*.value.append(rule.outer);
        }
    }

    const target = std.hash.CityHash64.hash("shiny gold");
    var seen = std.ArrayList(u64).init(allocator);
    defer seen.deinit();
    std.debug.print("{}\n", .{countParentTypes(&map, target, &seen)});
}

fn part2(allocator: *std.mem.Allocator, input: []u8, args: [][]u8) !void {
    var lineit = std.mem.tokenize(input, "\n");
    var map = std.AutoHashMap(u64, std.ArrayList(BagCount)).init(allocator);
    defer {
        var mapit = map.iterator();
        while (mapit.next()) |kv| kv.value.deinit();
        map.deinit();
    }

    const target = std.hash.CityHash64.hash("shiny gold");
    while (lineit.next()) |line| {
        var rule = try BagRule.from(line);
        if (map.get(rule.outer) == null)
            try map.put(rule.outer, std.ArrayList(BagCount).init(allocator));
        while (try rule.nextInner()) |bag| {
            try map.getEntry(rule.outer).?.*.value.append(bag);
        }
    }

    std.debug.print("{}\n", .{countBagsTotal(&map, target)});
}

pub const main = aoc.gen_main(part1, part2);
