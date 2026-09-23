`timescale 1 ns / 1 ps
module seven_seg_mux(input wire clk, i_ce, input wire [15:0] i_digits, input wire [3:0] i_blank, output reg [6:0] o_seg = 7'b1111111, output reg [3:0] o_an = 4'b1111);
     reg [1:0] digit_sel = 2'd0;
     reg [3:0] display_digit;
     reg [3:0] next_an;
     wire [6:0] next_seg;
     seven_seg_decoder inst0(.i_hex(display_digit), .o_seg(next_seg));
     always@(*) begin
        case (digit_sel)
        2'b00: begin
            display_digit = i_digits[3:0];
            next_an = 4'b1110 | i_blank;
        end
        2'b01: begin
            display_digit = i_digits[7:4];
            next_an = 4'b1101 | i_blank;
        end
        2'b10: begin
            display_digit = i_digits[11:8];
            next_an = 4'b1011 | i_blank;
        end
        2'b11: begin
            display_digit = i_digits[15:12];
            next_an = 4'b0111 | i_blank;
        end
        endcase
    end
    always@(posedge clk) begin
        if (i_ce) begin
            digit_sel <= digit_sel + 1;
            o_an <= next_an;
            o_seg <= next_seg;
        end
    end
endmodule