`timescale 1 ns / 1 ps
module pong_top(input wire clk, output wire Hsync, Vsync, output wire [3:0] vgaRed, vgaGreen, vgaBlue);
    wire clk_25;
    wire o_hsync, o_vsync;
    wire o_hsync_tp, o_vsync_tp;
    wire [3:0] o_red_tp, o_green_tp, o_blue_tp;
    clk_en #(.DIV(4)) inst_clk(.clk(clk), .o_ce(clk_25));
    vga_sync_pulses inst_pulses(.clk(clk), .i_ce(clk_25), .o_hsync(o_hsync), .o_vsync(o_vsync));
    test_pattern inst_test_pattern(.clk(clk), .i_ce(clk_25), .i_hsync(o_hsync), .i_vsync(o_vsync), .o_hsync(o_hsync_tp), .o_vsync(o_vsync_tp), .o_red(o_red_tp), .o_green(o_green_tp), .o_blue(o_blue_tp));
    vga_sync_porch inst_porch(.clk(clk), .i_ce(clk_25), .i_hsync(o_hsync_tp), .i_vsync(o_vsync_tp), .i_red(o_red_tp), .i_green(o_green_tp), .i_blue(o_blue_tp), .o_hsync(Hsync), .o_vsync(Vsync), .o_red(vgaRed), .o_green(vgaGreen), .o_blue(vgaBlue));
endmodule