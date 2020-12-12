const std = @import("std");
const aoc = @import("aoc");
const Pos = aoc.Pos;
const Dir = aoc.Dir;

const Ship = struct { pos: Pos, waypoint: Pos, dir: usize };

fn part1(allocator: *std.mem.Allocator, input: []u8, args: [][]u8) !void {
    var ship = Ship{ .pos = Pos{ .x = 0, .y = 0 }, .waypoint = Pos{ .x = 0, .y = 0 }, .dir = 0 };
    var lineit = std.mem.tokenize(input, "\n");
    while (lineit.next()) |line| {
        const val = try std.fmt.parseInt(u32, line[1..], 10);
        switch (line[0]) {
            'N' => ship.pos = ship.pos.add(Dir.North.mult(val)),
            'S' => ship.pos = ship.pos.add(Dir.South.mult(val)),
            'E' => ship.pos = ship.pos.add(Dir.East.mult(val)),
            'W' => ship.pos = ship.pos.add(Dir.West.mult(val)),
            'L' => ship.dir = Dir.nextCCW(ship.dir, @divExact(val, 90)),
            'R' => ship.dir = Dir.nextCW(ship.dir, @divExact(val, 90)),
            'F' => ship.pos = ship.pos.add(Dir.dirs[ship.dir].mult(val)),
            else => {
                return aoc.Error.InvalidInput;
            },
        }
    }

    std.debug.print("{}\n", .{std.math.absCast(ship.pos.x) + std.math.absCast(ship.pos.y)});
}

fn part2(allocator: *std.mem.Allocator, input: []u8, args: [][]u8) !void {
    var ship = Ship{ .pos = Pos{ .x = 0, .y = 0 }, .waypoint = Pos{ .x = 10, .y = 1 }, .dir = 0 };
    var lineit = std.mem.tokenize(input, "\n");
    while (lineit.next()) |line| {
        const val = try std.fmt.parseInt(u32, line[1..], 10);
        switch (line[0]) {
            'N' => ship.waypoint = ship.waypoint.add(Dir.North.mult(val)),
            'S' => ship.waypoint = ship.waypoint.add(Dir.South.mult(val)),
            'E' => ship.waypoint = ship.waypoint.add(Dir.East.mult(val)),
            'W' => ship.waypoint = ship.waypoint.add(Dir.West.mult(val)),
            // WORKAROUND for language bug (parameter is implicitly passed as reference and assignment order)
            'L' => {
                var new = Dir.rotCCW(ship.waypoint, @divExact(val, 90));
                ship.waypoint = new;
            },
            'R' => {
                var new = Dir.rotCW(ship.waypoint, @divExact(val, 90));
                ship.waypoint = new;
            },
            'F' => ship.pos = ship.pos.add(ship.waypoint.mult(val)),
            else => {
                return aoc.Error.InvalidInput;
            },
        }
        std.debug.print("{} {} {} {} {}\n", .{ line, ship.waypoint.x, ship.waypoint.y, ship.pos.x, ship.pos.y });
    }

    std.debug.print("{}\n", .{std.math.absCast(ship.pos.x) + std.math.absCast(ship.pos.y)});
}

pub const main = aoc.gen_main(part1, part2);
