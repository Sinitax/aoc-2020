// Own twist on https://en.wikipedia.org/wiki/Shunting-yard_algorithm

const std = @import("std");
const aoc = @import("aoc");

const OpType = enum { ADD, MULT, COUNT };
const Op = struct {
    prio: u32, optype: OpType
};
const Item = union(enum) {
    num: i64, op: OpType
};

const op_names = [_][]const u8{ "ADD", "MULT" };

fn printStack(stack: []Item) void {
    for (stack) |item| {
        switch (item) {
            .op => std.debug.print("{} ", .{op_names[@enumToInt(item.op)]}),
            .num => std.debug.print("{} ", .{item.num}),
        }
    }
    std.debug.print("\n", .{});
}

fn parseToken(line: []const u8, i: *usize, depth: *u32, op_prio: []const u32, mathstack: *std.ArrayList(Item), opstack: *std.ArrayList(Op)) !bool {
    if (i.* > line.len) {
        return false;
    } else if (i.* == line.len) {
        while (opstack.items.len > 0)
            try mathstack.append(Item{ .op = opstack.pop().optype });
    } else {
        const c = line[i.*];
        switch (c) {
            '+', '*' => {
                const optype = switch (c) {
                    '+' => OpType.ADD,
                    '*' => OpType.MULT,
                    else => unreachable,
                };
                const prio = depth.* * @enumToInt(OpType.COUNT) + op_prio[@enumToInt(optype)];
                while (opstack.items.len > 0 and
                    opstack.items[opstack.items.len - 1].prio >= prio)
                {
                    try mathstack.append(Item{ .op = opstack.pop().optype });
                }
                try opstack.append(Op{ .optype = optype, .prio = prio });
            },
            '(' => depth.* += 1,
            ')' => depth.* -= 1,
            ' ' => {},
            else => {
                // in this case we know that every number is one digit..
                // crappy zig parseInt requires span of exact int size
                // before we even know the format >:(((
                const val = try std.fmt.parseInt(i64, line[i.* .. i.* + 1], 10);
                try mathstack.append(Item{ .num = val });
            },
        }
    }
    i.* += 1;
    return true;
}

fn reduceStack(mathstack: *std.ArrayList(Item), opstack: *std.ArrayList(Op), tmpstack: *std.ArrayList(Item)) !void {
    while (mathstack.items.len > 0) {
        while (mathstack.items[mathstack.items.len - 1] != .op and
            tmpstack.items.len > 0)
        {
            try mathstack.append(tmpstack.pop());
        }
        if (mathstack.items.len < 3 or mathstack.items[mathstack.items.len - 1] != .op)
            break;
        const op = mathstack.pop();

        // get first arg
        if (mathstack.items[mathstack.items.len - 1] != .num) {
            try tmpstack.append(op);
            continue;
        }
        const a = mathstack.pop();

        // get second arg
        if (mathstack.items[mathstack.items.len - 1] != .num) {
            try tmpstack.append(op);
            try tmpstack.append(a);
            continue;
        }
        const b = mathstack.pop();

        const result: i64 = switch (op.op) {
            OpType.ADD => a.num + b.num,
            OpType.MULT => a.num * b.num,
            else => unreachable,
        };
        try mathstack.append(Item{ .num = result });
    }
}

fn printRPN(allocator: *std.mem.Allocator, input: []u8, prios: []const u32) !void {
    var mathstack = std.ArrayList(Item).init(allocator);
    defer mathstack.deinit();

    var opstack = std.ArrayList(Op).init(allocator);
    defer opstack.deinit();

    var lineit = std.mem.tokenize(input, "\n");
    while (lineit.next()) |line| {
        var depth: u32 = 0;
        var i: usize = 0;
        while (try parseToken(line, &i, &depth, prios, &mathstack, &opstack)) {}
    }

    printStack(mathstack.items);
}

fn partProto(allocator: *std.mem.Allocator, input: []u8, prios: []const u32) !void {
    var answer: i64 = 0;

    if (aoc.debug) {
        std.debug.print("Reverse Polish Notation:\n", .{});
        try printRPN(allocator, input, prios);
    }

    var mathstack = std.ArrayList(Item).init(allocator);
    defer mathstack.deinit();

    var opstack = std.ArrayList(Op).init(allocator);
    defer opstack.deinit();

    var tmpstack = std.ArrayList(Item).init(allocator);
    defer tmpstack.deinit();

    var lineit = std.mem.tokenize(input, "\n");
    while (lineit.next()) |line| {
        var depth: u32 = 0;
        var i: usize = 0;
        while (try parseToken(line, &i, &depth, prios, &mathstack, &opstack)) {
            try reduceStack(&mathstack, &opstack, &tmpstack);
        }

        if (mathstack.items.len != 1) return aoc.Error.InvalidInput;
        const last = mathstack.items[mathstack.items.len - 1];
        if (last != .num) return aoc.Error.InvalidInput;
        answer += last.num;

        try mathstack.resize(0);
        try opstack.resize(0);
        try tmpstack.resize(0);
    }

    std.debug.print("{}\n", .{answer});
}

fn part1(allocator: *std.mem.Allocator, input: []u8, args: [][]u8) !void {
    const prios = [_]u32{ 1, 1 };
    try partProto(allocator, input, prios[0..]);
}

fn part2(allocator: *std.mem.Allocator, input: []u8, args: [][]u8) !void {
    const prios = [_]u32{ 2, 1 };
    try partProto(allocator, input, prios[0..]);
}

test "unions" {
    const item1 = Item{ .op = OpType.MULT };
    const item2 = Item{ .num = 1000 };
    const expect = std.testing.expect;
    expect(item1 == .op);
    expect(item2 == .num);
}

pub const main = aoc.gen_main(part1, part2);
