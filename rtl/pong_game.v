`timescale 1 ns / 1 ps
`include "vga_params.vh"
module pong_game #(parameter PADDLE_DELAY = 1_250_000, BALL_DELAY = 1_250_000, SCORE_LIMIT = 9)(input wire clk, i_ce, i_vsync, i_hsync, i_start, i_btn1_U, i_btn1_D, i_btn2_U, i_btn2_D, output wire o_hsync, o_vsync, output wire [3:0] o_red, o_green, o_blue, output wire [3:0] o_p1_score, o_p2_score);
    localparam IDLE = 2'd0, RUNNING = 2'd1, POINT = 2'd2, GAME_OVER = 2'd3;
    localparam PADDLE_HEIGHT = 6;

    // Pixel counts and tile coordinates
    wire [9:0] col_count;
    wire [9:0] row_count;
    wire [$clog2(`TILE_COLUMN)-1:0] col_tile;
    wire [$clog2(`TILE_ROW)-1:0] row_tile;
    wire active;

    // Draw flags and positions from the paddle and ball modules
    wire draw_player1;
    wire draw_player2;
    wire draw_ball;
    wire [$clog2(`TILE_COLUMN)-1:0] ball_x;
    wire [$clog2(`TILE_ROW)-1:0] ball_y;
    wire [$clog2(`TILE_ROW)-1:0] paddle1;
    wire [$clog2(`TILE_ROW)-1:0] paddle2;

    // Game state
    reg [1:0] state = IDLE;
    reg [1:0] next_state;
    reg [3:0] p1_score = 4'd0;
    reg [3:0] p2_score = 4'd0;
    reg [$clog2(`TILE_COLUMN)-1:0] prev_ball_x = `CENTER_X;
    reg start_prev = 1'b0;
    wire game_active;
    wire start_edge;
    wire arrive_left;
    wire arrive_right;
    wire p1_covers;
    wire p2_covers;
    wire p1_scored;
    wire p2_scored;

    // Video out and sync delay
    reg [3:0] red = 4'd0;
    reg [3:0] green = 4'd0;
    reg [3:0] blue = 4'd0;
    reg hsync_d1 = 1'b0;
    reg hsync_d2 = 1'b0;
    reg vsync_d1 = 1'b0;
    reg vsync_d2 = 1'b0;

    vga_sync_to_count sync_game(.clk(clk), .i_ce(i_ce), .i_vsync(i_vsync), .i_hsync(i_hsync), .o_col_count(col_count), .o_row_count(row_count));

    // Drop the low 4 bits to get the 16 px tile. Row 512+ wraps to 0 in 5 bits, handled by the active gate
    assign col_tile = col_count[9:4];
    assign row_tile = row_count[8:4];
    assign active = (col_count < `ACTIVE_COLUMNS) && (row_count < `ACTIVE_ROWS);

    paddle_ctrl #(.PADDLEX(0), .PADDLE_HEIGHT(PADDLE_HEIGHT), .MOVE_DELAY(PADDLE_DELAY)) p1(.clk(clk), .i_ce(i_ce), .i_tile_column(col_tile), .i_tile_row(row_tile), .i_btnU(i_btn1_U), .i_btnD(i_btn1_D), .o_draw_flag(draw_player1), .o_paddleY(paddle1));
    paddle_ctrl #(.PADDLEX(`TILE_COLUMN - 1), .PADDLE_HEIGHT(PADDLE_HEIGHT), .MOVE_DELAY(PADDLE_DELAY)) p2(.clk(clk), .i_ce(i_ce), .i_tile_column(col_tile), .i_tile_row(row_tile), .i_btnU(i_btn2_U), .i_btnD(i_btn2_D), .o_draw_flag(draw_player2), .o_paddleY(paddle2));
    ball_ctrl #(.MOVE_DELAY(BALL_DELAY)) ball(.clk(clk), .i_ce(i_ce), .i_game_active(game_active), .i_tile_column(col_tile), .i_tile_row(row_tile), .o_draw_flag(draw_ball), .o_ball_x(ball_x), .o_ball_y(ball_y));

    // Game rules, all combinational from registered state
    assign game_active = (state == RUNNING);
    assign start_edge = i_start & ~start_prev;
    assign arrive_left = (ball_x == `X_MIN) && (prev_ball_x != `X_MIN);
    assign arrive_right = (ball_x == `X_MAX) && (prev_ball_x != `X_MAX);
    assign p1_covers = (ball_y >= paddle1) && (ball_y <= paddle1 + PADDLE_HEIGHT - 1);
    assign p2_covers = (ball_y >= paddle2) && (ball_y <= paddle2 + PADDLE_HEIGHT - 1);
    assign p1_scored = game_active && arrive_right && !p2_covers;
    assign p2_scored = game_active && arrive_left && !p1_covers;

    // Next state logic
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (start_edge) begin
                    next_state = RUNNING;
                end
            end
            RUNNING: begin
                if (p1_scored || p2_scored) begin
                    next_state = POINT;
                end
            end
            POINT: begin
                if (p1_score == SCORE_LIMIT || p2_score == SCORE_LIMIT) begin
                    next_state = GAME_OVER;
                end
                else begin
                    next_state = IDLE;
                end
            end
            GAME_OVER: begin
                if (start_edge) begin
                    next_state = IDLE;
                end
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end

    // State, scores and edge detect registers
    always @(posedge clk) begin
        if (i_ce) begin
            state <= next_state;
            prev_ball_x <= ball_x;
            start_prev <= i_start;
            if (state == GAME_OVER && start_edge) begin
                p1_score <= 4'd0;
                p2_score <= 4'd0;
            end
            else if (p1_scored) begin
                p1_score <= p1_score + 1;
            end
            else if (p2_scored) begin
                p2_score <= p2_score + 1;
            end
        end
    end

    // Video: independent of game state, registered, sync delayed to match
    always @(posedge clk) begin
        if (i_ce) begin
            if (active && (draw_player1 || draw_player2 || draw_ball)) begin
                red <= 4'd15;
                green <= 4'd15;
                blue <= 4'd15;
            end
            else begin
                red <= 4'd0;
                green <= 4'd0;
                blue <= 4'd0;
            end
            hsync_d1 <= i_hsync;
            hsync_d2 <= hsync_d1;
            vsync_d1 <= i_vsync;
            vsync_d2 <= vsync_d1;
        end
    end

    assign o_hsync = hsync_d2;
    assign o_vsync = vsync_d2;
    assign o_red = red;
    assign o_green = green;
    assign o_blue = blue;
    assign o_p1_score = p1_score;
    assign o_p2_score = p2_score;
endmodule