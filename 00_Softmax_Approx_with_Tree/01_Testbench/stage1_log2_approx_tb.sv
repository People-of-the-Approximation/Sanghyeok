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
    wire [15:0] o_in0_byp;
    wire [15:0] o_in1_byp;

    // Clock generation
    initial i_clk = 0;
    always #5 i_clk = ~i_clk;

    stage1_log2_approx u_log2 (
        .i_clk      (i_clk),
        .i_en       (i_en),
        .i_rst      (i_rst),
        
        .i_valid    (i_valid),
        .i_in0      (i_in0),
        .i_in1      (i_in1),

        .o_valid    (o_valid),
        .o_log2_in0 (o_log2_in0),

        .o_in0_byp  (o_in0_byp),
        .o_in1_byp  (o_in1_byp)
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

    task display_output;
        input [15:0] in0;
        input [15:0] in1;
        input [15:0] out;
        begin
            $write("Input:\n");
            $write("-> in0 : ");
            display_fixed(in0);
            $write("\n");
            $write("-> in1 : ");
            display_fixed(in1);
            $write("\n");
            $write("Output: \n");
            $write("-> out : ");
            display_fixed(out);
            $write("\n");
        end
    endtask

    initial begin
        i_en    = 0;
        i_rst   = 0;
        i_valid = 0;
        i_in0   = 16'd0;
        i_in1   = 16'd0;
        #5; 
        i_rst   = 1; #10;
        i_rst   = 0; #10;
    end

    initial begin
        #22.5;
        i_en    = 1;
        $display("==== log2_approx test ====");
        i_in0   = 16'b000000_0000000001;
        i_in1   = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; 
        i_valid = 1'b0;
        #5;

        i_in0   = 16'b000000_0000000010;
        i_in1   = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; 
        i_valid = 1'b0;
        #5;

        i_in0   = 16'b000000_0000000100;
        i_in1   = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; 
        i_valid = 1'b0;
        #5;
        display_output(o_in0_byp, o_in1_byp, o_log2_in0);

        i_in0   = 16'b000000_0000001000;
        i_in1   = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; 
        i_valid = 1'b0;
        #5;
        display_output(o_in0_byp, o_in1_byp, o_log2_in0);

        i_in0   = 16'b000000_0000010000;
        i_in1   = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; 
        i_valid = 1'b0;
        #5;
        display_output(o_in0_byp, o_in1_byp, o_log2_in0);

        i_in0   = 16'b000000_0000100000;
        i_in1   = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; 
        i_valid = 1'b0;
        #5;
        display_output(o_in0_byp, o_in1_byp, o_log2_in0);

        i_in0   = 16'b000000_0000110000;
        i_in1   = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; 
        i_valid = 1'b0;
        #5;
        display_output(o_in0_byp, o_in1_byp, o_log2_in0);

        i_in0   = 16'b000000_0001000000;
        i_in1   = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; 
        i_valid = 1'b0;
        #5;
        display_output(o_in0_byp, o_in1_byp, o_log2_in0);

        i_in0   = 16'b000000_0001010000;
        i_in1   = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; 
        i_valid = 1'b0;
        #5;
        display_output(o_in0_byp, o_in1_byp, o_log2_in0);

        i_in0   = 16'b000000_0001100000;
        i_in1   = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; 
        i_valid = 1'b0;
        #5;
        display_output(o_in0_byp, o_in1_byp, o_log2_in0);

        i_in0   = 16'b000000_0001110000;
        i_in1   = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; 
        i_valid = 1'b0;
        #5;
        display_output(o_in0_byp, o_in1_byp, o_log2_in0);

        i_in0   = 16'b000000_0010000000;
        i_in1   = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; 
        i_valid = 1'b0;
        #5;
        display_output(o_in0_byp, o_in1_byp, o_log2_in0);

        i_in0   = 16'b000000_0010100000;
        i_in1   = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; 
        i_valid = 1'b0;
        #5;
        display_output(o_in0_byp, o_in1_byp, o_log2_in0);

        i_in0   = 16'b000000_0011000000;
        i_in1   = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; 
        i_valid = 1'b0;
        #5;
        display_output(o_in0_byp, o_in1_byp, o_log2_in0);

        i_in0   = 16'b000000_0011100000;
        i_in1   = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; 
        i_valid = 1'b0;
        #5;
        display_output(o_in0_byp, o_in1_byp, o_log2_in0);

        i_in0   = 16'b000000_0100000000;
        i_in1   = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; 
        i_valid = 1'b0;
        #5;
        display_output(o_in0_byp, o_in1_byp, o_log2_in0);

        i_in0   = 16'b000000_0101000000;
        i_in1   = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; 
        i_valid = 1'b0;
        #5;
        display_output(o_in0_byp, o_in1_byp, o_log2_in0);

        i_in0   = 16'b000000_0110000000;
        i_in1   = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; 
        i_valid = 1'b0;
        #5;
        display_output(o_in0_byp, o_in1_byp, o_log2_in0);

        i_in0   = 16'b000000_0111000000;
        i_in1   = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; 
        i_valid = 1'b0;
        #5;
        display_output(o_in0_byp, o_in1_byp, o_log2_in0);

        i_in0   = 16'b000000_1000000000;
        i_in1   = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; 
        i_valid = 1'b0;
        #5;
        display_output(o_in0_byp, o_in1_byp, o_log2_in0);

        i_in0   = 16'b000000_1010000000;
        i_in1   = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; 
        i_valid = 1'b0;
        #5;
        display_output(o_in0_byp, o_in1_byp, o_log2_in0);

        i_in0   = 16'b000000_1100000000;
        i_in1   = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; 
        i_valid = 1'b0;
        #5;
        display_output(o_in0_byp, o_in1_byp, o_log2_in0);

        i_in0   = 16'b000000_1110000000;
        i_in1   = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; 
        i_valid = 1'b0;
        #5;
        display_output(o_in0_byp, o_in1_byp, o_log2_in0);

        i_in0   = 16'b000001_0000000000;
        i_in1   = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; 
        i_valid = 1'b0;
        #5;
        display_output(o_in0_byp, o_in1_byp, o_log2_in0);

        i_in0   = 16'b000001_0100000000;
        i_in1   = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; 
        i_valid = 1'b0;
        #5;
        display_output(o_in0_byp, o_in1_byp, o_log2_in0);

        i_in0   = 16'b000001_1000000000;
        i_in1   = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; 
        i_valid = 1'b0;
        #5;
        display_output(o_in0_byp, o_in1_byp, o_log2_in0);

        i_in0   = 16'b000001_1100000000;
        i_in1   = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; 
        i_valid = 1'b0;
        #5;
        display_output(o_in0_byp, o_in1_byp, o_log2_in0);

        i_in0   = 16'b000010_0000000000;
        i_in1   = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; 
        i_valid = 1'b0;
        #5;
        display_output(o_in0_byp, o_in1_byp, o_log2_in0);

        i_in0   = 16'b000010_0100000000;
        i_in1   = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; 
        i_valid = 1'b0;
        #5;
        display_output(o_in0_byp, o_in1_byp, o_log2_in0);

        i_in0   = 16'b000010_1000000000;
        i_in1   = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; 
        i_valid = 1'b0;
        #5;
        display_output(o_in0_byp, o_in1_byp, o_log2_in0);

        i_in0   = 16'b000010_1100000000;
        i_in1   = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; 
        i_valid = 1'b0;
        #5;
        display_output(o_in0_byp, o_in1_byp, o_log2_in0);

        i_in0   = 16'b000011_0000000000;
        i_in1   = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; 
        i_valid = 1'b0;
        #5;
        display_output(o_in0_byp, o_in1_byp, o_log2_in0);

        i_in0   = 16'b000011_0100000000;
        i_in1   = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; 
        i_valid = 1'b0;
        #5;
        display_output(o_in0_byp, o_in1_byp, o_log2_in0);

        i_in0   = 16'b000011_1000000000;
        i_in1   = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; 
        i_valid = 1'b0;
        #5;
        display_output(o_in0_byp, o_in1_byp, o_log2_in0);

        i_in0   = 16'b000011_1100000000;
        i_in1   = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; 
        i_valid = 1'b0;
        #5;
        display_output(o_in0_byp, o_in1_byp, o_log2_in0);

        i_in0   = 16'b000100_0000000000;
        i_in1   = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; 
        i_valid = 1'b0;
        #5;
        display_output(o_in0_byp, o_in1_byp, o_log2_in0);

        i_in0   = 16'b000100_0100000000;
        i_in1   = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; 
        i_valid = 1'b0;
        #5;
        display_output(o_in0_byp, o_in1_byp, o_log2_in0);

        i_in0   = 16'b000100_1000000000;
        i_in1   = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; 
        i_valid = 1'b0;
        #5;
        display_output(o_in0_byp, o_in1_byp, o_log2_in0);

        i_in0   = 16'b000100_1100000000;
        i_in1   = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; 
        i_valid = 1'b0;
        #5;
        display_output(o_in0_byp, o_in1_byp, o_log2_in0);

        i_in0   = 16'b000101_0000000000;
        i_in1   = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; 
        i_valid = 1'b0;
        #5;
        display_output(o_in0_byp, o_in1_byp, o_log2_in0);

        i_in0   = 16'b001000_0000000000;
        i_in1   = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; 
        i_valid = 1'b0;
        #5;
        display_output(o_in0_byp, o_in1_byp, o_log2_in0);

        i_in0   = 16'b001010_0000000000;
        i_in1   = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; 
        i_valid = 1'b0;
        #5;
        display_output(o_in0_byp, o_in1_byp, o_log2_in0);

        i_in0   = 16'b010000_0000000000;
        i_in1   = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; 
        i_valid = 1'b0;
        #5;
        display_output(o_in0_byp, o_in1_byp, o_log2_in0);
        
        i_in0   = 16'b010101_0000000000;
        i_in1   = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; 
        i_valid = 1'b0;
        #5;

        display_output(o_in0_byp, o_in1_byp, o_log2_in0);
        i_in0   = 16'b011111_0000000000;
        i_in1   = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; 
        i_valid = 1'b0;
        #5;
        display_output(o_in0_byp, o_in1_byp, o_log2_in0);

        i_in0   = 16'b011111_1111111111;
        i_in1   = 16'b000000_0001000000;
        i_valid = 1'b1;
        #5; 
        i_valid = 1'b0;
        #5;
        display_output(o_in0_byp, o_in1_byp, o_log2_in0);
        #10;

        display_output(o_in0_byp, o_in1_byp, o_log2_in0);
        #10;

        display_output(o_in0_byp, o_in1_byp, o_log2_in0);
        #10;

        $finish;
    end
endmodule