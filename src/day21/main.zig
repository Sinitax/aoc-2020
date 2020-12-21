const std = @import("std");
const aoc = @import("aoc");

const hasher = std.hash.CityHash32;
const IngredientInfo = struct {
    count: u32,
};
const Pair = struct { ingredient: []const u8, allergen: []const u8 };

fn freeListmap(listmap: *std.AutoHashMap(u32, std.ArrayList(u32))) void {
    var mapit = listmap.iterator();
    while (mapit.next()) |kv| {
        kv.value.deinit();
    }
    listmap.deinit();
}

fn getAllergen(allergens: *std.AutoHashMap(u32, std.ArrayList(u32)), ingredient: u32) ?u32 {
    var allergenit = allergens.iterator();
    while (allergenit.next()) |alg| {
        if (alg.value.items.len == 1 and alg.value.items[0] == ingredient)
            return alg.key;
    }
    return null;
}

fn updateAllergens(allocator: *std.mem.Allocator, allergens: *std.AutoHashMap(u32, std.ArrayList(u32)), allergen: u32) !void {
    var next = std.ArrayList(u32).init(allocator);
    defer next.deinit();

    try next.append(allergen);

    while (next.items.len > 0) {
        const key = next.items[0];
        var ingredient = allergens.getEntry(key).?.value.items[0];
        var mapit = allergens.iterator();
        while (mapit.next()) |alg| {
            if (alg.key == key) continue;
            const ind = std.mem.indexOfScalar(u32, alg.value.items, ingredient);
            if (ind != null) {
                _ = alg.value.swapRemove(ind.?);
                if (alg.value.items.len == 1) {
                    try next.append(alg.key);
                }
            }
        }
        _ = next.swapRemove(0);
    }
}

fn parseAllergens(allocator: *std.mem.Allocator, allergens: *std.AutoHashMap(u32, std.ArrayList(u32)), unhash: *std.AutoHashMap(u32, []const u8), ingredient_counts: *std.AutoHashMap(u32, u32), input: []const u8) !void {
    var ingredients = std.ArrayList(u32).init(allocator);
    defer ingredients.deinit();

    var lineit = std.mem.tokenize(input, "\n");
    while (lineit.next()) |line| {
        var allergen = false;

        try ingredients.resize(0);

        var spaceit = std.mem.tokenize(line, " ");
        while (spaceit.next()) |word| {
            if (std.mem.eql(u8, word, "(contains")) {
                allergen = true;
                continue;
            }

            if (allergen) {
                const allergen_name = if (word[word.len - 1] == ')' or word[word.len - 1] == ',') word[0 .. word.len - 1] else word;
                const allergen_hash = hasher.hash(allergen_name);
                try unhash.put(allergen_hash, allergen_name);
                var algentry = allergens.getEntry(allergen_hash);
                if (algentry) |algent| {
                    var i: u32 = 0;
                    while (i < algent.value.items.len) {
                        if (std.mem.indexOfScalar(u32, ingredients.items, algent.value.items[i]) == null) {
                            _ = algent.value.swapRemove(i);
                        } else {
                            i += 1;
                        }
                    }

                    if (algent.value.items.len == 1) {
                        try updateAllergens(allocator, allergens, algent.key);
                    }
                } else {
                    var copy = std.ArrayList(u32).init(allocator);
                    errdefer copy.deinit();
                    for (ingredients.items) |ing| {
                        if (getAllergen(allergens, ing) == null) {
                            try copy.append(ing);
                        }
                    }
                    try allergens.put(allergen_hash, copy);
                }
            } else {
                const ingredient_hash = hasher.hash(word);
                try unhash.put(ingredient_hash, word);
                try ingredients.append(ingredient_hash);
                const entry = ingredient_counts.getEntry(ingredient_hash);
                if (entry == null) {
                    try ingredient_counts.put(ingredient_hash, 1);
                } else {
                    entry.?.value += 1;
                }
            }
        }
    }
}

fn ascendingAllergen(ctx: void, p1: Pair, p2: Pair) bool {
    var i: u32 = 0;
    while (i < std.math.min(p1.allergen.len, p2.allergen.len) and p1.allergen[i] == p2.allergen[i]) : (i += 1) {}
    return p1.allergen[i] < p2.allergen[i];
}

fn part1(allocator: *std.mem.Allocator, input: []u8, args: [][]u8) !void {
    var allergens = std.AutoHashMap(u32, std.ArrayList(u32)).init(allocator);
    defer freeListmap(&allergens);

    var ingredient_counts = std.AutoHashMap(u32, u32).init(allocator);
    defer ingredient_counts.deinit();

    var unhash = std.AutoHashMap(u32, []const u8).init(allocator);
    defer unhash.deinit();

    try parseAllergens(allocator, &allergens, &unhash, &ingredient_counts, input);

    var answer: u32 = 0;

    var algit = allergens.iterator();
    while (algit.next()) |alg| {
        std.debug.print("{} - ", .{alg.key});
        for (alg.value.items) |v| {
            std.debug.print("{} ", .{v});
        }
        std.debug.print("\n", .{});
    }

    var mapit = ingredient_counts.iterator();
    while (mapit.next()) |kv| {
        if (getAllergen(&allergens, kv.key) == null) answer += kv.value;
    }

    std.debug.print("{}\n", .{answer});
}

fn part2(allocator: *std.mem.Allocator, input: []u8, args: [][]u8) !void {
    var allergens = std.AutoHashMap(u32, std.ArrayList(u32)).init(allocator);
    defer freeListmap(&allergens);

    var ingredient_counts = std.AutoHashMap(u32, u32).init(allocator);
    defer ingredient_counts.deinit();

    var unhash = std.AutoHashMap(u32, []const u8).init(allocator);
    defer unhash.deinit();

    try parseAllergens(allocator, &allergens, &unhash, &ingredient_counts, input);

    var pairs = std.ArrayList(Pair).init(allocator);
    defer pairs.deinit();

    var mapit = ingredient_counts.iterator();
    while (mapit.next()) |kv| {
        const alg = getAllergen(&allergens, kv.key);
        if (alg != null) {
            try pairs.append(Pair{ .ingredient = unhash.get(kv.key).?, .allergen = unhash.get(alg.?).? });
        }
    }

    std.sort.sort(Pair, pairs.items, {}, ascendingAllergen);

    for (pairs.items) |p, i| {
        if (i > 0) std.debug.print(",", .{});
        std.debug.print("{}", .{p.ingredient});
    }
    std.debug.print("\n", .{});
}

pub const main = aoc.gen_main(part1, part2);
