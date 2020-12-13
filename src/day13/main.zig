const std = @import("std");
const aoc = @import("aoc");

fn gcd(a: u64, b: u64) u64 {
    var ac = a;
    var bc = b;
    while (true) {
        if (ac > bc) {
            ac = ac % bc;
            if (ac == 0) return bc;
        } else {
            bc = bc % ac;
            if (bc == 0) return ac;
        }
    }
}

fn lcm(a: u64, b: u64) u64 {
    return @divExact(a * b, gcd(a, b));
}

fn waittime(start: u32, busid: u32) u32 {
    return (busid - (start % busid)) % busid;
}

fn printRegion(buses: []u32, start: u64, end: u64) void {
    std.debug.print("          ", .{});
    for (buses) |bus| {
        std.debug.print(" {:^5}", .{bus});
    }
    std.debug.print("\n", .{});

    var i = start;
    while (i < end) : (i += 1) {
        std.debug.print("{:<10}", .{i});
        for (buses) |bus| {
            var c: u8 = '.';
            if (bus > 0 and i % bus == 0) c = 'D';
            std.debug.print("   {c}  ", .{c});
        }
        std.debug.print("\n", .{});
    }
    std.debug.print("\n", .{});
}

fn part1(allocator: *std.mem.Allocator, input: []u8, args: [][]u8) !void {
    var lineit = std.mem.tokenize(input, "\n");
    var start = try std.fmt.parseInt(u32, lineit.next().?, 10);

    var bestbus: ?u32 = null;
    var busit = std.mem.tokenize(lineit.next().?, ",");
    while (busit.next()) |bus| {
        if (bus[0] == 'x') continue;
        const val = try std.fmt.parseInt(u32, bus, 10);
        if (bestbus == null or waittime(start, val) < waittime(start, bestbus.?)) {
            bestbus = val;
        }
    }

    std.debug.print("{} {}\n", .{ bestbus.?, bestbus.? * waittime(start, bestbus.?) });
}

fn part2(allocator: *std.mem.Allocator, input: []u8, args: [][]u8) !void {
    var lineit = std.mem.tokenize(input, "\n");
    _ = try std.fmt.parseInt(u32, lineit.next().?, 10);

    var busses = std.ArrayList(u32).init(allocator);
    defer busses.deinit();

    var busit = std.mem.tokenize(lineit.next().?, ",");

    const first = try std.fmt.parseInt(u32, busit.next().?, 10);
    try busses.append(first);

    var offset: u64 = 0;
    var cycle: u64 = first;
    var delay: u32 = 1;
    while (busit.next()) |bus| : (delay += 1) {
        if (bus[0] == 'x') {
            try busses.append(0);
            continue;
        }
        const val = try std.fmt.parseInt(u32, bus, 10);
        try busses.append(val);

        var mult: u64 = @divFloor(offset + delay, val);
        if ((offset + delay) % val != 0) mult += 1;
        while ((mult * val - offset - delay) % cycle != 0) {
            mult += std.math.max(1, @divFloor(cycle - (mult * val - offset - delay) % cycle, val));
        }
        offset = mult * val - delay;

        cycle = lcm(cycle, val);
        if (aoc.debug) {
            printRegion(busses.items, offset, offset + delay + 1);
            printRegion(busses.items, offset + cycle, offset + cycle + delay + 1);
            std.debug.print("{}\n", .{offset});
        }
    }

    printRegion(busses.items, offset, offset + busses.items.len);
    std.debug.print("{}\n", .{offset});
}

pub const main = aoc.gen_main(part1, part2);
