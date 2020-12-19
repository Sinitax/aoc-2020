const std = @import("std");
const aoc = @import("aoc");

const Rule = union(enum) {
    c: u8,
    combos: []const []const usize,
};

fn printSlice(slice: []const usize) void {
    for (slice) |v, i| {
        if (i > 0) {
            std.debug.print(" ", .{});
        }
        std.debug.print("{}", .{v});
    }
}

var stacktrace: std.ArrayList(usize) = undefined;

fn checkRule(rules: *std.AutoHashMap(usize, Rule), rid: usize, msg: []const u8, nextstack: *std.ArrayList(usize)) anyerror!bool {
    if (msg.len == 0) return true;
    const rule = rules.get(rid) orelse return aoc.Error.InvalidInput;

    if (rule == .c) {
        if (msg[0] != rule.c) return false;
        if (msg.len == 1) return (nextstack.items.len == 0);
        if (nextstack.items.len == 0) return false;

        const next = nextstack.pop();

        const valid = try checkRule(rules, next, msg[1..], nextstack);
        if (valid) try stacktrace.append(next);
        if (valid) return true;

        try nextstack.append(next);
    } else {
        for (rule.combos) |ruleseq| {
            try nextstack.appendSlice(ruleseq[1..]);
            std.mem.reverse(usize, nextstack.items[nextstack.items.len - (ruleseq.len - 1) ..]);

            const valid = try checkRule(rules, ruleseq[0], msg, nextstack);
            if (valid) try stacktrace.append(ruleseq[0]);
            if (valid) return true;

            try nextstack.resize(nextstack.items.len - (ruleseq.len - 1));
        }
    }
    return false;
}

fn freeRules(allocator: *std.mem.Allocator, rules: *std.AutoHashMap(usize, Rule), ignore: ?[]const usize) void {
    var mapit = rules.iterator();
    while (mapit.next()) |kv| {
        if (ignore != null and std.mem.indexOfScalar(usize, ignore.?, kv.key) != null) continue;
        if (kv.value == .combos) {
            for (kv.value.combos) |rs| {
                allocator.free(rs);
            }
            allocator.free(kv.value.combos);
        }
    }
    rules.deinit();
}

fn parseRule(allocator: *std.mem.Allocator, rules: *std.AutoHashMap(usize, Rule), line: []const u8) !void {
    const indexsep = try aoc.assertV(std.mem.indexOf(u8, line, ": "));
    const index = try std.fmt.parseInt(usize, line[0..indexsep], 10);

    var chrsep = std.mem.indexOf(u8, line, "\"");
    if (chrsep != null) {
        if (chrsep.? == line.len - 1) return aoc.Error.InvalidInput;
        try rules.put(index, Rule{ .c = line[chrsep.? + 1] });
    } else {
        var vals = std.ArrayList([]usize).init(allocator);
        errdefer vals.deinit();

        var ruleit = std.mem.split(line[indexsep + 2 ..], " | ");
        while (ruleit.next()) |r| {
            var ruleids = std.ArrayList(usize).init(allocator);
            errdefer ruleids.deinit();

            var spaceit = std.mem.tokenize(r, " ");
            while (spaceit.next()) |word| {
                try ruleids.append(try std.fmt.parseInt(usize, word, 10));
            }

            if (ruleids.items.len == 0) return aoc.Error.InvalidInput;

            try vals.append(ruleids.items);
        }

        try rules.put(index, Rule{ .combos = vals.items });
    }
}

fn part1(allocator: *std.mem.Allocator, input: []u8, args: [][]u8) !void {
    var rules = std.AutoHashMap(usize, Rule).init(allocator);
    defer freeRules(allocator, &rules, null);

    var partit = std.mem.split(input, "\n\n");

    var lineit = std.mem.tokenize(try aoc.assertV(partit.next()), "\n");
    while (lineit.next()) |line| {
        try parseRule(allocator, &rules, line);
    }

    var answer: u32 = 0;
    var nextstack = std.ArrayList(usize).init(allocator);
    defer nextstack.deinit();

    stacktrace = std.ArrayList(usize).init(allocator);
    defer stacktrace.deinit();

    lineit = std.mem.tokenize(try aoc.assertV(partit.next()), "\n");
    var count: usize = 0;
    while (lineit.next()) |line| {
        count += 1;
        if (try checkRule(&rules, 0, line, &nextstack))
            answer += 1;
        try nextstack.resize(0);
    }

    std.debug.print("{} / {} matching\n", .{ answer, count });
}

fn part2(allocator: *std.mem.Allocator, input: []u8, args: [][]u8) !void {
    var rules = std.AutoHashMap(usize, Rule).init(allocator);
    defer freeRules(allocator, &rules, ([_]usize{ 8, 11 })[0..]);

    var partit = std.mem.split(input, "\n\n");

    var lineit = std.mem.tokenize(try aoc.assertV(partit.next()), "\n");
    while (lineit.next()) |line| {
        if (std.mem.eql(u8, line[0..2], "8:")) {
            const p1: []const usize = ([_]usize{42})[0..];
            const p2: []const usize = ([_]usize{ 42, 8 })[0..];
            try rules.put(8, Rule{ .combos = ([_][]const usize{ p1, p2 })[0..] });
        } else if (std.mem.eql(u8, line[0..3], "11:")) {
            const p1: []const usize = ([_]usize{ 42, 31 })[0..];
            const p2: []const usize = ([_]usize{ 42, 11, 31 })[0..];
            try rules.put(11, Rule{ .combos = ([_][]const usize{ p1, p2 })[0..] });
        } else {
            try parseRule(allocator, &rules, line);
        }
    }

    var answer: u32 = 0;
    var nextstack = std.ArrayList(usize).init(allocator);
    defer nextstack.deinit();

    stacktrace = std.ArrayList(usize).init(allocator);
    defer stacktrace.deinit();

    var count: usize = 0;
    lineit = std.mem.tokenize(try aoc.assertV(partit.next()), "\n");
    while (lineit.next()) |line| {
        count += 1;
        const valid = try checkRule(&rules, 0, line, &nextstack);
        answer += @boolToInt(valid);
        if (aoc.debug) {
            std.debug.print("TRACE: [", .{});
            std.mem.reverse(usize, stacktrace.items);
            printSlice(stacktrace.items);
            std.debug.print("]\n", .{});
            if (valid) {
                std.debug.print("MATCH {}\n\n", .{line});
            } else {
                std.debug.print("NO MATCH {}\n\n", .{line});
            }
        }
        try nextstack.resize(0);
    }

    std.debug.print("{} / {} matching\n", .{ answer, count });
}

pub const main = aoc.gen_main(part1, part2);
