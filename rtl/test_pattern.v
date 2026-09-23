`timescale 1 ns / 1ps
module test_pattern(input wire clk, i_ce, i_hsync, i_vsync, output reg o_hsync, o_vsync, output reg [3:0] o_red, o_green, o_blue);
    `include "vga_params.vh"
    wire [9:0] count_col, count_row;
    wire hsync, vsync;
    vga_sync_to_count inst0(.clk(clk), .i_ce(i_ce), .i_hsync(i_hsync), .i_vsync(i_vsync), .o_hsync(hsync), .o_vsync(vsync), .o_col_count(count_col), .o_row_count(count_row));
    always@(posedge clk) begin
        if (i_ce) begin
            o_hsync <= hsync;
            o_vsync <= vsync;
            if (count_col >= ACTIVE_COLUMNS || count_row >= ACTIVE_ROWS) begin
                o_red <= 4'b0;
                o_blue <= 4'b0;
                o_green <= 4'b0;
            end
            else begin  
                case (count_col[9:7])
                    3'b000: begin
                        o_red <= 4'd15;
                        o_blue <= 4'b0;
                        o_green <= 4'b0;
                    end
                    3'b001: begin
                        o_red <= 4'b0;
                        o_blue <= 4'd15;
                        o_green <= 4'b0;
                    end 
                    3'b010: begin
                        o_red <= 4'b0;
                        o_blue <= 4'b0;
                        o_green <= 4'd15;
                    end
                    3'b011: begin
                        o_red <= 4'd15;
                        o_blue <= 4'b0;
                        o_green <= 4'b0;
                    end
                    3'b100: begin
                        o_red <= 4'b0;
                        o_blue <= 4'd15;
                        o_green <= 4'b0;
                    end
                    default: begin
                        o_red <= 4'b0;
                        o_blue <= 4'b0;
                        o_green <= 4'b0;
                    end
                endcase
             end
        end
    end
endmodule