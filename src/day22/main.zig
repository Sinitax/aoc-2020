const std = @import("std");
const aoc = @import("aoc");

const Player = enum { P1, P2 };
const GameResult = struct {
    score: u64, winner: Player
};

fn parseInput(input: []u8, decks: [2]*std.ArrayList(u32)) !void {
    var partit = std.mem.split(input, "\n\n");
    var decknum: u32 = 0;
    while (partit.next()) |part| : (decknum += 1) {
        if (decknum == 2) break;
        var lineit = std.mem.tokenize(part, "\n");
        _ = lineit.next();
        while (lineit.next()) |line| {
            try decks[decknum].append(try std.fmt.parseInt(u32, line, 10));
        }
    }
    if (decknum < 2) return aoc.Error.InvalidInput;
}

fn printDeck(deck: *std.ArrayList(u32)) void {
    for (deck.items) |v, i| {
        if (i > 0) std.debug.print(", ", .{});
        std.debug.print("{}", .{v});
    }
}

fn printRoundInfo(roundnum: u32, decks: [2]*std.ArrayList(u32)) void {
    std.debug.print("\n-- ROUND {} --\n", .{roundnum});
    std.debug.print("Player 1's deck: ", .{});
    printDeck(decks[0]);
    std.debug.print("\nPlayer 2's deck: ", .{});
    printDeck(decks[1]);
    std.debug.print("\n", .{});
}

fn printPickedCards(card1: u32, card2: u32) void {
    std.debug.print("Player 1 plays: {}\n", .{card1});
    std.debug.print("Player 2 plays: {}\n", .{card2});
}

fn calcScore(deck: *std.ArrayList(u32)) u64 {
    var score: u64 = 0;
    for (deck.items) |v, i| {
        score += v * (deck.items.len - i);
    }
    return score;
}

fn copyList(allocator: *std.mem.Allocator, list: []u32) !std.ArrayList(u32) {
    var newlist = std.ArrayList(u32).init(allocator);
    errdefer newlist.deinit();

    for (list) |v| {
        try newlist.append(v);
    }

    return newlist;
}

fn part1Round(
    allocator: *std.mem.Allocator,
    roundnum: u32,
    decks: [2]*std.ArrayList(u32),
) anyerror!void {
    if (aoc.debug) printRoundInfo(roundnum, decks);
    const card1: u32 = decks[0].orderedRemove(0);
    const card2: u32 = decks[1].orderedRemove(0);
    if (aoc.debug) printPickedCards(card1, card2);
    if (card1 > card2) {
        if (aoc.debug) std.debug.print("Player1 wins\n", .{});
        try decks[0].append(card1);
        try decks[0].append(card2);
    } else if (card2 > card1) {
        if (aoc.debug) std.debug.print("Player2 wins\n", .{});
        try decks[1].append(card2);
        try decks[1].append(card1);
    } else return aoc.Error.InvalidInput;
}

fn part2Round(
    allocator: *std.mem.Allocator,
    roundnum: u32,
    decks: [2]*std.ArrayList(u32),
) anyerror!void {
    if (aoc.debug) printRoundInfo(roundnum, decks);
    const card1: u32 = decks[0].orderedRemove(0);
    const card2: u32 = decks[1].orderedRemove(0);
    if (aoc.debug) printPickedCards(card1, card2);

    var winner = @intToEnum(Player, @boolToInt(card2 > card1));
    if (card1 <= decks[0].items.len and card2 <= decks[1].items.len) {
        if (aoc.debug) std.debug.print("\nStarting subgame..\n", .{});
        var tmp_deck1 = try copyList(allocator, decks[0].items[0..card1]);
        defer tmp_deck1.deinit();

        var tmp_deck2 = try copyList(allocator, decks[1].items[0..card2]);
        defer tmp_deck2.deinit();

        const result = try playGame(allocator, [2]*std.ArrayList(u32){ &tmp_deck1, &tmp_deck2 }, part2Round);
        winner = result.winner;
        if (aoc.debug) {
            const wp: u32 = if (winner == Player.P1) 1 else 2;
            std.debug.print("Player{} wins the subgame\n...anyway, back to previous game\n\n", .{wp});
        }
    }

    if (winner == Player.P1) {
        if (aoc.debug) std.debug.print("Player1 wins the round\n", .{});
        try decks[0].append(card1);
        try decks[0].append(card2);
    } else if (winner == Player.P2) {
        if (aoc.debug) std.debug.print("Player2 wins the round\n", .{});
        try decks[1].append(card2);
        try decks[1].append(card1);
    } else return aoc.Error.InvalidInput;
}

fn playGame(
    allocator: *std.mem.Allocator,
    decks: [2]*std.ArrayList(u32),
    roundFunc: fn (
        alloc: *std.mem.Allocator,
        num: u32,
        decks: [2]*std.ArrayList(u32),
    ) anyerror!void,
) !GameResult {
    var ctxstack = std.ArrayList(u64).init(allocator);
    defer ctxstack.deinit();

    var roundnum: u32 = 1;
    while (decks[0].items.len > 0 and decks[1].items.len > 0) : (roundnum += 1) {
        try roundFunc(allocator, roundnum, decks);

        var hash: u64 = calcScore(decks[0]) + 100000 * calcScore(decks[1]);
        if (std.mem.indexOfScalar(u64, ctxstack.items, hash) != null) {
            return GameResult{ .score = calcScore(decks[0]), .winner = Player.P1 };
        }

        try ctxstack.append(hash);
    }

    var nonempty = if (decks[0].items.len != 0) decks[0] else decks[1];
    return GameResult{
        .score = calcScore(nonempty),
        .winner = if (nonempty == decks[0]) Player.P1 else Player.P2,
    };
}

fn part1(allocator: *std.mem.Allocator, input: []u8, args: [][]u8) !void {
    var deck1 = std.ArrayList(u32).init(allocator);
    defer deck1.deinit();

    var deck2 = std.ArrayList(u32).init(allocator);
    defer deck2.deinit();

    const decks = [2]*std.ArrayList(u32){ &deck1, &deck2 };
    try parseInput(input, decks);

    const result = try playGame(allocator, decks, part1Round);
    std.debug.print("{}\n", .{result.score});
}

fn part2(allocator: *std.mem.Allocator, input: []u8, args: [][]u8) !void {
    var deck1 = std.ArrayList(u32).init(allocator);
    defer deck1.deinit();

    var deck2 = std.ArrayList(u32).init(allocator);
    defer deck2.deinit();

    const decks = [2]*std.ArrayList(u32){ &deck1, &deck2 };
    try parseInput(input, decks);

    const result = try playGame(allocator, decks, part2Round);
    std.debug.print("{}\n", .{result.score});
}

pub const main = aoc.gen_main(part1, part2);
