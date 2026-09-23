`timescale 1ns / 1ps
module vga_sync_porch(input wire clk, i_ce, i_hsync, i_vsync, input wire [3:0] i_red, i_green, i_blue, output reg o_hsync = 1'b1, o_vsync = 1'b1, output reg [3:0] o_red = 4'b0, o_green = 4'b0, o_blue = 4'b0);
    `include "vga_params.vh"
    wire [9:0] count_col, count_row;
    reg [3:0] red_delayed = 4'b0, green_delayed = 4'b0, blue_delayed = 4'b0;
    vga_sync_to_count inst_1(.clk(clk), .i_ce(i_ce), .i_hsync(i_hsync), .i_vsync(i_vsync), .o_col_count(count_col), .o_row_count(count_row));
    always@(posedge clk) begin
        if (i_ce) begin
            red_delayed <= i_red;
            green_delayed <= i_green;
            blue_delayed <= i_blue;
            o_red <= red_delayed;
            o_green <= green_delayed;
            o_blue <= blue_delayed;
            if (count_col >= SYNC_START_H && count_col < SYNC_STOP_H) begin
                o_hsync <= 1'b0;
            end
            else begin
                o_hsync <= 1'b1;
            end
            if (count_row >= SYNC_START_V && count_row < SYNC_STOP_V) begin
                o_vsync <= 1'b0;
            end
            else begin
                o_vsync <= 1'b1;
            end
            
        end
    end
endmodule