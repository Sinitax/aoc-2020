const std = @import("std");
const aoc = @import("aoc");

fn intChecker(
    comptime min: u32,
    comptime max: u32,
    comptime len: ?u32,
    comptime suffix: ?[]const u8,
) fn ([]const u8) bool {
    const impl = struct {
        fn check(input: []const u8) bool {
            var parsed = input;
            if (suffix) |suf| {
                if (!std.mem.eql(u8, suf, input[(input.len - suf.len)..]))
                    return false;
                parsed = input[0..(input.len - suf.len)];
            }
            if (len != null and parsed.len != len.?)
                return false;
            const val = std.fmt.parseInt(u32, parsed, 10) catch |x| {
                return false;
            };
            return (val >= min and val <= max);
        }
    };
    return impl.check;
}

fn combineOr(
    comptime f1: fn ([]const u8) bool,
    comptime f2: fn ([]const u8) bool,
) fn ([]const u8) bool {
    const impl = struct {
        fn check(input: []const u8) bool {
            return f1(input) or f2(input);
        }
    };
    return impl.check;
}

fn isColorStr(input: []const u8) bool {
    if (input.len != 7) return false;
    _ = std.fmt.parseInt(u32, input[1..], 16) catch |x| {
        return false;
    };
    return input[0] == '#';
}

fn isEyeColor(input: []const u8) bool {
    const valids = "amb blu brn gry grn hzl oth";
    return std.mem.indexOf(u8, valids[0..], input) != null;
}

fn countValids(allocator: *std.mem.Allocator, input: []u8, validate: bool) !u16 {
    var entryit = std.mem.split(input, "\n\n");
    const required_keys = [_][]const u8{ "byr", "iyr", "eyr", "hgt", "hcl", "ecl", "pid", "cid" };
    const validation_funcs = [required_keys.len]?fn ([]const u8) bool{
        intChecker(1920, 2002, 4, null),
        intChecker(2010, 2020, 4, null),
        intChecker(2020, 2030, 4, null),
        combineOr(comptime intChecker(150, 193, 3, "cm"), comptime intChecker(59, 76, 2, "in")),
        isColorStr,
        isEyeColor,
        intChecker(0, 999999999, 9, null),
        null,
    };
    var count: u16 = 0;
    entryloop: while (entryit.next()) |entry| {
        const key_mask = [required_keys.len]u8{ 1, 1, 1, 1, 1, 1, 1, 'X' };
        var present = [required_keys.len]u1{ 0, 0, 0, 0, 0, 0, 0, 0 };
        var partit = std.mem.tokenize(entry, ": \n");
        while (partit.next()) |key| {
            const value = partit.next().?;
            for (required_keys) |ckey, i| {
                if (std.mem.eql(u8, key, ckey)) {
                    if (validate and validation_funcs[i] != null) {
                        if (!validation_funcs[i].?(value)) continue :entryloop;
                    }
                    present[i] = 1;
                }
            }
        }
        for (key_mask) |k, i| {
            if (key_mask[i] != 'X' and present[i] != key_mask[i])
                continue :entryloop;
        }
        count += 1;
    }
    return count;
}

fn part1(allocator: *std.mem.Allocator, input: []u8, args: [][]u8) !void {
    std.debug.print("{}\n", .{try countValids(allocator, input, false)});
}

fn part2(allocator: *std.mem.Allocator, input: []u8, args: [][]u8) !void {
    std.debug.print("{}\n", .{try countValids(allocator, input, true)});
}

pub const main = aoc.gen_main(part1, part2);
