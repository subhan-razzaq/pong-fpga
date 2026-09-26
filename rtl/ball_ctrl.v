`timescale 1 ns / 1 ps
`default_nettype none
`include "vga_params.vh"
module ball_ctrl #(parameter MOVE_DELAY = 1_250_000) (input wire clk, i_ce, i_game_active,input wire [$clog2(`TILE_COLUMN) - 1:0] i_tile_column, input wire [$clog2(`TILE_ROW) - 1:0] i_tile_row, output wire o_draw_flag, output wire [$clog2(`TILE_COLUMN)-1:0] o_ball_x, output wire [$clog2(`TILE_ROW)-1:0] o_ball_y);
    reg [$clog2(MOVE_DELAY) - 1:0] move_counter = 0;
    reg dir_x = 1'b1, dir_y = 1'b1; // 1 = right, 1 = up
    reg [$clog2(`TILE_COLUMN)-1:0] ball_x = `CENTER_X; 
    reg [$clog2(`TILE_ROW)-1:0] ball_y = `CENTER_Y;
    always@(posedge clk) begin
        if (i_ce) begin
            if (~i_game_active) begin
                move_counter <= 0;
                dir_x <= 1'b1;
                dir_y <= 1'b1;
                ball_x <= `CENTER_X;
                ball_y <= `CENTER_Y;
            end 
            else begin
                if (move_counter == MOVE_DELAY - 1) begin
                    move_counter <= 0;
                    if (ball_y == `Y_MIN && dir_y) begin
                        dir_y <= ~dir_y;
                        ball_y <= ball_y + 1;
                    end
                    else if (ball_y == `Y_MAX && ~dir_y) begin
                        dir_y <= ~dir_y;
                        ball_y <= ball_y - 1; 
                    end
                    else begin
                        if (dir_y) begin
                            ball_y <= ball_y - 1;
                        end
                        else begin
                            ball_y <= ball_y + 1;
                        end
                    end
                    
                    if (ball_x == `X_MIN && ~dir_x) begin
                        dir_x <= ~dir_x;
                        ball_x <= ball_x + 1;
                    end
                    else if (ball_x == `X_MAX && dir_x) begin
                        dir_x <= ~dir_x;
                        ball_x <= ball_x - 1; 
                    end
                    else begin
                        if (dir_x) begin
                            ball_x <= ball_x + 1;
                        end
                        else begin
                            ball_x <= ball_x - 1;
                        end
                    end
                end
                else begin
                    move_counter <= move_counter + 1;
                end
            end
       end
    end
    assign o_draw_flag = (i_tile_column == ball_x && i_tile_row == ball_y);
    assign o_ball_x = ball_x;
    assign o_ball_y = ball_y;
endmodule
`default_nettype wire