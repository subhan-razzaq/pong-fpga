`timescale 1ns / 1ps
module vga_sync_pulses(input wire clk, i_ce, output reg o_hsync, o_vsync, output reg [9:0] o_col_count = 10'b0, o_row_count = 10'b0);
    `include "vga_params.vh"
    always@(posedge clk) begin
        if (i_ce) begin
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
      always@(*) begin
            if (o_col_count < ACTIVE_COLUMNS) begin
                o_hsync = 1'b1;
            end
            else begin
                o_hsync = 1'b0;
            end
            
            if (o_row_count < ACTIVE_ROWS) begin
                o_vsync = 1'b1;
            end
            else begin
                o_vsync = 1'b0;
            end
      end
endmodule
