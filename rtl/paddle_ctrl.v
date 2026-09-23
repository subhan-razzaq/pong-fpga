`timescale 1 ns / 1 ps
module paddle_ctrl #(parameter PADDLEX = 0, PADDLE_HEIGHT = 6, GAME_HEIGHT = 30, GAME_WIDTH = 40, MOVE_DELAY = 1_250_000)(input wire clk, i_ce, input wire [$clog2(GAME_WIDTH) - 1:0] i_tile_column, input wire [$clog2(GAME_HEIGHT) - 1:0] i_tile_row, input wire i_btnU, i_btnD, output wire o_draw_flag, output wire [$clog2(GAME_HEIGHT) - 1:0] o_paddleY);
    reg [$clog2(MOVE_DELAY) - 1:0] move_counter = 0;
    reg [$clog2(GAME_HEIGHT) - 1:0] posY = (GAME_HEIGHT - PADDLE_HEIGHT) / 2;
    always@(posedge clk) begin
        if (i_ce) begin
            if (i_btnU & ~i_btnD) begin
                if (move_counter == MOVE_DELAY - 1) begin
                    move_counter <= 0;
                    if (posY > 0) begin
                        posY <= posY - 1;
                    end
                end
                else begin
                    move_counter <= move_counter + 1;
                end
            end
            else if (~i_btnU & i_btnD) begin
                if (move_counter == MOVE_DELAY - 1) begin
                    move_counter <= 0;
                    if (posY < GAME_HEIGHT - PADDLE_HEIGHT) begin
                        posY <= posY + 1;
                    end
                end
                else begin
                    move_counter <= move_counter + 1;
                end
            end
            else begin
                move_counter <= 0;
            end
        end
    end
    assign o_paddleY = posY;
    assign o_draw_flag = (i_tile_column == PADDLEX && i_tile_row >= posY && i_tile_row <= posY + PADDLE_HEIGHT - 1) ? 1'b1 : 1'b0;
endmodule