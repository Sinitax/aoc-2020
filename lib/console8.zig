const std = @import("std");

pub const OpError = error{ InstructionPointerOOB, InvalidFormat, InstructionUnknown };
pub const OpFuncSig = fn (ctx: *Console, arg: i64) OpError!void;
pub const Instruction = struct {
    opcode: []const u8, opfunc: OpFuncSig, argval: i64
};

pub const Console = struct {
    accumulator: i64 = 0,
    instructptr: u64 = 0,

    jumpAddr: i65 = 0,

    code: []const u8,
    instlist: [][]const u8,
    allocator: *std.mem.Allocator,
    const Self = @This();

    pub fn init(code: []const u8, allocator: *std.mem.Allocator) !Self {
        var instvec = std.ArrayList([]const u8).init(allocator);
        errdefer instvec.deinit();

        var instit = std.mem.tokenize(code, "\n");
        while (instit.next()) |inst| {
            try instvec.append(inst);
        }
        return Console{
            .code = code,
            .instlist = instvec.toOwnedSlice(),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Self) void {
        self.allocator.free(self.instlist);
    }

    pub fn reset(self: *Self) void {
        self.accumulator = 0;
        self.instructptr = 0;
    }

    const instructionMap = std.ComptimeStringMap(OpFuncSig, .{
        .{ "jmp", jumpInstruction },
        .{ "acc", accInstruction },
        .{ "nop", nopInstruction },
    });

    pub fn jumpInstruction(self: *Self, arg: i64) OpError!void {
        self.jumpAddr = @intCast(i65, self.instructptr) + @intCast(i65, arg);
        if (self.jumpAddr < 0 or self.jumpAddr >= self.instlist.len)
            return error.InstructionPointerOOB;
        self.instructptr = @intCast(u64, self.jumpAddr);
    }

    pub fn accInstruction(self: *Self, arg: i64) OpError!void {
        self.accumulator += arg;
        self.instructptr += 1;
    }

    pub fn nopInstruction(self: *Self, arg: i64) OpError!void {
        self.instructptr += 1;
    }

    pub fn parseNext(self: *Self) !?Instruction {
        if (self.instructptr >= self.instlist.len)
            return null;

        const inststr = self.instlist[self.instructptr];
        const sep = std.mem.indexOfScalar(u8, inststr, ' ');
        if (sep == null) return OpError.InvalidFormat;

        const opcode = inststr[0..sep.?];
        if (instructionMap.get(opcode)) |opfunc| {
            const arg = inststr[sep.? + 1 ..];
            const val = std.fmt.parseInt(i64, arg, 10) catch |err| {
                std.debug.print("Failed to parse arg value: {}\n", .{arg});
                return OpError.InvalidFormat;
            };
            return Instruction{ .opcode = opcode, .opfunc = opfunc, .argval = val };
        } else {
            std.debug.print("Unknown instruction: {}\n", .{inststr});
            return OpError.InstructionUnknown;
        }
    }

    pub fn exec(self: *Self, inst: *Instruction) !void {
        try inst.opfunc(self, inst.argval);
    }
};
