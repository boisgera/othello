const std = @import("std");
const stdout = std.io.getStdOut().writer();

const State = enum {
    none,
    white,
    black,
};

const Board = struct {
    cells: [64]State,

    fn init() Board {
        var board = Board{
            .cells = [_]State{.none} ** 64,
        };
        board.cells[27] = .white;
        board.cells[28] = .black;
        board.cells[35] = .black;
        board.cells[36] = .white;
        return board;
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
                    .white => try stdout.print("{s}", .{"O "}),
                    .black => try stdout.print("{s}", .{"X "}),
                }
            }
            try stdout.print("{d}\n", .{x + 1});
        }
        try stdout.print("{s}", .{"  a b c d e f g h\n"});
    }
};

pub fn main() !void {
    const board = Board.init();
    try board.display();
}
