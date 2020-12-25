const std = @import("std");
pub const input = @import("input.zig");

pub const Error = error{InvalidInput};

pub var debug = false;
pub var debuglvl: u32 = 0;

const part_type = fn (alloc: *std.mem.Allocator, input: []u8, args: [][]u8) anyerror!void;
pub fn gen_main(comptime part1: part_type, comptime part2: part_type) fn () anyerror!void {
    const impl = struct {
        fn main() !void {
            // create a default allocator
            var gpa = std.heap.GeneralPurposeAllocator(.{}){};
            defer _ = gpa.deinit();
            var heapalloc = &gpa.allocator;

            // parse args
            const args = try std.process.argsAlloc(heapalloc);
            defer heapalloc.free(args);
            if (args.len < 2) return;
            const part = try std.fmt.parseInt(u8, args[1], 10);

            var filename: []const u8 = std.mem.spanZ("input");
            for (std.os.environ) |v| {
                const kv = std.mem.spanZ(v);
                if (std.mem.indexOfScalar(u8, kv, '=')) |sep| {
                    if (sep == kv.len - 1) continue;
                    if (std.mem.eql(u8, kv[0..sep], "AOCINPUT")) {
                        filename = kv[sep + 1 ..];
                        std.debug.print("Using input file: {}\n", .{filename});
                        break;
                    } else if (std.mem.eql(u8, kv[0..sep], "AOCDEBUG")) {
                        debug = true;
                        debuglvl = try std.fmt.parseInt(u32, kv[sep + 1 ..], 10);
                    }
                }
            }

            // read all input into mem (files are always small so no problem)
            const file = try std.fs.cwd().openFile(filename, .{});
            const text = try file.reader().readAllAlloc(heapalloc, std.math.maxInt(u32));
            defer heapalloc.free(text);

            // exec part
            try switch (part) {
                1 => part1(heapalloc, text, args[2..]),
                2 => part2(heapalloc, text, args[2..]),
                else => std.debug.print("Invalid part number!\n", .{}),
            };
        }
    };
    return impl.main;
}

pub const Pos = struct {
    x: i64,
    y: i64,
    const Self = @This();

    pub fn add(self: Self, other: Self) Self {
        return Self{ .x = self.x + other.x, .y = self.y + other.y };
    }

    pub fn mult(self: Self, val: i64) Self {
        return Self{ .x = self.x * val, .y = self.y * val };
    }
};

pub const Dir = struct {
    pub const East = Pos{ .x = 1, .y = 0 };
    pub const West = Pos{ .x = -1, .y = 0 };
    pub const South = Pos{ .x = 0, .y = -1 };
    pub const North = Pos{ .x = 0, .y = 1 };

    pub const Name = enum {
        NORTH = 0, EAST = 1, SOUTH = 2, WEST = 3
    };
    pub const dirs = [_]Pos{ North, East, South, West };

    pub fn get(name: Name) Pos {
        return dirs[@enumToInt(name)];
    }

    pub fn nextCW(dir: usize, offset: usize) usize {
        return (dir + @intCast(u32, offset)) % @intCast(u32, dirs.len);
    }

    pub fn nextCCW(dir: usize, offset: usize) usize {
        const constrained = offset % dirs.len;
        if (dir >= constrained) {
            return dir - constrained;
        } else {
            return dirs.len - (constrained - dir);
        }
    }

    const cos90vs = [_]i32{ 1, 0, -1, 0 };
    const sin90vs = [_]i32{ 0, 1, 0, -1 };

    pub fn rotCW(pos: Pos, offset: usize) Pos {
        const constrained = (4 - offset % 4) % 4;
        return Pos{
            .x = cos90vs[constrained] * pos.x - sin90vs[constrained] * pos.y,
            .y = sin90vs[constrained] * pos.x + cos90vs[constrained] * pos.y,
        };
    }

    pub fn rotCCW(pos: Pos, offset: usize) Pos {
        const constrained = offset % 4;
        std.debug.print("{}\n", .{constrained});
        return Pos{
            .x = cos90vs[constrained] * pos.x - sin90vs[constrained] * pos.y,
            .y = sin90vs[constrained] * pos.x + cos90vs[constrained] * pos.y,
        };
    }
};

pub fn assertV(v: anytype) !@TypeOf(v.?) {
    if (v == null) return Error.InvalidInput;
    return v.?;
}
