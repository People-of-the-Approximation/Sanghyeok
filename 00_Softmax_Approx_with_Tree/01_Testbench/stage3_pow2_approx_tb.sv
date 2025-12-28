`timescale 1ns/1ps

module stage3_pow2_approx_tb;
    // Operation signals
    reg         i_clk;
    reg         i_en;
    // Reset signal (active high)
    reg         i_rst;

    // Data input signals
    reg         i_valid;
    reg  [15:0] i_x;

    // Data output signals
    wire        o_valid;
    wire [15:0] o_pow_x;
    // Bypass outputs
    wire [15:0] o_x_bypass;

    // Clock generation
    initial i_clk = 0;
    always #5 i_clk = ~i_clk;

    stage3_pow2_approx u_pow2 (
        .i_clk(i_clk),
        .i_en(i_en),
        .i_rst(i_rst),
        
        .i_valid(i_valid),
        .i_x(i_x),

        .o_valid(o_valid),
        .o_pow_x(o_pow_x),
        .o_x_bypass(o_x_bypass)
    );

    task display_fixed;
        input [15:0] val;
        real real_val;
        begin
            real_val = $itor($signed(val)) / 1024.0;
            $write("%f", real_val);
        end
    endtask

    task display_output;
        input [15:0] o_x_bypass;
        input [15:0] o_pow_x;

        begin
            $write("Input: \n");
            display_fixed(o_x_bypass);
            $write("\n");
            $write("Output: \n");
            display_fixed(o_pow_x);
            $write("\n");
        end
    endtask

    initial begin
        i_en    = 0;
        i_rst   = 0;
        i_valid = 0;
        i_x     = 16'd0;
        #2.5;
        i_rst   = 1; #5; 
        i_rst   = 0; #17.5;
    end

    initial begin
        #22.5;
        i_en    = 1;

        $display("==== pow2_approx test ====");

        i_x     = 16'b100000_0000000000;
        i_valid = 1'b1; #5; 
        i_valid = 1'b0; #5;

        i_x     = 16'b100011_0000000000;
        i_valid = 1'b1; #5; 
        i_valid = 1'b0; #5;

        i_x     = 16'b100110_0000000000;
        i_valid = 1'b1; #5; 
        i_valid = 1'b0; #5;
        display_output(o_x_bypass, o_pow_x);

        i_x     = 16'b101000_0000000000;
        i_valid = 1'b1; #5; 
        i_valid = 1'b0; #5;
        display_output(o_x_bypass, o_pow_x);

        i_x     = 16'b111100_1000000000;
        i_valid = 1'b1; #5; 
        i_valid = 1'b0; #5;
        display_output(o_x_bypass, o_pow_x);

        i_x     = 16'b111101_0000000000;
        i_valid = 1'b1; #5; 
        i_valid = 1'b0; #5;
        display_output(o_x_bypass, o_pow_x);

        i_x     = 16'b111101_1000000000;
        i_valid = 1'b1; #5; 
        i_valid = 1'b0; #5;
        display_output(o_x_bypass, o_pow_x);

        i_x     = 16'b111110_0000000000;
        i_valid = 1'b1; #5; 
        i_valid = 1'b0; #5;
        display_output(o_x_bypass, o_pow_x);

        i_x     = 16'b111110_0100000000;
        i_valid = 1'b1; #5; 
        i_valid = 1'b0; #5;
        display_output(o_x_bypass, o_pow_x);

        i_x     = 16'b111110_1000000000;
        i_valid = 1'b1; #5; 
        i_valid = 1'b0; #5;
        display_output(o_x_bypass, o_pow_x);

        i_x     = 16'b111110_1100000000;
        i_valid = 1'b1; #5; 
        i_valid = 1'b0; #5;
        display_output(o_x_bypass, o_pow_x);

        i_x     = 16'b111111_0000000000;
        i_valid = 1'b1; #5; 
        i_valid = 1'b0; #5;
        display_output(o_x_bypass, o_pow_x);

        i_x     = 16'b111111_0100000000;
        i_valid = 1'b1; #5; 
        i_valid = 1'b0; #5;
        display_output(o_x_bypass, o_pow_x);

        i_x     = 16'b111111_1000000000;
        i_valid = 1'b1; #5; 
        i_valid = 1'b0; #5;
        display_output(o_x_bypass, o_pow_x);

        i_x     = 16'b111111_1100000000;
        i_valid = 1'b1; #5; 
        i_valid = 1'b0; #5;
        display_output(o_x_bypass, o_pow_x);

        i_x     = 16'b000000_0000000000;
        i_valid = 1'b1; #5; 
        i_valid = 1'b0; #5;
        display_output(o_x_bypass, o_pow_x);

        i_x     = 16'b000000_0100000000;
        i_valid = 1'b1; #5; 
        i_valid = 1'b0; #5;
        display_output(o_x_bypass, o_pow_x);

        i_x     = 16'b000000_1000000000;
        i_valid = 1'b1; #5; 
        i_valid = 1'b0; #5;
        display_output(o_x_bypass, o_pow_x);

        i_x     = 16'b000000_1100000000;
        i_valid = 1'b1; #5; 
        i_valid = 1'b0; #5;
        display_output(o_x_bypass, o_pow_x);

        i_x     = 16'b000001_0000000000;
        i_valid = 1'b1; #5; 
        i_valid = 1'b0; #5;
        display_output(o_x_bypass, o_pow_x);

        i_x     = 16'b000001_0100000000;
        i_valid = 1'b1; #5; 
        i_valid = 1'b0; #5;
        display_output(o_x_bypass, o_pow_x);

        i_x     = 16'b000001_1000000000;
        i_valid = 1'b1; #5; 
        i_valid = 1'b0; #5;
        display_output(o_x_bypass, o_pow_x);

        i_x     = 16'b000001_1100000000;
        i_valid = 1'b1; #5; 
        i_valid = 1'b0; #5;
        display_output(o_x_bypass, o_pow_x);

        i_x     = 16'b000010_0000000000;
        i_valid = 1'b1; #5; 
        i_valid = 1'b0; #5;
        display_output(o_x_bypass, o_pow_x);

        i_x     = 16'b000010_0010000000;
        i_valid = 1'b1; #5; 
        i_valid = 1'b0; #5;
        display_output(o_x_bypass, o_pow_x);

        i_x     = 16'b000010_0100000000;
        i_valid = 1'b1; #5; 
        i_valid = 1'b0; #5;
        display_output(o_x_bypass, o_pow_x);

        i_x     = 16'b000010_0110000000;
        i_valid = 1'b1; #5; 
        i_valid = 1'b0; #5;
        display_output(o_x_bypass, o_pow_x);

        i_x     = 16'b000010_1000000000;
        i_valid = 1'b1; #5; 
        i_valid = 1'b0; #5;
        display_output(o_x_bypass, o_pow_x);

        i_x     = 16'b000010_1010000000;
        i_valid = 1'b1; #5; 
        i_valid = 1'b0; #5;
        display_output(o_x_bypass, o_pow_x);

        i_x     = 16'b000010_1100000000;
        i_valid = 1'b1; #5; 
        i_valid = 1'b0; #5;
        display_output(o_x_bypass, o_pow_x);

        i_x     = 16'b000011_1100000000;
        i_valid = 1'b1; #5; 
        i_valid = 1'b0; #5;
        display_output(o_x_bypass, o_pow_x);

        i_x     = 16'b000100_1100101110;
        i_valid = 1'b1; #5; 
        i_valid = 1'b0; #5;
        display_output(o_x_bypass, o_pow_x);

        i_x     = 16'b000100_1111111111;
        i_valid = 1'b1; #5; 
        i_valid = 1'b0; #5;
        display_output(o_x_bypass, o_pow_x);
        #10;

        display_output(o_x_bypass, o_pow_x);
        #10;

        $finish;
    end
endmodule