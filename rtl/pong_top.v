`timescale 1 ns / 1 ps
`default_nettype none
module pong_top(input wire clk, btnU, btnD, btnL, btnR, btnC, output wire Hsync, Vsync, dp, output wire [3:0] vgaRed, vgaGreen, vgaBlue, an, output wire [6:0] seg);
    wire clk_25;
    wire clk_1k;
    wire o_hsync_p, o_vsync_p;
    wire o_hsync_game, o_vsync_game;
    wire btnC_db, btnU_db, btnD_db, btnL_db, btnR_db;
    wire [3:0] blank, o_red_game, o_green_game, o_blue_game, o_p1score_game, o_p2score_game;
    assign dp = 1'b1;
    assign blank = 4'b0000;
    clk_en #(.DIV(4)) inst_clk0(.clk(clk), .o_ce(clk_25));
    clk_en #(.DIV(100_000)) inst_clk1(.clk(clk), .o_ce(clk_1k));
    debounce instbtnC_debounce(.clk(clk), .i_btn(btnC), .o_btn(btnC_db));
    debounce instbtnU_debounce(.clk(clk), .i_btn(btnU), .o_btn(btnU_db));
    debounce instbtnD_debounce(.clk(clk), .i_btn(btnD), .o_btn(btnD_db));
    debounce instbtnL_debounce(.clk(clk), .i_btn(btnL), .o_btn(btnL_db));
    debounce instbtnR_debounce(.clk(clk), .i_btn(btnR), .o_btn(btnR_db));
    vga_sync_pulses inst_pulses(.clk(clk), .i_ce(clk_25), .o_hsync(o_hsync_p), .o_vsync(o_vsync_p));
    pong_game #(.PADDLE_DELAY(1_000_000), .BALL_DELAY(1_250_000), .SCORE_LIMIT(9)) inst_game( .clk(clk), .i_ce(clk_25), .i_vsync(o_vsync_p), .i_hsync(o_hsync_p), .i_start(btnC_db), .i_btn1_U(btnL_db), .i_btn1_D(btnU_db), .i_btn2_U(btnD_db), .i_btn2_D(btnR_db), .o_hsync(o_hsync_game), .o_vsync(o_vsync_game), .o_red(o_red_game), .o_green(o_green_game), .o_blue(o_blue_game), .o_p1_score(o_p1score_game), .o_p2_score(o_p2score_game));
    vga_sync_porch inst_porch(.clk(clk), .i_ce(clk_25), .i_hsync(o_hsync_game), .i_vsync(o_vsync_game), .i_red(o_red_game), .i_green(o_green_game), .i_blue(o_blue_game), .o_hsync(Hsync), .o_vsync(Vsync), .o_red(vgaRed), .o_green(vgaGreen), .o_blue(vgaBlue));
    seven_seg_mux inst_seven_seg(.clk(clk), .i_ce(clk_1k), .i_digits({4'hA, o_p1score_game, 4'hB, o_p2score_game}), .i_blank(blank), .o_seg(seg), .o_an(an)); 
endmodule
`default_nettype wire