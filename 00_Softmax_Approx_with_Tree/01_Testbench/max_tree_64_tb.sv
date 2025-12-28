`timescale 1ns/1ps

module max_tree_64_tb;
    // Signals
    reg           i_clk;
    reg           i_en;
    reg           i_rst;

    reg    [1:0]  i_length_mode;
    reg    [63:0] i_valid;
    reg  [1023:0] i_in_flat;

    wire          o_valid_max;
    wire   [15:0] o_max64_0;
    wire   [15:0] o_max32_0, o_max32_1;
    wire   [15:0] o_max16_0, o_max16_1, o_max16_2, o_max16_3;
    wire    [1:0] o_length_mode_byp;
    wire   [63:0] o_valid_byp;
    wire [1023:0] o_in_byp;

    // Helper array to handle data easily in TB
    reg signed [15:0] test_data [0:63];

    // Clock Generation
    initial i_clk = 0;
    always #5 i_clk = ~i_clk;

    // Instantiate
    max_tree_64 max_tree_test(
        .i_clk(i_clk), 
        .i_en(i_en), 
        .i_rst(i_rst),

        .i_length_mode(i_length_mode),
        .i_valid(i_valid), 
        .i_in_flat(i_in_flat),

        .o_valid_max(o_valid_max),

        .o_max64_0(o_max64_0),

        .o_max32_0(o_max32_0), 
        .o_max32_1(o_max32_1),

        .o_max16_0(o_max16_0), 
        .o_max16_1(o_max16_1), 
        .o_max16_2(o_max16_2), 
        .o_max16_3(o_max16_3),

        .o_length_mode_byp(o_length_mode_byp),
        .o_valid_byp(o_valid_byp), 
        .o_in_byp(o_in_byp)
    );

    // Utility Tasks
    task put_data;
        input [1:0] mode;
        integer i;
        begin
            @(negedge i_clk);
            #2.5;
            i_length_mode = mode;
            i_valid = {64{1'b1}};
            for (i = 0; i < 64; i = i + 1) begin
                i_in_flat[i*16 +: 16] = test_data[i];
            end
            @(posedge i_clk);
            #2.5;
            i_valid = 1'b0;
        end
    endtask

    // Task to display fixed-point value as real number
    task display_fixed;
        input [15:0] val;
        real real_val;
        begin
            real_val = $itor($signed(val)) / 1024.0;
            $write("%f", real_val);
        end
    endtask

    always @(posedge i_clk) begin
        if (o_valid_max) begin
            $write("64_out :\n"); 
            display_fixed(o_max64_0); 
            $write("\n");
            
            $write("32_out :\n"); 
            display_fixed(o_max32_0); $write(" | ");
            display_fixed(o_max32_1);
            $write("\n");

            $write("16_out :\n"); 
            display_fixed(o_max16_0); $write(" | ");
            display_fixed(o_max16_1); $write(" | ");
            display_fixed(o_max16_2); $write(" | ");
            display_fixed(o_max16_3);
            $write("\n\n");
        end
    end

    // Main Stimulus
    integer k;
    initial begin
        // Reset
        i_rst         = 0; 
        i_en          = 0; 
        i_length_mode = 0; 
        i_valid       = 0; 
        i_in_flat     = 0;
        #20; 
        i_rst = 1;
        #10; 
        i_rst = 0;
        i_en  = 1;
        #20;

        // Test Case 1:
        for (k=0; k<64; k=k+1) test_data[k] = k; 
        test_data[0] = 500;
        put_data(2'd0);

        // Test Case 2:
        for (k=0; k<64; k=k+1) test_data[k] = 10;
        test_data[63] = 999;
        put_data(2'd0);

        // Test Case 3:
        for (k=0; k<64; k=k+1) test_data[k] = k;
        put_data(2'd1);

        // Test Case 4:
        for (k=0; k<64; k=k+1) test_data[k] = -100 + k; 
        put_data(2'd2);

        // Test Case 5:
        for (k=0; k<64; k=k+1) test_data[k] = k; 
        put_data(2'd2);

        // Test Case 6:
        for (k=0; k<64; k=k+1) test_data[k] = -500 - k;
        test_data[10] = -5;
        put_data(2'd0);

        // Wait for pipeline to drain
        repeat(10) @(posedge i_clk);
        $display("Simulation Finished.");
        $finish;
    end
endmodule