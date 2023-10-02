const std = @import("std");
const stdout = std.io.getStdOut().writer();
const stdin = std.io.getStdIn().reader();

const State = enum {
    none,
    white,
    black,
};

const Error = error{ ParseMoveError, InvalidMoveError };

const XY = struct {
    x: u8,
    y: u8,
};

const Board = struct {
    cells: [64]State = [_]State{.none} ** 64,

    fn init() Board {
        var board = Board{};
        board.cells[27] = .white;
        board.cells[28] = .black;
        board.cells[35] = .black;
        board.cells[36] = .white;
        return board;
    }

    fn get(self: Board, x: u8, y: u8) State {
        return self.cells[y * 8 + x];
    }

    fn set(self: *Board, x: u8, y: u8, state: State) !void {
        var board = Board{};
        _ = board;
        if (self.get(x, y) != .none) {
            return error.InvalidMoveError;
        }
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
        return XY{ .x = x, .y = y };
    }

    fn display(self: Board) !void {
        try stdout.print("{s}", .{"  a b c d e f g h\n"});
        var x: u8 = 0;
        while (x < 8) : (x += 1) {
            try stdout.print("{d} ", .{x + 1});
            var y: u8 = 0;
            while (y < 8) : (y += 1) {
                const index = y * 8 + x;
                switch (self.cells[index]) {
                    .none => try stdout.print("{s}", .{"- "}),
                    .white => try stdout.print("{s}", .{"○ "}),
                    .black => try stdout.print("{s}", .{"● "}),
                }
            }
            try stdout.print("{d}\n", .{x + 1});
        }
        try stdout.print("{s}", .{"  a b c d e f g h\n"});
    }
};

pub fn main() !void {
    var board = Board.init();
    var buffer: [1024]u8 = undefined;

    while (true) {
        try board.display();
        try stdout.print("\n", .{});
        try stdout.print("Turn: ●\n", .{});
        try stdout.print("\n", .{});
        try stdout.print("Enter move: ", .{});

        var xy: ?XY = null;
        while (xy == null) {
            const move = try stdin.readUntilDelimiter(&buffer, '\n');
            xy = Board.parseMove(move) catch {
                try stdout.print("Invalid move, try again: ", .{});
                continue;
            };
        }
        try board.set(xy.?.x, xy.?.y, .black);
        try stdout.print("\n", .{});
    }
}
