const std = @import("std");

const stdout = std.io.getStdOut().writer();
const stdin = std.io.getStdIn().reader();

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
    turn: ?State = null,

    fn init() Board {
        var self = Board{};
        self.set(3, 3, .white);
        self.set(4, 3, .black);
        self.set(3, 4, .white);
        self.set(4, 4, .black);
        self.turn = .black;
        return self;
    }

    fn get(self: Board, x: u8, y: u8) ?State {
        return self.cells[y * 8 + x];
    }

    fn set(self: *Board, x: u8, y: u8, state: ?State) void {
        self.cells[y * 8 + x] = state;
    }

    fn parseMove(move: []u8) !XY {
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
        var x: u8 = 0;
        while (x < 8) : (x += 1) {
            try stdout.print("{d} ", .{x + 1});
            var y: u8 = 0;
            while (y < 8) : (y += 1) {
                if (self.get(x, y)) |state| {
                    switch (state) {
                        .white => try stdout.print("{s}", .{"○ "}),
                        .black => try stdout.print("{s}", .{"● "}),
                    }
                } else {
                    try stdout.print("{s}", .{"- "});
                }
            }
            try stdout.print("{d}\n", .{x + 1});
        }
        try stdout.print("{s}", .{"  a b c d e f g h\n"});
    }

    fn promptPlay(self: Board) !void {
        try self.display();
        try stdout.print("\n", .{});
        if (self.turn) |state| {
            try stdout.print("Turn: {s}\n\n", .{@tagName(state)});
        }
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
            if (board.get(xy[0], xy[1])) |_| {
                try stdout.print("Invalid move, try again: ", .{});
                continue;
            }
            board.set(xy[0], xy[1], .black);
            try board.promptPlay();
        }
    }
}
