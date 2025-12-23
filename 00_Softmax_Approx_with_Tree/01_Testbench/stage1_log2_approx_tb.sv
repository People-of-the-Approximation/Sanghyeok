/*
16-bit fixed-point : Q4.12
stage1_log2_approx_tb (Testbench)
Description:
- Testbench for the stage1_log2_approx module.
- Generates clock, reset, enable, and valid signals to drive the DUT.
- Applies a sequence of 16-bit fixed-point test inputs representing various magnitudes.
- Uses display_fixed task to print real-number interpretations of inputs and outputs.
- Verifies log2 approximation behavior by displaying bypassed inputs and computed outputs.
*/

`timescale 1ns/1ps

module stage1_log2_approx_tb;
    // Operation signals
    reg         i_clk;
    reg         i_en;

    // Reset signal (active high)
    reg         i_rst;

    // Data input signals
    reg         i_valid;
    reg  [15:0] i_in0;
    reg  [15:0] i_in1;

    // Data output signals
    wire        o_valid;
    wire [15:0] o_log2_in0;

    // Bypass outputs
    wire [15:0] o_in0_bypass;
    wire [15:0] o_in1_bypass;

    // Clock generation
    initial i_clk = 0;
    always #5 i_clk = ~i_clk;


    stage1_log2_approx u_log2 (
        .i_valid     (i_valid),
        .i_clk       (i_clk),
        .i_rst       (i_rst),

        .i_en        (i_en),
        .i_in0       (i_in0),
        .i_in1       (i_in1),

        .o_valid     (o_valid),
        .o_log2_in0  (o_log2_in0),

        .o_in0_bypass(o_in0_bypass),
        .o_in1_bypass(o_in1_bypass)
    );

    // Task to display fixed-point value as real number
    task display_fixed;
        input [15:0] val;
        real real_val;
        begin
            real_val = $itor($signed(val)) / 1024.0;
            $write("%f", real_val);
        end
    endtask

    initial begin
        #2; i_rst = 1;
        #10; i_rst = 0;
        #10; i_en = 1;

        $display("==== log2_approx test ====");

        i_in0 = 16'b000000_0000000001;
        i_in1 = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; i_valid = 1'b0;
        #5;

        i_in0 = 16'b000000_0000000010;
        i_in1 = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; i_valid = 1'b0;
        #5;

        i_in0 = 16'b000000_0000000100;
        i_in1 = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; i_valid = 1'b0;
        #5;
        $write("Input: ");
        $write("\n");
        display_fixed(o_in0_bypass);
        $write("\n");
        display_fixed(o_in1_bypass);
        $write("\n");
        $write("-> Onput: ");
        display_fixed(o_log2_in0);
        $write("\n");

        i_in0 = 16'b000000_0000001000;
        i_in1 = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; i_valid = 1'b0;
        #5;
        $write("Input: ");
        $write("\n");
        display_fixed(o_in0_bypass);
        $write("\n");
        display_fixed(o_in1_bypass);
        $write("\n");
        $write("-> Onput: ");
        display_fixed(o_log2_in0);
        $write("\n");

        i_in0 = 16'b000000_0000010000;
        i_in1 = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; i_valid = 1'b0;
        #5;

        $write("Input: ");
        $write("\n");
        display_fixed(o_in0_bypass);
        $write("\n");
        display_fixed(o_in1_bypass);
        $write("\n");
        $write("-> Onput: ");
        display_fixed(o_log2_in0);
        $write("\n");

        i_in0 = 16'b000000_0000100000;
        i_in1 = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; i_valid = 1'b0;
        #5;

        $write("Input: ");
        $write("\n");
        display_fixed(o_in0_bypass);
        $write("\n");
        display_fixed(o_in1_bypass);
        $write("\n");
        $write("-> Onput: ");
        display_fixed(o_log2_in0);
        $write("\n");

        i_in0 = 16'b000000_0000110000;
        i_in1 = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; i_valid = 1'b0;
        #5;
        $write("Input: ");
        $write("\n");
        display_fixed(o_in0_bypass);
        $write("\n");
        display_fixed(o_in1_bypass);
        $write("\n");
        $write("-> Onput: ");
        display_fixed(o_log2_in0);
        $write("\n");

        i_in0 = 16'b000000_0001000000;
        i_in1 = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; i_valid = 1'b0;
        #5;
        $write("Input: ");
        $write("\n");
        display_fixed(o_in0_bypass);
        $write("\n");
        display_fixed(o_in1_bypass);
        $write("\n");
        $write("-> Onput: ");
        display_fixed(o_log2_in0);
        $write("\n");

        i_in0 = 16'b000000_0001010000;
        i_in1 = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; i_valid = 1'b0;
        #5;
        $write("Input: ");
        $write("\n");
        display_fixed(o_in0_bypass);
        $write("\n");
        display_fixed(o_in1_bypass);
        $write("\n");
        $write("-> Onput: ");
        display_fixed(o_log2_in0);
        $write("\n");

        i_in0 = 16'b000000_0001100000;
        i_in1 = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; i_valid = 1'b0;
        #5;
        $write("Input: ");
        $write("\n");
        display_fixed(o_in0_bypass);
        $write("\n");
        display_fixed(o_in1_bypass);
        $write("\n");
        $write("-> Onput: ");
        display_fixed(o_log2_in0);
        $write("\n");

        i_in0 = 16'b000000_0001110000;
        i_in1 = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; i_valid = 1'b0;
        #5;
        $write("Input: ");
        $write("\n");
        display_fixed(o_in0_bypass);
        $write("\n");
        display_fixed(o_in1_bypass);
        $write("\n");
        $write("-> Onput: ");
        display_fixed(o_log2_in0);
        $write("\n");

        i_in0 = 16'b000000_0010000000;
        i_in1 = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; i_valid = 1'b0;
        #5;
        $write("Input: ");
        $write("\n");
        display_fixed(o_in0_bypass);
        $write("\n");
        display_fixed(o_in1_bypass);
        $write("\n");
        $write("-> Onput: ");
        display_fixed(o_log2_in0);
        $write("\n");

        i_in0 = 16'b000000_0010100000;
        i_in1 = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; i_valid = 1'b0;
        #5;
        $write("Input: ");
        $write("\n");
        display_fixed(o_in0_bypass);
        $write("\n");
        display_fixed(o_in1_bypass);
        $write("\n");
        $write("-> Onput: ");
        display_fixed(o_log2_in0);
        $write("\n");

        i_in0 = 16'b000000_0011000000;
        i_in1 = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; i_valid = 1'b0;
        #5;
        $write("Input: ");
        $write("\n");
        display_fixed(o_in0_bypass);
        $write("\n");
        display_fixed(o_in1_bypass);
        $write("\n");
        $write("-> Onput: ");
        display_fixed(o_log2_in0);
        $write("\n");

        i_in0 = 16'b000000_0011100000;
        i_in1 = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; i_valid = 1'b0;
        #5;
        $write("Input: ");
        $write("\n");
        display_fixed(o_in0_bypass);
        $write("\n");
        display_fixed(o_in1_bypass);
        $write("\n");
        $write("-> Onput: ");
        display_fixed(o_log2_in0);
        $write("\n");

        i_in0 = 16'b000000_0100000000;
        i_in1 = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; i_valid = 1'b0;
        #5;
        $write("Input: ");
        $write("\n");
        display_fixed(o_in0_bypass);
        $write("\n");
        display_fixed(o_in1_bypass);
        $write("\n");
        $write("-> Onput: ");
        display_fixed(o_log2_in0);
        $write("\n");

        i_in0 = 16'b000000_0101000000;
        i_in1 = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; i_valid = 1'b0;
        #5;
        $write("Input: ");
        $write("\n");
        display_fixed(o_in0_bypass);
        $write("\n");
        display_fixed(o_in1_bypass);
        $write("\n");
        $write("-> Onput: ");
        display_fixed(o_log2_in0);
        $write("\n");

        i_in0 = 16'b000000_0110000000;
        i_in1 = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; i_valid = 1'b0;
        #5;
        $write("Input: ");
        $write("\n");
        display_fixed(o_in0_bypass);
        $write("\n");
        display_fixed(o_in1_bypass);
        $write("\n");
        $write("-> Onput: ");
        display_fixed(o_log2_in0);
        $write("\n");

        i_in0 = 16'b000000_0111000000;
        i_in1 = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; i_valid = 1'b0;
        #5;
        $write("Input: ");
        $write("\n");
        display_fixed(o_in0_bypass);
        $write("\n");
        display_fixed(o_in1_bypass);
        $write("\n");
        $write("-> Onput: ");
        display_fixed(o_log2_in0);
        $write("\n");

        i_in0 = 16'b000000_1000000000;
        i_in1 = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; i_valid = 1'b0;
        #5;
        $write("Input: ");
        $write("\n");
        display_fixed(o_in0_bypass);
        $write("\n");
        display_fixed(o_in1_bypass);
        $write("\n");
        $write("-> Onput: ");
        display_fixed(o_log2_in0);
        $write("\n");

        i_in0 = 16'b111111_0000000000;
        i_in1 = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; i_valid = 1'b0;
        #5;
        $write("Input: ");
        $write("\n");
        display_fixed(o_in0_bypass);
        $write("\n");
        display_fixed(o_in1_bypass);
        $write("\n");
        $write("-> Onput: ");
        display_fixed(o_log2_in0);
        $write("\n");

        i_in0 = 16'b000000_1010000000;
        i_in1 = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; i_valid = 1'b0;
        #5;
        $write("Input: ");
        $write("\n");
        display_fixed(o_in0_bypass);
        $write("\n");
        display_fixed(o_in1_bypass);
        $write("\n");
        $write("-> Onput: ");
        display_fixed(o_log2_in0);
        $write("\n");

        i_in0 = 16'b000000_1100000000;
        i_in1 = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; i_valid = 1'b0;
        #5;
        $write("Input: ");
        $write("\n");
        display_fixed(o_in0_bypass);
        $write("\n");
        display_fixed(o_in1_bypass);
        $write("\n");
        $write("-> Onput: ");
        display_fixed(o_log2_in0);
        $write("\n");

        i_in0 = 16'b000000_1110000000;
        i_in1 = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; i_valid = 1'b0;
        #5;
        $write("Input: ");
        $write("\n");
        display_fixed(o_in0_bypass);
        $write("\n");
        display_fixed(o_in1_bypass);
        $write("\n");
        $write("-> Onput: ");
        display_fixed(o_log2_in0);
        $write("\n");

        i_in0 = 16'b000001_0000000000;
        i_in1 = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; i_valid = 1'b0;
        #5;
        $write("Input: ");
        $write("\n");
        display_fixed(o_in0_bypass);
        $write("\n");
        display_fixed(o_in1_bypass);
        $write("\n");
        $write("-> Onput: ");
        display_fixed(o_log2_in0);
        $write("\n");

        i_in0 = 16'b000001_0100000000;
        i_in1 = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; i_valid = 1'b0;
        #5;
        $write("Input: ");
        $write("\n");
        display_fixed(o_in0_bypass);
        $write("\n");
        display_fixed(o_in1_bypass);
        $write("\n");
        $write("-> Onput: ");
        display_fixed(o_log2_in0);
        $write("\n");

        i_in0 = 16'b000001_1000000000;
        i_in1 = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; i_valid = 1'b0;
        #5;
        $write("Input: ");
        $write("\n");
        display_fixed(o_in0_bypass);
        $write("\n");
        display_fixed(o_in1_bypass);
        $write("\n");
        $write("-> Onput: ");
        display_fixed(o_log2_in0);
        $write("\n");

        i_in0 = 16'b000001_1100000000;
        i_in1 = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; i_valid = 1'b0;
        #5;
        $write("Input: ");
        $write("\n");
        display_fixed(o_in0_bypass);
        $write("\n");
        display_fixed(o_in1_bypass);
        $write("\n");
        $write("-> Onput: ");
        display_fixed(o_log2_in0);
        $write("\n");

        i_in0 = 16'b000010_0000000000;
        i_in1 = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; i_valid = 1'b0;
        #5;
        $write("Input: ");
        $write("\n");
        display_fixed(o_in0_bypass);
        $write("\n");
        display_fixed(o_in1_bypass);
        $write("\n");
        $write("-> Onput: ");
        display_fixed(o_log2_in0);
        $write("\n");

        i_in0 = 16'b000010_0100000000;
        i_in1 = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; i_valid = 1'b0;
        #5;
        $write("Input: ");
        $write("\n");
        display_fixed(o_in0_bypass);
        $write("\n");
        display_fixed(o_in1_bypass);
        $write("\n");
        $write("-> Onput: ");
        display_fixed(o_log2_in0);
        $write("\n");

        i_in0 = 16'b000010_1000000000;
        i_in1 = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; i_valid = 1'b0;
        #5;
        $write("Input: ");
        $write("\n");
        display_fixed(o_in0_bypass);
        $write("\n");
        display_fixed(o_in1_bypass);
        $write("\n");
        $write("-> Onput: ");
        display_fixed(o_log2_in0);
        $write("\n");

        i_in0 = 16'b000010_1100000000;
        i_in1 = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; i_valid = 1'b0;
        #5;
        $write("Input: ");
        $write("\n");
        display_fixed(o_in0_bypass);
        $write("\n");
        display_fixed(o_in1_bypass);
        $write("\n");
        $write("-> Onput: ");
        display_fixed(o_log2_in0);
        $write("\n");

        i_in0 = 16'b000011_0000000000;
        i_in1 = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; i_valid = 1'b0;
        #5;
        $write("Input: ");
        $write("\n");
        display_fixed(o_in0_bypass);
        $write("\n");
        display_fixed(o_in1_bypass);
        $write("\n");
        $write("-> Onput: ");
        display_fixed(o_log2_in0);
        $write("\n");

        i_in0 = 16'b000011_0100000000;
        i_in1 = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; i_valid = 1'b0;
        #5;
        $write("Input: ");
        $write("\n");
        display_fixed(o_in0_bypass);
        $write("\n");
        display_fixed(o_in1_bypass);
        $write("\n");
        $write("-> Onput: ");
        display_fixed(o_log2_in0);
        $write("\n");

        i_in0 = 16'b000011_1000000000;
        i_in1 = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; i_valid = 1'b0;
        #5;
        $write("Input: ");
        $write("\n");
        display_fixed(o_in0_bypass);
        $write("\n");
        display_fixed(o_in1_bypass);
        $write("\n");
        $write("-> Onput: ");
        display_fixed(o_log2_in0);
        $write("\n");

        i_in0 = 16'b000011_1100000000;
        i_in1 = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; i_valid = 1'b0;
        #5;
        $write("Input: ");
        $write("\n");
        display_fixed(o_in0_bypass);
        $write("\n");
        display_fixed(o_in1_bypass);
        $write("\n");
        $write("-> Onput: ");
        display_fixed(o_log2_in0);
        $write("\n");

        i_in0 = 16'b000100_0000000000;
        i_in1 = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; i_valid = 1'b0;
        #5;
        $write("Input: ");
        $write("\n");
        display_fixed(o_in0_bypass);
        $write("\n");
        display_fixed(o_in1_bypass);
        $write("\n");
        $write("-> Onput: ");
        display_fixed(o_log2_in0);
        $write("\n");

        i_in0 = 16'b000100_0100000000;
        i_in1 = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; i_valid = 1'b0;
        #5;
        $write("Input: ");
        $write("\n");
        display_fixed(o_in0_bypass);
        $write("\n");
        display_fixed(o_in1_bypass);
        $write("\n");
        $write("-> Onput: ");
        display_fixed(o_log2_in0);
        $write("\n");

        i_in0 = 16'b000100_1000000000;
        i_in1 = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; i_valid = 1'b0;
        #5;
        $write("Input: ");
        $write("\n");
        display_fixed(o_in0_bypass);
        $write("\n");
        display_fixed(o_in1_bypass);
        $write("\n");
        $write("-> Onput: ");
        display_fixed(o_log2_in0);
        $write("\n");

        i_in0 = 16'b000100_1100000000;
        i_in1 = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; i_valid = 1'b0;
        #5;
        $write("Input: ");
        $write("\n");
        display_fixed(o_in0_bypass);
        $write("\n");
        display_fixed(o_in1_bypass);
        $write("\n");
        $write("-> Onput: ");
        display_fixed(o_log2_in0);
        $write("\n");

        i_in0 = 16'b000101_0000000000;
        i_in1 = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; i_valid = 1'b0;
        #5;
        $write("Input: ");
        $write("\n");
        display_fixed(o_in0_bypass);
        $write("\n");
        display_fixed(o_in1_bypass);
        $write("\n");
        $write("-> Onput: ");
        display_fixed(o_log2_in0);
        $write("\n");

        i_in0 = 16'b001111_0000000000;
        i_in1 = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; i_valid = 1'b0;
        #5;
        $write("Input: ");
        $write("\n");
        display_fixed(o_in0_bypass);
        $write("\n");
        display_fixed(o_in1_bypass);
        $write("\n");
        $write("-> Onput: ");
        display_fixed(o_log2_in0);
        $write("\n");

        i_in0 = 16'b011111_0000000000;
        i_in1 = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; i_valid = 1'b0;
        #5;
        $write("Input: ");
        $write("\n");
        display_fixed(o_in0_bypass);
        $write("\n");
        display_fixed(o_in1_bypass);
        $write("\n");
        $write("-> Onput: ");
        display_fixed(o_log2_in0);
        $write("\n");

        i_in0 = 16'b011111_1111111111;
        i_in1 = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; i_valid = 1'b0;
        #5;
        $write("Input: ");
        $write("\n");
        display_fixed(o_in0_bypass);
        $write("\n");
        display_fixed(o_in1_bypass);
        $write("\n");
        $write("-> Onput: ");
        display_fixed(o_log2_in0);
        $write("\n");

        i_in0 = 16'b100000_0000000000;
        i_in1 = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; i_valid = 1'b0;
        #5;
        $write("Input: ");
        $write("\n");
        display_fixed(o_in0_bypass);
        $write("\n");
        display_fixed(o_in1_bypass);
        $write("\n");
        $write("-> Onput: ");
        display_fixed(o_log2_in0);
        $write("\n");

        i_in0 = 16'b111111_0000000000;
        i_in1 = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; i_valid = 1'b0;
        #5;
        $write("Input: ");
        $write("\n");
        display_fixed(o_in0_bypass);
        $write("\n");
        display_fixed(o_in1_bypass);
        $write("\n");
        $write("-> Onput: ");
        display_fixed(o_log2_in0);
        $write("\n");

        #10;
        $write("Input: ");
        $write("\n");
        display_fixed(o_in0_bypass);
        $write("\n");
        display_fixed(o_in1_bypass);
        $write("\n");
        $write("-> Onput: ");
        display_fixed(o_log2_in0);
        $write("\n");

        #10;    
        $write("Input: ");
        $write("\n");
        display_fixed(o_in0_bypass);
        $write("\n");
        display_fixed(o_in1_bypass);
        $write("\n");
        $write("-> Onput: ");
        display_fixed(o_log2_in0);
        $write("\n");
        #10;

        $finish;
    end
endmodule