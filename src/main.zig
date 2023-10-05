// TODO:
//   x switch turn if one player can't play,
//   x implement end of game
//   - implement/show possible moves

//

const std = @import("std");

const stdout = std.io.getStdOut().writer();
const stdin = std.io.getStdIn().reader();
const expect = std.testing.expect;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const State = enum {
    white,
    black,
};

const XY = struct {
    u8,
    u8,
};

const Board = struct {
    cells: [64]?State = .{null} ** 64,
    turn: State = undefined,

    fn init() Board {
        var self = Board{};
        self.set(3, 3, .black);
        self.set(4, 3, .white);
        self.set(3, 4, .white);
        self.set(4, 4, .black);
        self.turn = .black;
        return self;
    }

    fn switchTurn(self: *Board) void {
        if (self.turn == .black) {
            self.turn = .white;
        } else {
            self.turn = .black;
        }
    }

    fn possibleMoves(self: Board) std.ArrayList(XY) {
        var results = std.ArrayList(XY).init(allocator);
        var y: u8 = 0;
        while (y < 8) : (y += 1) {
            var x: u8 = 0;
            while (x < 8) : (x += 1) {
                if (self.get(x, y)) |_| {
                    continue;
                }
                if (self.flip(x, y, self.turn).items.len > 0) {
                    results.append(.{ x, y }) catch unreachable;
                }
            }
        }
        return results;
    }

    fn get(self: Board, x: u8, y: u8) ?State {
        return self.cells[x + y * 8];
    }

    fn set(self: *Board, x: u8, y: u8, state: ?State) void {
        self.cells[x + y * 8] = state;
    }

    fn flip(self: *const Board, x: u8, y: u8, state: State) std.ArrayList(XY) {
        var results = std.ArrayList(XY).init(allocator);
        if (self.get(x, y)) |_| {
            return results;
        }
        results.append(.{ x, y }) catch unreachable;
        const directions: [8]struct { i8, i8 } = .{ .{ 0, -1 }, .{ 1, -1 }, .{ 1, 0 }, .{ 1, 1 }, .{ 0, 1 }, .{ -1, 1 }, .{ -1, 0 }, .{ -1, -1 } };
        for (directions) |d| {
            var current = .{ @as(i16, x), @as(i16, y) };
            var candidates = std.ArrayList(struct { u8, u8 }).init(allocator);
            while (true) {
                current[0] = current[0] + @as(i16, d[0]);
                current[1] = current[1] + @as(i16, d[1]);
                if (current[0] < 0 or current[0] > 7 or current[1] < 0 or current[1] > 7) {
                    break;
                }
                if (self.get(@intCast(current[0]), @intCast(current[1]))) |s| {
                    if (s != state) {
                        candidates.append(.{ @intCast(current[0]), @intCast(current[1]) }) catch unreachable;
                        continue;
                    } else {
                        results.appendSlice(candidates.items) catch unreachable;
                        break;
                    }
                } else {
                    break;
                }
            }
        }
        if (results.items.len == 1) {
            results.resize(0) catch unreachable;
        }
        return results;
    }

    fn parseMove(move: []const u8) !XY {
        if (move.len != 2) {
            return error.ParseMoveError;
        }
        const x = move[0] - 'a';
        const y = move[1] - '1';
        if (x > 7 or y > 7) {
            return error.ParseMoveError;
        }
        return .{ x, y };
    }

    fn display(self: Board) !void {
        try stdout.print("{s}", .{"  a b c d e f g h\n"});
        var y: u8 = 0;
        while (y < 8) : (y += 1) {
            try stdout.print("{d} ", .{y + 1});
            var x: u8 = 0;
            while (x < 8) : (x += 1) {
                if (self.get(x, y)) |state| {
                    switch (state) {
                        .white => try stdout.print("{s}", .{"○ "}),
                        .black => try stdout.print("{s}", .{"● "}),
                    }
                } else {
                    if (self.flip(x, y, self.turn).items.len > 0) {
                        try stdout.print("{s}", .{"◉ "});
                    } else {
                        try stdout.print("{s}", .{"· "});
                    }
                }
            }
            try stdout.print("{d}\n", .{y + 1});
        }
        try stdout.print("{s}", .{"  a b c d e f g h\n"});
    }

    fn promptPlay(self: Board) !void {
        try self.display();
        try stdout.print("\n", .{});
        try stdout.print("Turn: {s}\n\n", .{@tagName(self.turn)});
        try stdout.print("Enter move: ", .{});
    }
};

// TODO: test several board & shared data or not (default values)

pub fn main() !void {
    var board = Board.init();
    var buffer: [1024]u8 = undefined;

    while (true) {
        // TODO: split display & promptPlay
        try board.promptPlay();

        while (true) {
            const move = try stdin.readUntilDelimiter(&buffer, '\n');
            const xy = Board.parseMove(move) catch {
                try stdout.print("Invalid move, try again: ", .{});
                continue;
            };
            const flips = board.flip(xy[0], xy[1], board.turn);
            if (flips.items.len == 0) {
                try stdout.print("Invalid move, try again: ", .{});
                continue;
            } else {
                board.set(xy[0], xy[1], board.turn);
                for (flips.items) |xy_| {
                    board.set(xy_[0], xy_[1], board.turn);
                }
                board.switchTurn();
                if (board.possibleMoves().items.len == 0) {
                    try stdout.print("No possible moves, turn skipped\n\n", .{});
                    board.switchTurn();
                }
                if (board.possibleMoves().items.len == 0) {
                    try stdout.print("No possible moves, game over!!!\n\n", .{});
                    // TODO: print stats ?
                    return;
                }
                try board.promptPlay();
            }
        }
    }
}

test "Board data not shared" {
    const board_1 = Board.init();
    var board_2 = Board.init();
    board_2.set(0, 0, .black);
    try expect(board_1.get(0, 0) == null);
    try expect(&board_1.cells != &board_2.cells);
}

test "Parse move" {
    try expect(std.meta.eql(try Board.parseMove("a1"), .{ 0, 0 }));
    try expect(std.meta.eql(try Board.parseMove("a2"), .{ 0, 1 }));
    try expect(std.meta.eql(try Board.parseMove("a8"), .{ 0, 7 }));
    try expect(std.meta.eql(try Board.parseMove("h1"), .{ 7, 0 }));
    try expect(std.meta.eql(try Board.parseMove("h8"), .{ 7, 7 }));
}
