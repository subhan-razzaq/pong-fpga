`timescale 1ns / 1ps
// DIV MUST BE > 1
module clk_en #(parameter DIV = 4)(input wire clk, output reg o_ce = 1'b0);
    reg [$clog2(DIV) - 1:0] counter = 0;
    always@(posedge clk) begin
        o_ce <= 1'b0;
        if (counter < DIV - 1) begin
            counter <= counter + 1;
        end 
        else begin
            o_ce <= 1'b1;
            counter <= 0;
        end
    end
endmodule
