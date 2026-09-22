`timescale 1ns / 1ps
module clk_en(input wire clk, output reg o_ce);
    reg [1:0] counter = 2'd0;
    always@(posedge clk) begin
        o_ce <= 1'b0;
        if (counter < 3) begin
            counter <= counter + 1;
        end 
        else begin
            o_ce <= 1'b1;
            counter <= 0;
        end
    end
endmodule
