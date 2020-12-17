const std = @import("std");
const aoc = @import("aoc");

fn PosVec(comptime N: u32) type {
    return struct { data: [N]i64 };
}

const Active = bool;

fn forNeighbors(comptime dims: u32, map: *std.AutoHashMap(PosVec(dims), Active), p: PosVec(dims), data: anytype, func: fn (map: *std.AutoHashMap(PosVec(dims), Active), p: PosVec(dims), d: @TypeOf(data)) anyerror!void) !void {
    var i: u32 = 0;
    while (i < comptime std.math.pow(u32, 3, dims)) : (i += 1) {
        var np: PosVec(dims) = undefined;
        var d: u32 = 0;
        var skip = true;
        while (d < dims) : (d += 1) {
            const offset = (i / std.math.pow(u32, 3, d)) % 3;
            np.data[d] = p.data[d] + @intCast(i64, offset) - 1;
            if (skip and offset != 1) skip = false;
        }
        if (skip) continue;
        try func(map, np, data);
    }
}

fn posStr(comptime dims: u32, p: PosVec(dims)) void {
    var d: u32 = 0;
    while (d < dims) : (d += 1) {
        std.debug.print("{} ", .{p.data[d]});
    }
}

fn countActive(comptime dims: u32) fn (map: *std.AutoHashMap(PosVec(dims), Active), p: PosVec(dims), d: *u32) anyerror!void {
    const impl = struct {
        fn func(map: *std.AutoHashMap(PosVec(dims), Active), p: PosVec(dims), d: *u32) anyerror!void {
            d.* += @boolToInt(map.get(p) != null);
        }
    };
    return impl.func;
}

fn addNew(comptime dims: u32) fn (oldmap: *std.AutoHashMap(PosVec(dims), Active), p: PosVec(dims), newmap: *std.AutoHashMap(PosVec(dims), Active)) anyerror!void {
    const impl = struct {
        fn func(oldmap: *std.AutoHashMap(PosVec(dims), Active), p: PosVec(dims), newmap: *std.AutoHashMap(PosVec(dims), Active)) anyerror!void {
            if (newmap.get(p) != null) return;

            var v = oldmap.get(p);
            var state = (v != null);

            var count: u32 = 0;
            try forNeighbors(dims, oldmap, p, &count, countActive(dims));
            if (state and count >= 2 and count <= 3 or !state and count == 3) {
                try newmap.put(p, true);
            }
        }
    };
    return impl.func;
}

fn simulateRound(comptime dims: u32, map: *std.AutoHashMap(PosVec(dims), Active), allocator: *std.mem.Allocator) !void {
    var newmap = std.AutoHashMap(PosVec(dims), Active).init(allocator);
    errdefer newmap.deinit();

    var mapit = map.iterator();
    while (mapit.next()) |kv| {
        try forNeighbors(dims, map, kv.key, &newmap, addNew(dims));
        try addNew(dims)(map, kv.key, &newmap);
    }

    std.mem.swap(std.AutoHashMap(PosVec(dims), Active), map, &newmap);
    newmap.deinit();
}

fn sliceProduct(data: []i64) i64 {
    var product: i64 = 1;
    for (data) |v| {
        product *= v;
    }
    return product;
}

fn printMap(comptime dims: u32, map: *std.AutoHashMap(PosVec(dims), Active)) void {
    var min: ?PosVec(dims) = null;
    var max: ?PosVec(dims) = null;

    var mapit = map.iterator();
    while (mapit.next()) |kv| {
        if (min == null) min = kv.key;
        if (max == null) max = kv.key;

        var d: u32 = 0;
        while (d < dims) : (d += 1) {
            if (min.?.data[d] > kv.key.data[d]) min.?.data[d] = kv.key.data[d];
            if (max.?.data[d] < kv.key.data[d]) max.?.data[d] = kv.key.data[d];
        }
    }

    if (min == null or max == null) return;

    var space: PosVec(dims) = undefined;
    {
        var d: u32 = 0;
        while (d < dims) : (d += 1) {
            space.data[d] = max.?.data[d] - min.?.data[d];
        }
    }

    var i: usize = 0;
    while (i < sliceProduct(space.data[0..])) : (i += @intCast(usize, space.data[0] * space.data[1])) {
        var np: PosVec(dims) = undefined;
        var d: u32 = 0;
        while (d < dims) : (d += 1) {
            np.data[d] = min.?.data[d] + @mod(@divFloor(@intCast(i64, i), sliceProduct(space.data[0..d])), space.data[d]);
        }

        d = 2;
        std.debug.print("Slice at: ", .{});
        while (d < dims) : (d += 1) {
            if (d > 2) std.debug.print(",", .{});
            std.debug.print("{}.Dim = {} ", .{ d + 1, np.data[d] });
        }
        std.debug.print("\n", .{});

        var y = min.?.data[1];
        while (y <= max.?.data[1]) : (y += 1) {
            var x = min.?.data[0];
            while (x <= max.?.data[0]) : (x += 1) {
                var v = np;
                v.data[0] = x;
                v.data[1] = y;
                var c: u8 = '.';
                if (map.get(v) != null) c = '#';
                std.debug.print("{c}", .{c});
            }
            std.debug.print("\n", .{});
        }
        std.debug.print("\n", .{});
    }
}

fn part1(allocator: *std.mem.Allocator, input: []u8, args: [][]u8) !void {
    var map = std.AutoHashMap(PosVec(3), Active).init(allocator);
    defer map.deinit();

    var lineit = std.mem.tokenize(input, "\n");
    var y: i64 = 0;
    while (lineit.next()) |line| : (y += 1) {
        for (line) |c, x| {
            if (c != '#') continue;
            try map.put(PosVec(3){ .data = [_]i64{ @intCast(i64, x), y, 0 } }, true);
        }
    }

    var i: usize = 0;
    while (i < 6) : (i += 1) {
        try simulateRound(3, &map, allocator);
        if (aoc.debug) {
            std.debug.print("AFTER ROUND {}:\n", .{i + 1});
            printMap(3, &map);
        }
    }

    var answer: u32 = map.count();
    std.debug.print("{}\n", .{answer});
}

fn part2(allocator: *std.mem.Allocator, input: []u8, args: [][]u8) !void {
    var map = std.AutoHashMap(PosVec(4), Active).init(allocator);
    defer map.deinit();

    var lineit = std.mem.tokenize(input, "\n");
    var y: i64 = 0;
    while (lineit.next()) |line| : (y += 1) {
        for (line) |c, x| {
            if (c != '#') continue;
            try map.put(PosVec(4){ .data = [_]i64{ @intCast(i64, x), y, 0, 0 } }, true);
        }
    }

    var i: usize = 0;
    while (i < 6) : (i += 1) {
        try simulateRound(4, &map, allocator);
        if (aoc.debug) {
            std.debug.print("AFTER ROUND {}:\n", .{i + 1});
            printMap(4, &map);
        }
    }

    var answer: u32 = map.count();
    std.debug.print("{}\n", .{answer});
}

pub const main = aoc.gen_main(part1, part2);
