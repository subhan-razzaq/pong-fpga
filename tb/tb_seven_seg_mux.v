`timescale 1ns / 1ps
module tb_seven_seg_mux();
    reg clk;
    wire clk_25;
    wire [6:0] seg_decoded, seg_mux;
    wire [3:0] an_mux;
    reg [3:0] blank, hex;
    reg [15:0] digits;
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end 
    
    clk_en #(.DIV(4)) clkgen(.clk(clk), .o_ce(clk_25));
    seven_seg_decoder decoder_check(.i_hex(hex), .o_seg(seg_decoded));
    seven_seg_mux mux_check(.clk(clk), .i_ce(clk_25), .i_digits(digits), .i_blank(blank), .o_seg(seg_mux), .o_an(an_mux));
    initial begin
        hex = 4'b0;
        blank = 4'b0;
        digits = 16'b0;
        #10 hex = 4'd1;
        #10 hex = 4'd2;
        #10 hex = 4'd3;
        #10 hex = 4'd4;
        #10 hex = 4'd5;
        #10 hex = 4'd6;
        #10 hex = 4'd7;
        #10 hex = 4'd8;
        #10 hex = 4'd9;
        #10 hex = 4'd10;
        #10 hex = 4'd11;
        #10 hex = 4'd12;
        #10 hex = 4'd13;
        #10 hex = 4'd14;
        #10 hex = 4'd15;
        #10 digits = 16'h0123;
        repeat (8) @(posedge clk_25);
        digits = 16'h4567;
        repeat (8) @(posedge clk_25);
        digits = 16'h89AB;
        repeat (8) @(posedge clk_25);
        digits = 16'hCDEF;
        repeat (8) @(posedge clk_25);
        blank = 4'b0110;
        repeat (8) @(posedge clk_25);
        $finish;
    end
endmodule