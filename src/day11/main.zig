const std = @import("std");
const aoc = @import("aoc");

const SeatState = enum { EMPTY, FLOOR, TAKEN };
const MapDims = struct { width: usize, height: usize };
const Dir = struct { x: i8, y: i8 };
const Pos = struct { x: i128, y: i128 };

const adjacent = [_]Dir{
    Dir{ .x = -1, .y = -1 },
    Dir{ .x = -0, .y = -1 },
    Dir{ .x = 1, .y = -1 },
    Dir{ .x = -1, .y = 0 },
    Dir{ .x = 1, .y = 0 },
    Dir{ .x = -1, .y = 1 },
    Dir{ .x = 0, .y = 1 },
    Dir{ .x = 1, .y = 1 },
};

fn parseMap(mapitems: *[]SeatState, dims: *MapDims, input: []const u8, allocator: *std.mem.Allocator) !void {
    var lineit = std.mem.tokenize(input, "\n");
    var map = std.ArrayList(SeatState).init(allocator);
    errdefer map.deinit();
    while (lineit.next()) |line| {
        if (dims.width == 0) {
            dims.width = line.len;
        } else if (dims.width != line.len) {
            return aoc.Error.InvalidInput;
        }
        for (line) |c, i| {
            try map.append(switch (c) {
                '#' => SeatState.TAKEN,
                'L' => SeatState.EMPTY,
                '.' => SeatState.FLOOR,
                else => {
                    return aoc.Error.InvalidInput;
                },
            });
        }
        dims.height += 1;
    }
    mapitems.* = map.toOwnedSlice();
}

fn printMap(mapitems: []SeatState, dims: MapDims) void {
    for (mapitems) |state, i| {
        const c: u8 = switch (state) {
            SeatState.EMPTY => 'L',
            SeatState.TAKEN => '#',
            SeatState.FLOOR => '.',
        };
        if (i % dims.width == 0) {
            std.debug.print("\n", .{});
        }
        std.debug.print("{c}", .{c});
    }
}

fn simulateStrategyOne(before: []SeatState, after: []SeatState, dims: MapDims) u32 {
    var seat_changes: u32 = 0;
    for (before) |state, i| {
        const p = Pos{ .x = i % dims.width, .y = i / dims.width };
        var count: u32 = 0;
        for (adjacent) |ap| {
            if (p.x + ap.x >= dims.width or p.x + ap.x < 0 or p.y + ap.y >= dims.height or p.y + ap.y < 0) continue;
            const ni = @intCast(u64, @intCast(i64, i) + ap.x + ap.y * @intCast(i64, dims.width));
            count += @boolToInt(before[ni] == SeatState.TAKEN);
        }
        if (state == SeatState.EMPTY and count == 0) {
            after[i] = SeatState.TAKEN;
            seat_changes += 1;
        } else if (state == SeatState.TAKEN and count >= 4) {
            after[i] = SeatState.EMPTY;
            seat_changes += 1;
        } else {
            after[i] = before[i];
        }
    }
    return seat_changes;
}

fn simulateStrategyTwo(before: []SeatState, after: []SeatState, dims: MapDims) u32 {
    var seat_changes: u32 = 0;
    for (before) |state, i| {
        const p = Pos{ .x = i % dims.width, .y = i / dims.width };
        var count: u32 = 0;
        for (adjacent) |ap| {
            var iterp = Pos{ .x = p.x + ap.x, .y = p.y + ap.y };
            while (iterp.x < dims.width and iterp.x >= 0 and iterp.y < dims.height and iterp.y >= 0) {
                const ni = @intCast(u64, iterp.x + iterp.y * @intCast(i64, dims.width));
                if (before[ni] == SeatState.TAKEN) {
                    count += 1;
                    break;
                } else if (before[ni] == SeatState.EMPTY) {
                    break;
                } else {
                    iterp.x += ap.x;
                    iterp.y += ap.y;
                }
            }
        }
        if (state == SeatState.EMPTY and count == 0) {
            after[i] = SeatState.TAKEN;
            seat_changes += 1;
        } else if (state == SeatState.TAKEN and count >= 5) {
            after[i] = SeatState.EMPTY;
            seat_changes += 1;
        } else {
            after[i] = before[i];
        }
    }
    return seat_changes;
}

fn part1(allocator: *std.mem.Allocator, input: []u8, args: [][]u8) !void {
    var mapdims = MapDims{ .width = 0, .height = 0 };
    var mapitems: []SeatState = undefined;
    try parseMap(&mapitems, &mapdims, input, allocator);
    defer allocator.free(mapitems);

    var mapresult = try allocator.alloc(SeatState, mapitems.len);
    defer allocator.free(mapresult);

    var round: u32 = 0;
    while (simulateStrategyOne(mapitems, mapresult, mapdims) > 0) : (round += 1) {
        std.debug.print("\rRound: {}", .{round});
        std.mem.copy(SeatState, mapitems, mapresult);
    }

    var taken_count: u64 = 0;
    for (mapresult) |state| {
        taken_count += @boolToInt(state == SeatState.TAKEN);
    }

    std.debug.print("\nSeats Occupied: {}\n", .{taken_count});
}

fn part2(allocator: *std.mem.Allocator, input: []u8, args: [][]u8) !void {
    var mapdims = MapDims{ .width = 0, .height = 0 };
    var mapitems: []SeatState = undefined;
    try parseMap(&mapitems, &mapdims, input, allocator);
    defer allocator.free(mapitems);

    var mapresult = try allocator.alloc(SeatState, mapitems.len);
    defer allocator.free(mapresult);

    var round: u32 = 0;
    while (simulateStrategyTwo(mapitems, mapresult, mapdims) > 0) : (round += 1) {
        std.debug.print("\rRound: {}", .{round});
        std.mem.copy(SeatState, mapitems, mapresult);
    }

    var taken_count: u64 = 0;
    for (mapresult) |state| {
        taken_count += @boolToInt(state == SeatState.TAKEN);
    }

    std.debug.print("\nSeats Occupied: {}\n", .{taken_count});
}

pub const main = aoc.gen_main(part1, part2);
