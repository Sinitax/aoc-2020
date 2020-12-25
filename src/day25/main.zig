const std = @import("std");
const aoc = @import("aoc");

fn transform(subject_num: u64, loops: u64) u64 {
    var num: u64 = 1;
    var i: u64 = 0;
    while (i < loops) : (i += 1) {
        num *= subject_num;
        num %= 20201227;
    }
    return num;
}

fn bfLoops(subject_num: u64, pubkey: u64) ?u64 {
    var i: u64 = 0;
    var tmp: u64 = 1;
    while (i < ~@as(u64, 0)) : (i += 1) {
        if (tmp == pubkey) return i;
        tmp *= subject_num;
        tmp %= 20201227;
    }
    return null;
}

fn parseInput(door_pubkey: *u64, card_pubkey: *u64, input: []const u8) !void {
    var lineit = std.mem.tokenize(input, "\n");
    door_pubkey.* = try std.fmt.parseInt(u64, try aoc.assertV(lineit.next()), 10);
    card_pubkey.* = try std.fmt.parseInt(u64, try aoc.assertV(lineit.next()), 10);
}

fn part1(allocator: *std.mem.Allocator, input: []u8, args: [][]u8) !void {
    var door_pubkey: u64 = undefined;
    var card_pubkey: u64 = undefined;

    try parseInput(&door_pubkey, &card_pubkey, input);

    if (args.len == 0 or std.mem.eql(u8, args[0], "bf_door")) {
        if (bfLoops(7, door_pubkey)) |door_loops| {
            std.debug.print("{}\n", .{transform(card_pubkey, door_loops)});
            return;
        }
    } else if (args.len > 0 and std.mem.eql(u8, args[0], "bf_card")) {
        if (bfLoops(7, card_pubkey)) |card_loops| {
            std.debug.print("{}\n", .{transform(door_pubkey, card_loops)});
            return;
        }
    }
}

fn part2(allocator: *std.mem.Allocator, input: []u8, args: [][]u8) !void {
    var answer: u32 = 0;

    std.debug.print("{}\n", .{answer});
}

pub const main = aoc.gen_main(part1, part2);
