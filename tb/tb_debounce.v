`timescale 1ns / 1ps
module tb_debounce();
    reg clk;
    reg i_btn;
    wire o_btn;
    integer errors;
    integer i;

    // 100 MHz clock
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    debounce #(.LIMIT(8)) debounce_check(.clk(clk), .i_btn(i_btn), .o_btn(o_btn));

    // Watchdog: ends the sim if the tb ever hangs
    initial begin
        #10_000;
        $display("TEST FAILED: timeout");
        $finish;
    end

    // Compare o_btn to the expected value, log and count any mismatch
    task check;
        input expected;
        input [8*16-1:0] label;
        begin
            if (o_btn !== expected) begin
                $display("ERROR [%0s] at %0t ns: expected %b, got %b", label, $time, expected, o_btn);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors = 0;
        i_btn  = 1'b0;

        // 1. Idle: output stays low
        repeat (20) @(posedge clk); #1;
        check(1'b0, "idle");

        // 2. Clean press: low after 9 edges, high after 10
        @(negedge clk) i_btn = 1'b1;
        repeat (9) @(posedge clk); #1;
        check(1'b0, "press_early");
        @(posedge clk); #1;
        check(1'b1, "press");

        // 3. Clean release
        @(negedge clk) i_btn = 1'b0;
        repeat (9) @(posedge clk); #1;
        check(1'b1, "release_early");
        @(posedge clk); #1;
        check(1'b0, "release");

        // 4. Bouncy press: 6 toggles of 3 edges each, ends low
        for (i = 0; i < 6; i = i + 1) begin
            @(negedge clk) i_btn = ~i_btn;
            repeat (3) @(posedge clk);
        end
        #1;
        check(1'b0, "bounce_press");
        @(negedge clk) i_btn = 1'b1;
        repeat (9) @(posedge clk); #1;
        check(1'b0, "bpress_early");
        @(posedge clk); #1;
        check(1'b1, "bpress");

        // 5. Short glitch low while pressed: must be ignored
        @(negedge clk) i_btn = 1'b0;
        repeat (4) @(posedge clk);
        @(negedge clk) i_btn = 1'b1;
        #1;
        check(1'b1, "glitch_mid");
        repeat (12) @(posedge clk); #1;
        check(1'b1, "glitch_after");

        // 6. Bouncy release: 6 toggles, ends high
        for (i = 0; i < 6; i = i + 1) begin
            @(negedge clk) i_btn = ~i_btn;
            repeat (3) @(posedge clk);
        end
        #1;
        check(1'b1, "bounce_release");
        @(negedge clk) i_btn = 1'b0;
        repeat (9) @(posedge clk); #1;
        check(1'b1, "brel_early");
        @(posedge clk); #1;
        check(1'b0, "brel");

        // Result
        if (errors == 0)
            $display("TEST PASSED");
        else
            $display("TEST FAILED: %0d errors", errors);
        $finish;
    end
endmodule