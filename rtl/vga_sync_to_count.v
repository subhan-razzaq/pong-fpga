`timescale 1ns / 1ps
module vga_sync_to_count(input wire clk, i_ce, i_hsync, i_vsync, output reg [9:0] o_col_count = 10'b0, o_row_count = 10'b0, output reg o_hsync = 1'b0, o_vsync = 1'b0);
    `include "vga_params.vh"
    always@(posedge clk) begin
       if (i_ce) begin
            o_hsync <= i_hsync;
            o_vsync <= i_vsync;
            if (i_vsync == 1'b1 && o_vsync == 1'b0) begin
                o_col_count <= 10'b0;
                o_row_count <= 10'b0;
            end
            else begin
                if (o_col_count < TOTAL_COLUMNS - 1) begin
                o_col_count <= o_col_count + 1;
                end 
                else begin
                    o_col_count <= 10'b0;
                    if (o_row_count < TOTAL_ROWS - 1) begin
                        o_row_count <= o_row_count + 1;
                    end
                    else begin
                        o_row_count <= 10'b0;
                    end  
                end
            end
       end
     end
endmodule
