const std = @import("std");
const aoc = @import("aoc");

const tile_width: u32 = 10;
const Tile = struct {
    id: u32,
    data: [tile_width * tile_width]u1,
    sides: [4][tile_width]u1, // NOTE: update these values when placed accordingly
    adj: [4]?usize,
    pos: aoc.Pos,
};
const Flip = enum { NONE, HOR, VERT };
const flips = [_]Flip{ Flip.NONE, Flip.HOR, Flip.VERT };

const seamonster = [_][]const u8{
    "                  # ",
    "#    ##    ##    ###",
    " #  #  #  #  #  #   ",
};

const dirs = [4]aoc.Pos{
    aoc.Pos{ .x = 0, .y = -1 },
    aoc.Pos{ .x = 1, .y = 0 },
    aoc.Pos{ .x = 0, .y = 1 },
    aoc.Pos{ .x = -1, .y = 0 },
};

fn printGrid(tiles: []Tile, grid: []?usize, grid_width: u32) void {
    var y: u32 = 0;
    while (y < grid_width * tile_width) : (y += 1) {
        var x: u32 = 0;
        if (y > 0 and y % tile_width == 0) std.debug.print("\n", .{});
        while (x < grid_width * tile_width) : (x += 1) {
            if (x > 0 and x % tile_width == 0) std.debug.print(" ", .{});
            var tile_index: ?usize = grid[@divFloor(y, tile_width) * grid_width + @divFloor(x, tile_width)];
            if (tile_index) |ti| {
                var tile = tiles[tile_index.?];
                var c: u8 = if (tile.data[(y % tile_width) * tile_width + (x % tile_width)] == 1) '#' else '.';
                std.debug.print("{c}", .{c});
            } else {
                std.debug.print("?", .{});
            }
        }
        std.debug.print("\n", .{});
    }
    std.debug.print("\n\n", .{});
}

fn printTile(data: []u1, width: u32) void {
    var y: u32 = 0;
    while (y < width) : (y += 1) {
        printTileSlice(data[y * width .. (y + 1) * width]);
        std.debug.print("\n", .{});
    }
}

fn printTileSlice(slice: []const u1) void {
    var i: u32 = 0;
    while (i < slice.len) : (i += 1) {
        var c: u8 = if (slice[i] == 1) '#' else '.';
        std.debug.print("{c}", .{c});
    }
}

fn couldMatch(side1: [tile_width]u1, side2: [tile_width]u1) bool {
    var side1_cpy = side1;
    if (std.mem.eql(u1, side1_cpy[0..], side2[0..])) return true;
    std.mem.reverse(u1, side1_cpy[0..]);
    if (std.mem.eql(u1, side1_cpy[0..], side2[0..])) return true;
    return false;
}

fn parseTiles(tiles: *std.ArrayList(Tile), input: []u8) !void {
    var tileit = std.mem.split(input, "\n\n");
    while (tileit.next()) |tilestr| {
        if (tilestr.len <= 1) continue;
        var tile: Tile = undefined;
        var lineit = std.mem.tokenize(tilestr, "\n");

        // read tile id
        var numstr = (try aoc.assertV(lineit.next()))[5..9];
        tile.id = try std.fmt.parseInt(u32, numstr, 10);

        // read tile data
        var i: u32 = 0;
        var line: []const u8 = undefined;
        while (i < tile_width * tile_width) : (i += 1) {
            if (i % tile_width == 0) line = try aoc.assertV(lineit.next());
            tile.data[i] = @boolToInt(line[i % tile_width] == '#');
        }

        // read side bits
        i = 0;
        while (i < 4) : (i += 1) {
            var sidebits: [tile_width]u1 = undefined;
            for (sidebits) |_, k| {
                sidebits[k] = switch (i) {
                    @enumToInt(aoc.Dir.Name.NORTH) => tile.data[k],
                    @enumToInt(aoc.Dir.Name.WEST) => tile.data[(tile_width - 1 - k) * tile_width],
                    @enumToInt(aoc.Dir.Name.EAST) => tile.data[tile_width - 1 + k * tile_width],
                    @enumToInt(aoc.Dir.Name.SOUTH) => tile.data[tile_width * tile_width - 1 - k],
                    else => unreachable,
                };
            }
            tile.sides[i] = sidebits;
        }

        // init misc data
        tile.adj = [_]?usize{ null, null, null, null };

        try tiles.append(tile);
    }
}

fn matchTiles(tiles: *std.ArrayList(Tile)) void {
    // for each items's side, look for another item with a matching side
    for (tiles.items) |*tile, tile_index| {
        sides_loop: for (tile.sides) |_, i| {
            for (tiles.items) |*otile, otile_index| {
                if (tile_index == otile_index) continue;

                for (otile.sides) |_, oi| {
                    if (tile.adj[i] == null and otile.adj[oi] == null and couldMatch(tile.sides[i], otile.sides[oi])) {
                        tile.adj[i] = otile_index;
                        otile.adj[oi] = tile_index;
                        continue :sides_loop;
                    }
                }
            }
        }

        if (aoc.debug) {
            std.debug.print("{}:\nSIDES ", .{tile.id});
            for (tile.sides) |side| {
                for (side) |b| {
                    var c: u8 = if (b == 1) '#' else '.';
                    std.debug.print("{c}", .{c});
                }
                std.debug.print(" ", .{});
            }
            std.debug.print("\n", .{});
            for (tile.adj) |adj, i| {
                if (tile.adj[i] == null) {
                    std.debug.print("null ", .{});
                } else {
                    var adjtile = tiles.items[adj.?];
                    std.debug.print("{} ", .{adjtile.id});
                }
            }
            std.debug.print("\n\n", .{});
        }
    }
}

fn checkSides(tiles: []Tile, grid: []?usize, grid_width: u32, p: aoc.Pos, adj: [4]?usize, sides: [4][10]u1) bool {
    var rot: u32 = 0;
    while (rot < 4) : (rot += 1) {
        const np = p.add(dirs[rot]);
        std.debug.print("{}\n", .{@intToEnum(aoc.Dir.Name, @intCast(u2, rot))});
        std.debug.print("{} {}\n", .{ np.x, np.y });

        var side: ?[tile_width]u1 = undefined;
        if (np.x < 0 or np.x >= grid_width or np.y < 0 or np.y >= grid_width) {
            std.debug.print("Side is null\n", .{});
            if (adj[rot] == null) {
                continue;
            } else {
                std.debug.print("Side {} should be NULL!\n", .{@intToEnum(aoc.Dir.Name, @intCast(u2, rot))});
                return false;
            }
        }

        var ti: ?usize = grid[@intCast(u32, np.y * @intCast(i64, grid_width) + np.x)] orelse continue;

        var otherside = tiles[ti.?].sides[aoc.Dir.nextCW(rot, 2)];
        std.mem.reverse(u1, otherside[0..]);
        printTileSlice(otherside[0..]);
        std.debug.print(" vs ", .{});
        printTileSlice(sides[rot][0..]);
        std.debug.print("\n", .{});

        if (!std.mem.eql(u1, otherside[0..], sides[rot][0..])) return false;
    }
    return true;
}

fn rotateData(newdata: *[]u1, olddata: []u1, width: u32, rot: usize) void {
    for (olddata) |v, di| {
        const dy = @divFloor(di, width);
        const dx = di % width;
        var nx = dx;
        var ny = dy;
        switch (rot) {
            @enumToInt(aoc.Dir.Name.NORTH) => {},
            @enumToInt(aoc.Dir.Name.EAST) => {
                nx = width - 1 - dy;
                ny = dx;
            },
            @enumToInt(aoc.Dir.Name.SOUTH) => {
                nx = width - 1 - dx;
                ny = width - 1 - dy;
            },
            @enumToInt(aoc.Dir.Name.WEST) => {
                nx = dy;
                ny = width - 1 - dx;
            },
            else => {},
        }
        newdata.*[ny * width + nx] = v;
    }
}

fn flipData(data: []u1, width: u32, flip: Flip) void {
    switch (flip) {
        Flip.HOR => {
            var y: u32 = 0;
            while (y < width) : (y += 1) {
                std.mem.reverse(u1, data[y * width .. (y + 1) * width]);
            }
        },
        Flip.VERT => {
            var x: u32 = 0;
            while (x < width) : (x += 1) {
                var y: u32 = 0;
                while (y < width / 2) : (y += 1) {
                    std.mem.swap(u1, &data[x + y * width], &data[x + (width - 1 - y) * width]);
                }
            }
        },
        else => {},
    }
}

fn manipulateAndPlace(allocator: *std.mem.Allocator, tiles: []Tile, grid: []?usize, grid_width: u32, p: aoc.Pos, tile_index: usize) !void {
    var tile = &tiles[tile_index];

    for (dirs) |_, rot| {
        for (flips) |flip| {
            // apply manipulation to only sides first for checking
            var sides = tile.sides;
            var tmp_sides = tile.sides;
            var adj = tile.adj;
            var tmp_adj = tile.adj;
            switch (flip) {
                Flip.HOR => {
                    std.mem.reverse(u1, tmp_sides[@enumToInt(aoc.Dir.Name.NORTH)][0..]);
                    std.mem.reverse(u1, tmp_sides[@enumToInt(aoc.Dir.Name.SOUTH)][0..]);
                    tmp_sides[@enumToInt(aoc.Dir.Name.WEST)] = sides[@enumToInt(aoc.Dir.Name.EAST)];
                    tmp_sides[@enumToInt(aoc.Dir.Name.EAST)] = sides[@enumToInt(aoc.Dir.Name.WEST)];
                    std.mem.reverse(u1, tmp_sides[@enumToInt(aoc.Dir.Name.EAST)][0..]);
                    std.mem.reverse(u1, tmp_sides[@enumToInt(aoc.Dir.Name.WEST)][0..]);
                    std.mem.swap(?usize, &adj[@enumToInt(aoc.Dir.Name.EAST)], &adj[@enumToInt(aoc.Dir.Name.WEST)]);
                },
                Flip.VERT => {
                    std.mem.reverse(u1, tmp_sides[@enumToInt(aoc.Dir.Name.WEST)][0..]);
                    std.mem.reverse(u1, tmp_sides[@enumToInt(aoc.Dir.Name.EAST)][0..]);
                    tmp_sides[@enumToInt(aoc.Dir.Name.NORTH)] = sides[@enumToInt(aoc.Dir.Name.SOUTH)];
                    tmp_sides[@enumToInt(aoc.Dir.Name.SOUTH)] = sides[@enumToInt(aoc.Dir.Name.NORTH)];
                    std.mem.reverse(u1, tmp_sides[@enumToInt(aoc.Dir.Name.NORTH)][0..]);
                    std.mem.reverse(u1, tmp_sides[@enumToInt(aoc.Dir.Name.SOUTH)][0..]);
                    std.mem.swap(?usize, &adj[@enumToInt(aoc.Dir.Name.NORTH)], &adj[@enumToInt(aoc.Dir.Name.SOUTH)]);
                },
                else => {},
            }
            sides = tmp_sides;

            for (dirs) |_, i| {
                tmp_sides[i] = sides[aoc.Dir.nextCCW(i, rot)];
                tmp_adj[i] = adj[aoc.Dir.nextCCW(i, rot)];
            }

            std.debug.print("\nROT: {}\n", .{rot});
            std.debug.print("FLIP: {}\n", .{flip});
            std.debug.print("SIDES: \n", .{});
            for (tmp_sides) |side| {
                printTileSlice(side[0..]);
                std.debug.print("\n", .{});
            }
            const valid = checkSides(tiles, grid, grid_width, p, tmp_adj, tmp_sides);

            // now apply manipulations to image data
            if (valid) {
                // for (tile.sides) |side| {
                //     printTileSlice(side[0..]);
                //     std.debug.print("\n", .{});
                // }
                std.debug.print("{} {} {}\n", .{ tile.id, flip, rot });
                printTile(tile.data[0..], tile_width);
                std.debug.print("\n", .{});
                tile.sides = tmp_sides;
                tile.pos = p;
                tile.adj = tmp_adj;
                grid[@intCast(u32, p.y * @intCast(i64, grid_width) + p.x)] = tile_index;

                flipData(tile.data[0..], tile_width, flip);

                var newdata = try allocator.alloc(u1, tile_width * tile_width);
                defer allocator.free(newdata);

                rotateData(&newdata, tile.data[0..], tile_width, rot);
                std.mem.copy(u1, tile.data[0..], newdata);
                return;
            }
        }
    }
    return aoc.Error.InvalidInput;
}

fn part1(allocator: *std.mem.Allocator, input: []u8, args: [][]u8) !void {
    var tiles = std.ArrayList(Tile).init(allocator);
    defer tiles.deinit();

    try parseTiles(&tiles, input);

    matchTiles(&tiles);

    var answer: u64 = 1;
    for (tiles.items) |tile| {
        var unknown: u32 = 0;
        for (tile.adj) |v| {
            unknown += @boolToInt(v == null);
        }
        if (unknown == 2) answer *= tile.id;
    }

    std.debug.print("{}\n", .{answer});
}

fn part2(allocator: *std.mem.Allocator, input: []u8, args: [][]u8) !void {
    var tiles = std.ArrayList(Tile).init(allocator);
    defer tiles.deinit();

    try parseTiles(&tiles, input);

    matchTiles(&tiles);

    var grid = try allocator.alloc(?usize, tiles.items.len);
    defer allocator.free(grid);
    var grid_width = @intCast(u32, std.math.sqrt(tiles.items.len));

    var left = std.ArrayList(usize).init(allocator);
    defer left.deinit();

    for (tiles.items) |_, tile_index| {
        try left.append(tile_index);
    }

    // add a corner as first item to add onto
    for (tiles.items) |tile, tile_index| {
        var unknown: u32 = 0;
        for (tile.adj) |v| {
            unknown += @boolToInt(v == null);
        }
        if (unknown == 2) {
            try manipulateAndPlace(allocator, tiles.items, grid, grid_width, aoc.Pos{ .x = 0, .y = 0 }, tile_index);
            _ = left.swapRemove(tile_index);
            break;
        }
    }

    // find adjacents and manipulate until they fit
    next_tile: while (left.items.len > 0) {
        if (aoc.debug) printGrid(tiles.items, grid, grid_width);

        for (grid) |_, gi| {
            std.debug.print("POS {}\n", .{gi});
            const tile_index: ?usize = grid[gi] orelse continue;
            std.debug.print("POS {} YES\n", .{gi});

            var placed = &tiles.items[tile_index.?];
            for (placed.adj) |want, dir| {
                if (want == null) continue;
                // std.debug.print("LOOKING FOR {}\n", .{want.?});
                // for (left.items) |item| {
                //     std.debug.print("> {}\n", .{item});
                // }
                if (std.mem.indexOfScalar(usize, left.items, want.?)) |left_index| {
                    const new_index = left.items[left_index];
                    const new_tile = tiles.items[new_index];
                    var npos = placed.pos.add(dirs[dir]);
                    std.debug.print("TRYING TO PLACE {} NEW AT: {} {}\n", .{ new_tile.id, npos.x, npos.y });

                    try manipulateAndPlace(allocator, tiles.items, grid, grid_width, npos, new_index);

                    _ = left.swapRemove(left_index);
                    continue :next_tile;
                }
            }
        }
        return aoc.Error.InvalidInput;
    }

    if (aoc.debug) printGrid(tiles.items, grid, grid_width);

    // convert grid to image
    var image = try allocator.alloc(u1, grid.len * (tile_width - 2) * (tile_width - 2));
    defer allocator.free(image);

    const image_width = grid_width * (tile_width - 2);
    var y: u32 = 0;
    while (y < grid_width) : (y += 1) {
        var x: u32 = 0;
        while (x < grid_width) : (x += 1) {
            var tile = tiles.items[grid[y * grid_width + x].?];
            var doff = (y * grid_width * (tile_width - 2) + x) * (tile_width - 2);
            var dy: u32 = 1;
            while (dy < tile_width - 1) : (dy += 1) {
                var dx: u32 = 1;
                while (dx < tile_width - 1) : (dx += 1) {
                    image[doff + (dy - 1) * image_width + (dx - 1)] = tile.data[dy * tile_width + dx];
                }
            }
        }
    }

    y = 0;
    while (y < grid_width * (tile_width - 2)) : (y += 1) {
        printTileSlice(image[y * grid_width * (tile_width - 2) .. (y + 1) * grid_width * (tile_width - 2)]);
        std.debug.print("\n", .{});
    }

    // rotate image till we find a sea monster
    var image_copy = try allocator.dupe(u1, image);
    defer allocator.free(image_copy);

    var rot: usize = 0;
    while (rot < 4) : (rot += 1) {
        for (flips) |flip| {
            flipData(image, image_width, flip);
            rotateData(&image_copy, image, image_width, rot);

            y = 0;
            var count: u32 = 0;
            while (y < image_width - seamonster.len) : (y += 1) {
                var x: u32 = 0;
                check_next: while (x < image_width - seamonster[0].len) : (x += 1) {
                    var sy: u32 = 0;
                    while (sy < seamonster.len) : (sy += 1) {
                        var sx: u32 = 0;
                        while (sx < seamonster[0].len) : (sx += 1) {
                            if (seamonster[sy][sx] == '#' and image_copy[(y + sy) * image_width + (x + sx)] != 1)
                                continue :check_next;
                        }
                    }
                    count += 1;
                }
            }

            if (count > 0) {
                var image_count = std.mem.count(u1, image_copy, ([_]u1{1})[0..]);
                var seamonster_count: usize = 0;
                var sy: u32 = 0;
                while (sy < seamonster.len) : (sy += 1) {
                    seamonster_count += std.mem.count(u8, seamonster[sy], "#");
                }
                std.debug.print("{}\n", .{image_count - count * seamonster_count});
                return;
            }
        }
    }
}

pub const main = aoc.gen_main(part1, part2);
