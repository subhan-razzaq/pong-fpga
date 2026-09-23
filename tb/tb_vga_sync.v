`timescale 1ns / 1ps
module tb_vga_sync();
    reg clk;
    wire clk_25;
    wire o_hsync, o_vsync;
    wire o_hsync_delayed, o_vsync_delayed;
    wire [9:0] o_col_count, o_row_count;
    wire [9:0] o_col_count1, o_row_count1;
    wire o_hsync_tp, o_vsync_tp;
    wire [3:0] o_red_tp, o_green_tp, o_blue_tp;
    wire o_hsync_porch, o_vsync_porch;
    wire [3:0] o_red_porch, o_green_porch, o_blue_porch;
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end 
    clk_en #(.DIV(4)) clkgen(.clk(clk), .o_ce(clk_25));
    vga_sync_pulses pulse_check(.clk(clk), .i_ce(clk_25), .o_hsync(o_hsync), .o_vsync(o_vsync), .o_col_count(o_col_count), .o_row_count(o_row_count));
    vga_sync_to_count sync_check(.clk(clk), .i_ce(clk_25), .i_hsync(o_hsync), .i_vsync(o_vsync), .o_col_count(o_col_count1), .o_row_count(o_row_count1), .o_hsync(o_hsync_delayed), .o_vsync(o_vsync_delayed));
    test_pattern check(.clk(clk), .i_ce(clk_25), .i_hsync(o_hsync), .i_vsync(o_vsync), .o_hsync(o_hsync_tp), .o_vsync(o_vsync_tp), .o_red(o_red_tp), .o_green(o_green_tp), .o_blue(o_blue_tp));
    vga_sync_porch porch_check(.clk(clk), .i_ce(clk_25), .i_hsync(o_hsync_tp), .i_vsync(o_vsync_tp), .i_red(o_red_tp), .i_green(o_green_tp), .i_blue(o_blue_tp), .o_hsync(o_hsync_porch), .o_vsync(o_vsync_porch), .o_red(o_red_porch), .o_green(o_green_porch), .o_blue(o_blue_porch));
    initial begin
        # 20_000_000
        $finish;
    end
endmodule