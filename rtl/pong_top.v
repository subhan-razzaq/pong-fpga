`timescale 1 ns / 1 ps
module pong_top(input wire clk, input wire btnC, input wire [15:0] sw, output wire Hsync, Vsync, dp, output wire [3:0] vgaRed, vgaGreen, vgaBlue, an, output wire [6:0] seg);
    wire clk_25;
    wire clk_1k;
    wire o_hsync, o_vsync;
    wire o_hsync_tp, o_vsync_tp;
    wire btnC_db;
    wire btnC_press;
    reg  btnC_db_prev = 1'b0;
    reg [7:0] press_count = 8'd0;
    wire [15:0] test_digits = {8'd0, press_count};
    wire [3:0] blank, o_red_tp, o_green_tp, o_blue_tp;
    assign dp = 1'b1;
    assign blank = 4'b0000;
    assign btnC_press = (btnC_db && !btnC_db_prev) ? 1'b1 : 1'b0;
    clk_en #(.DIV(4)) inst_clk0(.clk(clk), .o_ce(clk_25));
    clk_en #(.DIV(100_000)) inst_clk1(.clk(clk), .o_ce(clk_1k));
    vga_sync_pulses inst_pulses(.clk(clk), .i_ce(clk_25), .o_hsync(o_hsync), .o_vsync(o_vsync));
    test_pattern inst_test_pattern(.clk(clk), .i_ce(clk_25), .i_hsync(o_hsync), .i_vsync(o_vsync), .o_hsync(o_hsync_tp), .o_vsync(o_vsync_tp), .o_red(o_red_tp), .o_green(o_green_tp), .o_blue(o_blue_tp));
    vga_sync_porch inst_porch(.clk(clk), .i_ce(clk_25), .i_hsync(o_hsync_tp), .i_vsync(o_vsync_tp), .i_red(o_red_tp), .i_green(o_green_tp), .i_blue(o_blue_tp), .o_hsync(Hsync), .o_vsync(Vsync), .o_red(vgaRed), .o_green(vgaGreen), .o_blue(vgaBlue));
    seven_seg_mux inst_seven_seg(.clk(clk), .i_ce(clk_1k), .i_digits(test_digits), .i_blank(blank), .o_seg(seg), .o_an(an)); // TEMPORARY
    debounce inst_debounce(.clk(clk), .i_btn(btnC), .o_btn(btnC_db));
    always@(posedge clk) begin
        btnC_db_prev <= btnC_db;
        if (btnC_press == 1'b1) begin
            press_count <= press_count + 1;
        end
    end
endmodule