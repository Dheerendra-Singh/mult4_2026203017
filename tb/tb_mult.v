`timescale 1ns/1ps
// Exhaustive self-checking testbench for mult_array (4x4 unsigned, latency = 2 cycles)
module tb_mult;
    reg        clk, rst_n;
    reg  [3:0] a, b;
    wire [7:0] p;

    integer i, j;
    integer errors  = 0;
    integer checked = 0;
    reg [7:0] expected;

    mult_array dut (.clk(clk), .rst_n(rst_n), .a(a), .b(b), .p(p));

    // 10 ns clock
    initial clk = 1'b0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("mult.vcd");
        $dumpvars(0, tb_mult);

        // hold reset low for the first 2 clock cycles
        rst_n = 1'b0;
        a = 4'd0;
        b = 4'd0;
        repeat (2) @(negedge clk);
        rst_n = 1'b1;

        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                @(negedge clk);
                a = i[3:0];
                b = j[3:0];
                expected = a * b;      // * allowed in the testbench only
                // inputs captured at next posedge, product captured one posedge later
                @(negedge clk);
                @(negedge clk);
                if (p !== expected) begin
                    $display("MISMATCH: a=%0d b=%0d expected=%0d got=%0d", a, b, expected, p);
                    errors = errors + 1;
                end
                checked = checked + 1;
            end
        end

        if (errors == 0)
            $display("PASS: %0d vectors checked, %0d errors", checked, errors);
        else
            $display("FAIL: %0d vectors checked, %0d errors", checked, errors);
        $finish;
    end
endmodule
