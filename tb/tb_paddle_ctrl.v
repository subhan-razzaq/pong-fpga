`timescale 1ns / 1ps
module tb_paddle_ctrl();
    // Test constants, shared by the DUT instance and the checks
    localparam DELAY  = 8;   // move delay for this tb (real design uses 1,250,000)
    localparam HEIGHT = 6;   // paddle height in tiles

    reg clk;
    reg i_ce;
    reg i_btn_up;
    reg i_btn_dn;
    reg [5:0] i_tile_column;
    reg [4:0] i_tile_row;
    wire o_draw_flag;
    wire [4:0] o_paddleY;
    integer errors;

    // 100 MHz clock
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    paddle_ctrl #(.MOVE_DELAY(DELAY), .PADDLE_HEIGHT(HEIGHT)) paddle_ctrl_check(.clk(clk), .i_ce(i_ce), .i_tile_column(i_tile_column), .i_tile_row(i_tile_row), .i_btnU(i_btn_up), .i_btnD(i_btn_dn), .o_draw_flag(o_draw_flag), .o_paddleY(o_paddleY));

    // Watchdog: ends the sim if the tb ever hangs
    initial begin
        #20_000;
        $display("TEST FAILED: timeout");
        $finish;
    end

    // Compare paddle Y to the expected value, log and count any mismatch
    task check_y;
        input [4:0] expected;
        input [8*16-1:0] label;
        begin
            if (o_paddleY !== expected) begin
                $display("ERROR [%0s] at %0t ns: expected Y=%0d, got %0d", label, $time, expected, o_paddleY);
                errors = errors + 1;
            end
        end
    endtask

    // Compare the draw flag to the expected value, log and count any mismatch
    task check_draw;
        input expected;
        input [8*16-1:0] label;
        begin
            if (o_draw_flag !== expected) begin
                $display("ERROR [%0s] at %0t ns: col %0d row %0d expected draw %b, got %b", label, $time, i_tile_column, i_tile_row, expected, o_draw_flag);
                errors = errors + 1;
            end
        end
    endtask

    // Walk every row of one column and check draw against the current Y
    task sweep_draw;
        input [5:0] column;
        input on_paddle_col;
        input [8*16-1:0] label;
        integer row;
        integer y_now;
        begin
            y_now = o_paddleY;
            i_tile_column = column;
            for (row = 0; row < 30; row = row + 1) begin
                i_tile_row = row;
                #1;
                check_draw(on_paddle_col && (row >= y_now) && (row <= y_now + HEIGHT - 1), label);
            end
        end
    endtask

    initial begin
        errors        = 0;
        i_ce          = 1'b1;
        i_btn_up      = 1'b0;
        i_btn_dn      = 1'b0;
        i_tile_column = 6'd0;
        i_tile_row    = 5'd0;

        // 1. Idle: Y stays at the centered start value
        repeat (20) @(posedge clk); #1;
        check_y(5'd12, "idle");

        // 2. First move up: no move after DELAY-1 edges, move on edge DELAY
        @(negedge clk) i_btn_up = 1'b1;
        repeat (DELAY - 1) @(posedge clk); #1;
        check_y(5'd12, "up_early");
        @(posedge clk); #1;
        check_y(5'd11, "up_first");

        // 3. Continued hold: one more tile after another DELAY edges
        repeat (DELAY) @(posedge clk); #1;
        check_y(5'd10, "up_second");

        // 4. Release mid-count: the counter must restart from 0
        repeat (3) @(posedge clk);
        @(negedge clk) i_btn_up = 1'b0;
        @(negedge clk) i_btn_up = 1'b1;
        repeat (DELAY - 1) @(posedge clk); #1;
        check_y(5'd10, "restart_early");
        @(posedge clk); #1;
        check_y(5'd9, "restart_move");

        // 5. Both held: no movement
        @(negedge clk) i_btn_dn = 1'b1;
        repeat (3 * DELAY) @(posedge clk); #1;
        check_y(5'd9, "both_held");
        @(negedge clk) begin
            i_btn_up = 1'b0;
            i_btn_dn = 1'b0;
        end

        // 6. Draw at mid-screen, then a column with no paddle
        sweep_draw(6'd0, 1'b1, "draw_mid");
        sweep_draw(6'd1, 1'b0, "draw_col1");

        // 7. Top clamp: hold up well past the wall
        @(negedge clk) i_btn_up = 1'b1;
        repeat (DELAY * 30) @(posedge clk); #1;
        check_y(5'd0, "top_clamp");
        @(negedge clk) i_btn_up = 1'b0;
        sweep_draw(6'd0, 1'b1, "draw_top");

        // 8. Bottom clamp: hold down well past the wall
        @(negedge clk) i_btn_dn = 1'b1;
        repeat (DELAY * 30) @(posedge clk); #1;
        check_y(5'd24, "bottom_clamp");
        @(negedge clk) i_btn_dn = 1'b0;
        sweep_draw(6'd0, 1'b1, "draw_bottom");

        // Result
        if (errors == 0) begin
            $display("TEST PASSED");
        end
        else begin
            $display("TEST FAILED: %0d errors", errors);
        end
        $finish;
    end
endmodule