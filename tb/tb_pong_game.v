`timescale 1ns / 1ps
// Shared grid macros: TILE_SIZE, TILE_COLUMN, TOTAL_COLUMNS, TOTAL_ROWS, X_MIN, X_MAX, CENTER_X, CENTER_Y
`include "vga_params.vh"
module tb_pong_game();
    // Test constants
    localparam PADDLE_DELAY = 2;    // paddles move faster than the ball, so a paddle can leave during the ball's wall dwell
    localparam BALL_DELAY = 20;     // ball sits at each wall for 20 ticks
    localparam SCORE_LIMIT = 2;     // short game
    localparam PADDLE_HEIGHT = 6;   // must match pong_game
    localparam FRAME_TICKS = `TOTAL_COLUMNS * `TOTAL_ROWS;
    localparam WHITE_PER_FRAME = (`TILE_SIZE * `TILE_SIZE) + 2 * (`TILE_SIZE * PADDLE_HEIGHT * `TILE_SIZE);  // ball + 2 paddles in pixels

    // FSM encodings, must match pong_game
    localparam IDLE = 2'd0, RUNNING = 2'd1, POINT = 2'd2, GAME_OVER = 2'd3;

    reg clk;
    reg i_ce;
    reg i_start;
    reg i_btn1_U;
    reg i_btn1_D;
    reg i_btn2_U;
    reg i_btn2_D;
    wire hsync_raw;
    wire vsync_raw;
    wire o_hsync;
    wire o_vsync;
    wire [3:0] o_red;
    wire [3:0] o_green;
    wire [3:0] o_blue;
    wire [3:0] o_p1_score;
    wire [3:0] o_p2_score;
    integer errors;

    // 100 MHz clock
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // Real sync source, the same verified module the design uses (check port names match yours)
    vga_sync_pulses sync_gen(.clk(clk), .i_ce(i_ce), .o_hsync(hsync_raw), .o_vsync(vsync_raw), .o_col_count(), .o_row_count());

    pong_game #(.PADDLE_DELAY(PADDLE_DELAY), .BALL_DELAY(BALL_DELAY), .SCORE_LIMIT(SCORE_LIMIT)) dut(.clk(clk), .i_ce(i_ce), .i_vsync(vsync_raw), .i_hsync(hsync_raw), .i_start(i_start), .i_btn1_U(i_btn1_U), .i_btn1_D(i_btn1_D), .i_btn2_U(i_btn2_U), .i_btn2_D(i_btn2_D), .o_hsync(o_hsync), .o_vsync(o_vsync), .o_red(o_red), .o_green(o_green), .o_blue(o_blue), .o_p1_score(o_p1_score), .o_p2_score(o_p2_score));

    // Watchdog: two full frames plus game time is about 9 ms
    initial begin
        #20_000_000;
        $display("TEST FAILED: timeout");
        $finish;
    end

    // Compare both scores to expected values
    task check_scores;
        input [3:0] exp_p1;
        input [3:0] exp_p2;
        input [8*16-1:0] label;
        begin
            if (o_p1_score !== exp_p1 || o_p2_score !== exp_p2) begin
                $display("ERROR [%0s] at %0t ns: expected score %0d-%0d, got %0d-%0d", label, $time, exp_p1, exp_p2, o_p1_score, o_p2_score);
                errors = errors + 1;
            end
        end
    endtask

    // Compare the FSM state (hierarchical peek into the DUT)
    task check_state;
        input [1:0] expected;
        input [8*16-1:0] label;
        begin
            if (dut.state !== expected) begin
                $display("ERROR [%0s] at %0t ns: expected state %0d, got %0d", label, $time, expected, dut.state);
                errors = errors + 1;
            end
        end
    endtask

    // Compare the ball position (hierarchical peek into the DUT)
    task check_ball;
        input integer exp_x;
        input integer exp_y;
        input [8*16-1:0] label;
        begin
            if (dut.ball_x !== exp_x || dut.ball_y !== exp_y) begin
                $display("ERROR [%0s] at %0t ns: expected ball (%0d,%0d), got (%0d,%0d)", label, $time, exp_x, exp_y, dut.ball_x, dut.ball_y);
                errors = errors + 1;
            end
        end
    endtask

    // Step clock edges until the FSM reaches a state, error if it takes too long
    task wait_state;
        input [1:0] target;
        input integer max_ticks;
        input [8*16-1:0] label;
        integer n;
        begin
            n = 0;
            while (dut.state !== target && n < max_ticks) begin
                @(posedge clk); #1;
                n = n + 1;
            end
            if (dut.state !== target) begin
                $display("ERROR [%0s] at %0t ns: state %0d never reached", label, $time, target);
                errors = errors + 1;
            end
        end
    endtask

    // Step clock edges until the ball reaches a column, error if it takes too long
    task wait_ball_x;
        input integer target;
        input integer max_ticks;
        input [8*16-1:0] label;
        integer n;
        begin
            n = 0;
            while (dut.ball_x !== target && n < max_ticks) begin
                @(posedge clk); #1;
                n = n + 1;
            end
            if (dut.ball_x !== target) begin
                $display("ERROR [%0s] at %0t ns: ball never reached column %0d", label, $time, target);
                errors = errors + 1;
            end
        end
    endtask

    // Short start press: 3 ticks down, then released
    task tap_start;
        begin
            @(negedge clk) i_start = 1'b1;
            repeat (3) @(negedge clk);
            i_start = 1'b0;
        end
    endtask

    // Count white pixels over exactly one frame of ticks, the scene must be static while this runs
    task count_frame;
        input integer expected;
        input [8*16-1:0] label;
        integer n;
        integer whites;
        begin
            whites = 0;
            for (n = 0; n < FRAME_TICKS; n = n + 1) begin
                @(posedge clk); #1;
                if (o_red == 4'd15 && o_green == 4'd15 && o_blue == 4'd15) begin
                    whites = whites + 1;
                end
                else if (o_red != 4'd0 || o_green != 4'd0 || o_blue != 4'd0) begin
                    $display("ERROR [%0s] at %0t ns: RGB not black or white: %h %h %h", label, $time, o_red, o_green, o_blue);
                    errors = errors + 1;
                end
            end
            if (whites != expected) begin
                $display("ERROR [%0s]: expected %0d white pixels per frame, got %0d", label, expected, whites);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors   = 0;
        i_ce     = 1'b1;
        i_start  = 1'b0;
        i_btn1_U = 1'b0;
        i_btn1_D = 1'b0;
        i_btn2_U = 1'b0;
        i_btn2_D = 1'b0;

        // 1. Idle: no press, nothing moves, scores stay 0
        repeat (5 * BALL_DELAY) @(posedge clk); #1;
        check_state(IDLE, "idle_state");
        check_scores(0, 0, "idle_scores");
        check_ball(`CENTER_X, `CENTER_Y, "idle_ball");

        // 2. Serve with start HELD the whole point: first miss is P2's (paddle rows 12 to 17, ball arrives at row 3)
        @(negedge clk) i_start = 1'b1;
        wait_state(RUNNING, 5, "serve");
        wait_state(POINT, 20 * BALL_DELAY, "miss1");
        check_ball(`X_MAX, 3, "miss1_ball");
        check_scores(1, 0, "miss1_scores");

        // 3. Still holding start: POINT returns to IDLE and must NOT serve again (edge detect)
        repeat (5 * BALL_DELAY) @(posedge clk); #1;
        check_state(IDLE, "held_no_serve");
        check_ball(`CENTER_X, `CENTER_Y, "held_center");
        @(negedge clk) i_start = 1'b0;

        // 4a. Move P2 to the top so it covers row 3, then check the active gate with a paddle in tile row 0
        @(negedge clk) i_btn2_U = 1'b1;
        repeat (30 * PADDLE_DELAY) @(posedge clk);
        @(negedge clk) i_btn2_U = 1'b0;
        #1;
        if (dut.paddle2 !== 0) begin
            $display("ERROR [p2_to_top]: P2 paddle at %0d, expected 0", dut.paddle2);
            errors = errors + 1;
        end
        count_frame(WHITE_PER_FRAME, "frame_gate");

        // 4b. Serve: P2 covers on arrival, so no score
        tap_start;
        wait_ball_x(`X_MAX, 20 * BALL_DELAY, "hit_arrive");
        check_state(RUNNING, "hit_no_point");
        check_scores(1, 0, "hit_scores");

        // 4c. Move P2 off the ball while it still sits at the wall: must still not score (arrival-only check)
        @(negedge clk) i_btn2_D = 1'b1;
        repeat (6 * PADDLE_DELAY) @(posedge clk);
        @(negedge clk) i_btn2_D = 1'b0;
        #1;
        if (dut.paddle2 <= 3 || dut.ball_x !== `X_MAX) begin
            $display("ERROR [late_move_setup]: paddle %0d, ball X %0d, test did not exercise the dwell window", dut.paddle2, dut.ball_x);
            errors = errors + 1;
        end
        wait_ball_x(`X_MAX - 1, 2 * BALL_DELAY, "hit_bounce");
        check_state(RUNNING, "late_move_state");
        check_scores(1, 0, "late_move_scores");

        // 4d. Ball continues to the left wall and arrives at row 18, just below P1 (rows 12 to 17): P2 scores
        wait_state(POINT, 60 * BALL_DELAY, "miss2");
        check_ball(`X_MIN, 18, "miss2_ball");
        check_scores(1, 1, "miss2_scores");
        wait_state(IDLE, 5, "miss2_idle");

        // 5. Serve again: P2 is now low (rows 6+), ball arrives at row 3, P1 reaches SCORE_LIMIT
        tap_start;
        wait_state(POINT, 20 * BALL_DELAY, "miss3");
        check_scores(2, 1, "miss3_scores");
        wait_state(GAME_OVER, 5, "game_over");

        // 6. GAME_OVER holds: nothing moves, scores stay on display, then check one full frame of video
        repeat (5 * BALL_DELAY) @(posedge clk); #1;
        check_state(GAME_OVER, "over_hold");
        check_scores(2, 1, "over_scores");
        check_ball(`CENTER_X, `CENTER_Y, "over_ball");
        count_frame(WHITE_PER_FRAME, "frame_over");

        // 7. Start in GAME_OVER: scores clear, back to IDLE, no serve until another press
        tap_start;
        repeat (5) @(posedge clk); #1;
        check_state(IDLE, "reset_state");
        check_scores(0, 0, "reset_scores");

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