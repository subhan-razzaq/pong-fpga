`timescale 1 ns / 1 ps
module debounce#(parameter LIMIT = 1_000_000) (input wire clk, input wire i_btn, output wire o_btn);  // LIMIT MUST BE >= 2
    reg state = 1'b0;
    (* ASYNC_REG = "TRUE" *) reg btn_first = 1'b0;
    (* ASYNC_REG = "TRUE" *) reg btn_second = 1'b0;
    reg [$clog2(LIMIT) - 1:0] counter = 0;
    always@(posedge clk) begin
       btn_first <= i_btn;
       btn_second <= btn_first;
       if (btn_second == ~state) begin
            if (counter == LIMIT - 1) begin
                state <= btn_second;
                counter <= 0;
            end
            else begin
                counter <= counter + 1;
            end
       end
       else begin
            counter <= 0;
       end
    end
    assign o_btn = state;
endmodule