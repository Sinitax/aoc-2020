const std = @import("std");
const aoc = @import("aoc");

fn getBit(v: u36, i: u6) bool {
    return ((v >> i) & 1) > 0;
}

fn clearBit(v: u36, i: u6) u36 {
    return v & ~(@as(u36, 1) << i);
}

fn setBit(v: u36, i: u6) u36 {
    return v | (@as(u36, 1) << i);
}

fn getValStr(line: []const u8) ![]const u8 {
    const sep = std.mem.indexOf(u8, line, " = ");
    if (sep == null) return aoc.Error.InvalidInput;
    return line[sep.? + 3 ..];
}

fn getAddrStr(line: []const u8) ![]const u8 {
    const sep = std.mem.indexOfScalar(u8, line, ']');
    if (sep == null) return aoc.Error.InvalidInput;
    return line[4..sep.?];
}

fn part1(allocator: *std.mem.Allocator, input: []u8, args: [][]u8) !void {
    var answer: u64 = 0;

    var memmap = std.AutoHashMap(u36, u64).init(allocator);
    defer memmap.deinit();

    var ormask: u36 = 0;
    var andmask: u36 = ~@as(u36, 0);

    var lineit = std.mem.tokenize(input, "\n");
    while (lineit.next()) |line| {
        if (std.mem.eql(u8, line[0..4], "mask")) {
            andmask = ~@as(u36, 0);
            ormask = 0;
            for (try getValStr(line)) |c, i| {
                if (c == '0') {
                    andmask = clearBit(andmask, @intCast(u6, 35 - i));
                } else if (c == '1') {
                    ormask = setBit(ormask, @intCast(u6, 35 - i));
                }
            }
        } else {
            const val = try std.fmt.parseInt(u36, try getValStr(line), 10);
            const addr = try std.fmt.parseInt(u36, try getAddrStr(line), 10);
            try memmap.put(addr, (val & andmask) | ormask);
        }
    }

    var mapit = memmap.iterator();
    while (mapit.next()) |kv| {
        answer += kv.value;
    }

    std.debug.print("{}\n", .{answer});
}

fn bitRecurse(map: *std.AutoHashMap(u36, u64), addr: *u36, val: u64, mask: u36, index: u6) anyerror!void {
    if (index == 36) {
        std.debug.print("SET: {b} {}\n", .{ addr.*, val });
        try map.put(addr.*, val);
    } else {
        if (getBit(mask, index)) {
            addr.* = setBit(addr.*, index);
            try bitRecurse(map, addr, val, mask, index + 1);
            addr.* = clearBit(addr.*, index);
            try bitRecurse(map, addr, val, mask, index + 1);
        } else {
            try bitRecurse(map, addr, val, mask, index + 1);
        }
    }
}

fn part2(allocator: *std.mem.Allocator, input: []u8, args: [][]u8) !void {
    var answer: u64 = 0;

    var memmap = std.AutoHashMap(u36, u64).init(allocator);
    defer memmap.deinit();

    var ormask: u36 = 0;
    var flipmask: u36 = 0;

    var lineit = std.mem.tokenize(input, "\n");
    while (lineit.next()) |line| {
        if (std.mem.eql(u8, line[0..4], "mask")) {
            ormask = 0;
            flipmask = 0;
            for (try getValStr(line)) |c, i| {
                if (c == '1') {
                    ormask = setBit(ormask, @intCast(u6, 35 - i));
                } else if (c == 'X') {
                    flipmask = setBit(flipmask, @intCast(u6, 35 - i));
                }
            }
        } else {
            var addr = try std.fmt.parseInt(u36, try getAddrStr(line), 10);
            const val = try std.fmt.parseInt(u36, try getValStr(line), 10);
            addr = addr | ormask;
            std.debug.print("{b} {b} {} {}\n", .{ flipmask, ormask, addr, val });
            try bitRecurse(&memmap, &addr, val, flipmask, 0);
        }
    }

    var mapit = memmap.iterator();
    while (mapit.next()) |kv| {
        answer += kv.value;
    }

    std.debug.print("{}\n", .{answer});
}

pub const main = aoc.gen_main(part1, part2);
