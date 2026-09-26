`timescale 1ns / 1ps
// Shared grid macros: TILE_COLUMN, TILE_ROW, X_MIN, X_MAX, Y_MIN, Y_MAX, CENTER_X, CENTER_Y
`default_nettype none
`include "vga_params.vh"
module tb_ball_ctrl();

    // Test constants
    localparam DELAY = 5;    // move delay for this tb, not a power of 2 so a missing counter reset can't hide (real design uses 1,250,000)
    localparam MOVES = 120;  // long run length, enough to reach all four walls

    reg clk;
    reg i_ce;
    reg i_game_active;
    reg [$clog2(`TILE_COLUMN)-1:0] i_tile_column;
    reg [$clog2(`TILE_ROW)-1:0] i_tile_row;
    wire o_draw_flag;
    wire [$clog2(`TILE_COLUMN)-1:0] o_ball_x;
    wire [$clog2(`TILE_ROW)-1:0] o_ball_y;
    integer errors;
    integer i;
    integer prev_x;
    integer prev_y;
    integer x_now;
    integer y_now;
    reg hit_left;
    reg hit_right;
    reg hit_top;
    reg hit_bottom;

    // 100 MHz clock
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    ball_ctrl #(.MOVE_DELAY(DELAY)) ball_ctrl_check(.clk(clk), .i_ce(i_ce), .i_game_active(i_game_active), .i_tile_column(i_tile_column), .i_tile_row(i_tile_row), .o_draw_flag(o_draw_flag), .o_ball_x(o_ball_x), .o_ball_y(o_ball_y));

    // Watchdog: ends the sim if the tb ever hangs
    initial begin
        #50_000;
        $display("TEST FAILED: timeout");
        $finish;
    end

    // Compare ball X and Y to the expected values, log and count any mismatch
    task check_pos;
        input [$clog2(`TILE_COLUMN)-1:0] exp_x;
        input [$clog2(`TILE_ROW)-1:0] exp_y;
        input [8*16-1:0] label;
        begin
            if (o_ball_x !== exp_x || o_ball_y !== exp_y) begin
                $display("ERROR [%0s] at %0t ns: expected (%0d,%0d), got (%0d,%0d)", label, $time, exp_x, exp_y, o_ball_x, o_ball_y);
                errors = errors + 1;
            end
        end
    endtask

    // Compare the draw flag to the expected value, log and count any mismatch
    task check_draw;
        input expected;
        input [8*16-1:0] label;
        begin
            if (o_draw_flag !== expected) begin
                $display("ERROR [%0s] at %0t ns: col %0d row %0d expected draw %b, got %b", label, $time, i_tile_column, i_tile_row, expected, o_draw_flag);
                errors = errors + 1;
            end
        end
    endtask

    // Walk every tile on the grid and check draw is high only on the ball
    // Ball must be frozen (CE low or game inactive) while this runs
    task sweep_grid;
        input [8*16-1:0] label;
        integer col;
        integer row;
        integer bx;
        integer by;
        begin
            bx = o_ball_x;
            by = o_ball_y;
            for (col = 0; col < `TILE_COLUMN; col = col + 1) begin
                for (row = 0; row < `TILE_ROW; row = row + 1) begin
                    i_tile_column = col;
                    i_tile_row = row;
                    #1;
                    check_draw((col == bx) && (row == by), label);
                end
            end
        end
    endtask

    initial begin
        errors        = 0;
        i_ce          = 1'b1;
        i_game_active = 1'b0;
        i_tile_column = 0;
        i_tile_row    = 0;
        hit_left      = 1'b0;
        hit_right     = 1'b0;
        hit_top       = 1'b0;
        hit_bottom    = 1'b0;

        // 1. Inactive: ball holds center
        repeat (20) @(posedge clk); #1;
        check_pos(`CENTER_X, `CENTER_Y, "idle_center");

        // 2. Serve: no move after DELAY-1 edges, first move on edge DELAY, heading right and up
        @(negedge clk) i_game_active = 1'b1;
        repeat (DELAY - 1) @(posedge clk); #1;
        check_pos(`CENTER_X, `CENTER_Y, "serve_early");
        @(posedge clk); #1;
        check_pos(`CENTER_X + 1, `CENTER_Y - 1, "serve_first");

        // 3. Second move lands exactly DELAY edges after the first (catches a missing counter reset)
        repeat (DELAY - 1) @(posedge clk); #1;
        check_pos(`CENTER_X + 1, `CENTER_Y - 1, "second_early");
        @(posedge clk); #1;
        check_pos(`CENTER_X + 2, `CENTER_Y - 2, "second_move");

        // 4. Long run: every move steps exactly 1 in X and in Y, and the ball never leaves the walls
        for (i = 0; i < MOVES; i = i + 1) begin
            prev_x = o_ball_x;
            prev_y = o_ball_y;
            repeat (DELAY) @(posedge clk); #1;
            x_now = o_ball_x;
            y_now = o_ball_y;
            if ((x_now - prev_x != 1) && (x_now - prev_x != -1)) begin
                $display("ERROR [x_step] at %0t ns: X went %0d -> %0d", $time, prev_x, x_now);
                errors = errors + 1;
            end
            if ((y_now - prev_y != 1) && (y_now - prev_y != -1)) begin
                $display("ERROR [y_step] at %0t ns: Y went %0d -> %0d", $time, prev_y, y_now);
                errors = errors + 1;
            end
            if (x_now < `X_MIN || x_now > `X_MAX) begin
                $display("ERROR [x_range] at %0t ns: X = %0d", $time, x_now);
                errors = errors + 1;
            end
            if (y_now < `Y_MIN || y_now > `Y_MAX) begin
                $display("ERROR [y_range] at %0t ns: Y = %0d", $time, y_now);
                errors = errors + 1;
            end
            if (x_now == `X_MIN) begin
                hit_left = 1'b1;
            end
            if (x_now == `X_MAX) begin
                hit_right = 1'b1;
            end
            if (y_now == `Y_MIN) begin
                hit_top = 1'b1;
            end
            if (y_now == `Y_MAX) begin
                hit_bottom = 1'b1;
            end
        end
        if (!(hit_left && hit_right && hit_top && hit_bottom)) begin
            $display("ERROR [walls]: left %b right %b top %b bottom %b", hit_left, hit_right, hit_top, hit_bottom);
            errors = errors + 1;
        end
        // 122 moves from center: X bounces 20 -> 38 -> 1 -> 38 -> 8 (heading left), Y bounces 15 -> 0 -> 29 -> 0 -> 29 -> 9 (heading up)
        check_pos(8, 9, "after_run");

        // 5. CE low freezes everything, then check draw across the whole grid at a non-center position
        @(negedge clk) i_ce = 1'b0;
        repeat (3 * DELAY) @(posedge clk); #1;
        check_pos(8, 9, "ce_freeze");
        sweep_grid("draw_frozen");
        @(negedge clk) i_ce = 1'b1;

        // 6. Drop game active mid-count: ball snaps to center on the next edge
        repeat (2) @(posedge clk);
        @(negedge clk) i_game_active = 1'b0;
        @(posedge clk); #1;
        check_pos(`CENTER_X, `CENTER_Y, "drop_center");
        sweep_grid("draw_center");

        // 7. Re-serve: counter restarted from 0 and direction reset to right and up
        @(negedge clk) i_game_active = 1'b1;
        repeat (DELAY - 1) @(posedge clk); #1;
        check_pos(`CENTER_X, `CENTER_Y, "reserve_early");
        @(posedge clk); #1;
        check_pos(`CENTER_X + 1, `CENTER_Y - 1, "reserve_first");

        // Result
        if (errors == 0) begin
            $display("TEST PASSED");
        end
        else begin
            $display("TEST FAILED: %0d errors", errors);
        end
        $finish;
    end
endmodule
`default_nettype wire