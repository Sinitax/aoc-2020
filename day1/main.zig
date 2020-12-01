const std = @import("std");
const ArrayList = std.ArrayList;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const heapalloc = &gpa.allocator;

const Parts = struct {
    a: i32, b: i32
};
fn findparts(intlist: ArrayList(i32), sum: i32) !Parts {
    var start: usize = 0;
    const items = intlist.items;
    var end: usize = items.len - 1;
    while (start != end) {
        const csum = items[start] + items[end];
        if (csum == sum) {
            return Parts{ .a = items[start], .b = items[end] };
        } else if (csum > sum) {
            end -= 1;
        } else {
            start += 1;
        }
    }
    return error.Error;
}

fn part1(intlist: ArrayList(i32), args: [][*:0]u8) !void {
    std.sort.sort(i32, intlist.items, {}, comptime std.sort.asc(i32));

    var parts = try findparts(intlist, 2020);
    std.debug.print("{}\n", .{parts.a * parts.b});
}

fn part2(intlist: ArrayList(i32), args: [][*:0]u8) !void {
    std.sort.sort(i32, intlist.items, {}, comptime std.sort.asc(i32));

    var third: u32 = 0;
    while (third < intlist.items.len) {
        var tmp = intlist.items[third];
        intlist.items[third] = -2020;
        var parts = findparts(intlist, 2020 - tmp) catch |err| {
            intlist.items[third] = tmp;
            third += 1;
            continue;
        };
        std.debug.print("{}\n", .{parts.a * parts.b * tmp});
        return;
    }
}

pub fn main() !void {
    if (std.os.argv.len < 2) return;

    var argv = std.os.argv;
    const file = try std.fs.cwd().openFile("input", .{});
    const reader = file.reader();

    var buf: [256]u8 = undefined;
    var intlist = ArrayList(i32).init(heapalloc);

    while (try reader.readUntilDelimiterOrEof(buf[0..], '\n')) |result| {
        try intlist.append(try std.fmt.parseInt(i32, result, 10));
    }

    if (std.mem.eql(u8, std.mem.span(argv[1]), "1")) {
        try part1(intlist, argv[2..]);
    } else if (std.mem.eql(u8, std.mem.span(argv[1]), "2")) {
        try part2(intlist, argv[2..]);
    }
}
