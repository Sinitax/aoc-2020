const std = @import("std");
pub const input = @import("input.zig");

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

            // read all input into mem (files are always small so no problem)
            const file = try std.fs.cwd().openFile("input", .{});
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
