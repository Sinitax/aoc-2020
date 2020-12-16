const std = @import("std");
const aoc = @import("aoc");

const Range = struct { min: u32, max: u32 };
const FieldRule = struct { name: []const u8, r1: Range, r2: Range };

fn assert(comptime T: type, part: ?T) !T {
    if (part == null) return aoc.Error.InvalidInput;
    return part.?;
}

fn parseRange(str: []const u8) !Range {
    const sep = try assert(usize, std.mem.indexOfScalar(u8, str, '-'));
    if (sep == str.len - 1) return aoc.Error.InvalidInput;
    return Range{
        .min = try std.fmt.parseInt(u32, str[0..sep], 10),
        .max = try std.fmt.parseInt(u32, str[sep + 1 ..], 10),
    };
}

fn parseRules(rules: *std.ArrayList(FieldRule), str: []const u8) !void {
    var lineit = std.mem.tokenize(str, "\n");
    while (lineit.next()) |line| {
        const sep = try assert(usize, std.mem.indexOf(u8, line, ": "));
        if (sep == line.len - 1) return aoc.Error.InvalidInput;
        const name = line[0..sep];
        var rangepart = line[sep + 2 ..];
        var spaceit = std.mem.tokenize(rangepart, " ");
        const r1 = try parseRange(try assert([]const u8, spaceit.next()));
        _ = spaceit.next();
        const r2 = try parseRange(try assert([]const u8, spaceit.next()));
        try rules.append(FieldRule{ .name = name, .r1 = r1, .r2 = r2 });
    }
}

fn parseVals(vals: *std.ArrayList(u32), str: []const u8) !void {
    var lineit = std.mem.tokenize(str, "\n");
    while (lineit.next()) |line| {
        var partit = std.mem.tokenize(line, ",");
        while (partit.next()) |part| {
            try vals.append(try std.fmt.parseInt(u32, part, 10));
        }
    }
}

fn matchesRule(rule: FieldRule, v: u32) bool {
    return (v >= rule.r1.min and v <= rule.r1.max or v >= rule.r2.min and v <= rule.r2.max);
}

fn hasRule(rules: []FieldRule, v: u32) bool {
    for (rules) |r, i| {
        if (matchesRule(r, v)) return true;
    }
    return false;
}

fn printCandidates(candidates: []u1, rulecount: usize, remove: usize) void {
    var i: u32 = 0;
    while (i < rulecount) : (i += 1) {
        for (candidates[i * rulecount .. (i + 1) * rulecount]) |c| {
            std.debug.print("{} ", .{c});
        }
        if (i == remove) std.debug.print(" <<<", .{});
        std.debug.print("\n", .{});
    }
}

fn part1(allocator: *std.mem.Allocator, input: []u8, args: [][]u8) !void {
    var answer: u32 = 0;

    var rules = std.ArrayList(FieldRule).init(allocator);
    defer rules.deinit();

    var othervals = std.ArrayList(u32).init(allocator);
    defer othervals.deinit();

    var secit = std.mem.split(input, "\n\n");
    try parseRules(&rules, try assert([]const u8, secit.next()));
    _ = secit.next();
    try parseVals(&othervals, (try assert([]const u8, secit.next()))[16..]);

    for (othervals.items) |v| {
        if (!hasRule(rules.items, v)) answer += v;
    }

    std.debug.print("{}\n", .{answer});
}

fn part2(allocator: *std.mem.Allocator, input: []u8, args: [][]u8) !void {
    var rules = std.ArrayList(FieldRule).init(allocator);
    defer rules.deinit();

    var ownvals = std.ArrayList(u32).init(allocator);
    defer ownvals.deinit();

    var othervals = std.ArrayList(u32).init(allocator);
    defer othervals.deinit();

    var secit = std.mem.split(input, "\n\n");
    try parseRules(&rules, try assert([]const u8, secit.next()));
    try parseVals(&ownvals, (try assert([]const u8, secit.next()))[13..]);
    try parseVals(&othervals, (try assert([]const u8, secit.next()))[16..]);

    const rulecount = rules.items.len;

    {
        var index: u32 = 0;
        while (index < othervals.items.len) {
            const ri = index % rulecount;
            var i: u32 = 0;
            while (i < rulecount) : (i += 1) {
                if (!hasRule(rules.items, othervals.items[index + i]))
                    break;
            }

            if (i == rulecount) {
                index += @intCast(u32, rulecount);
            } else {
                if (aoc.debug)
                    std.debug.print("REMOVE: ", .{});
                i = 0;
                while (i < rulecount) : (i += 1) {
                    if (aoc.debug)
                        std.debug.print("{} ", .{othervals.items[index]});
                    _ = othervals.orderedRemove(index);
                }
                if (aoc.debug)
                    std.debug.print("\n", .{});
            }
        }
    }

    var candidates = try allocator.alloc(u1, rulecount * rulecount);
    defer allocator.free(candidates);
    std.mem.set(u1, candidates, 1);

    if (aoc.debug)
        std.debug.print("{}\n", .{othervals.items.len});
    {
        var index: u32 = 0;
        while (index < othervals.items.len) : (index += 1) {
            const ri = index % rulecount;
            const v = othervals.items[index];
            for (rules.items) |r, rri| {
                if (!matchesRule(r, v)) {
                    candidates[ri * rulecount + rri] = 0;
                }
            }
        }
    }

    var answer: u64 = 1;
    {
        var index: u32 = 0;
        while (index < rulecount * rulecount) : (index += 1) {
            var ri = index % rulecount;
            const cc = candidates[ri * rulecount .. (ri + 1) * rulecount];
            if (std.mem.count(u1, cc, ([_]u1{1})[0..]) == 1) {
                const field = std.mem.indexOfScalar(u1, cc, 1).?;
                if (std.mem.indexOf(u8, rules.items[field].name, "departure") != null)
                    answer *= ownvals.items[ri];
                for (ownvals.items) |_, ii| {
                    candidates[ii * rulecount + field] = 0;
                }
                if (aoc.debug) {
                    printCandidates(candidates, rulecount, ri);
                    std.debug.print("\n", .{});
                }
            }
        }
    }

    std.debug.print("{}\n", .{answer});
}

pub const main = aoc.gen_main(part1, part2);
