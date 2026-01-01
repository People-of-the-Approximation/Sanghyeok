`timescale 1ns/1ps

module acc_module_tb;
    // Signals
    reg           i_clk;
    reg           i_en;
    reg           i_rst;
    
    reg    [3:0]  i_length_mode;
    reg           i_valid;
    reg  [1023:0] i_in0_flat; // Bypass용 데이터
    reg  [1023:0] i_in1_flat; // Summation용 데이터

    wire   [31:0] o_global_sum;
    wire   [31:0] o_sum64_0;
    wire   [31:0] o_sum32_0, o_sum32_1;
    wire   [31:0] o_sum16_0, o_sum16_1, o_sum16_2, o_sum16_3;
    wire   [3:0]  o_length_mode_byp;
    wire          o_valid_byp;
    wire [1023:0] o_in0_byp;

    // Helper array to handle data easily in TB
    reg signed [15:0] test_data [0:63];

    // Clock Generation
    initial i_clk = 0;
    always #5 i_clk = ~i_clk;

    // Instantiate add_tree_64
    acc_module acc_module_test(
        .i_clk(i_clk), 
        .i_en(i_en), 
        .i_rst(i_rst),

        .i_length_mode(i_length_mode),
        .i_valid(i_valid), 
        .i_in0_flat(i_in0_flat),
        .i_in1_flat(i_in1_flat),

        .o_global_sum(o_global_sum),
        .o_sum64_0(o_sum64_0),
        .o_sum32_0(o_sum32_0), 
        .o_sum32_1(o_sum32_1),
        .o_sum16_0(o_sum16_0), 
        .o_sum16_1(o_sum16_1), 
        .o_sum16_2(o_sum16_2), 
        .o_sum16_3(o_sum16_3),

        .o_length_mode_byp(o_length_mode_byp),
        .o_valid_byp(o_valid_byp), 
        .o_in0_byp(o_in0_byp)
    );

    // Utility Tasks
    task put_data;
        input [3:0] mode;
        integer i;
        begin
            @(negedge i_clk);
            #2.5;
            i_length_mode = mode;
            i_valid = 1'b1;
            for (i = 0; i < 64; i = i + 1) begin
                i_in1_flat[i*16 +: 16] = test_data[i];
                i_in0_flat[i*16 +: 16] = test_data[63-i];
            end
            @(posedge i_clk);
            #2.5;
            i_valid = 1'b0;
        end
    endtask

    // Task to display fixed-point value as real number (Q12.10)
    task display_fixed;
        input [31:0] val;
        real real_val;
        begin
            real_val = $itor($signed(val)) / 1024.0;
            $write("%f", real_val);
        end
    endtask

    // Result Monitor (Triggers when o_valid_byp is high after 12-cycle latency)
    always @(posedge i_clk) begin
        if (o_valid_byp) begin
            $write("Length Mode : %0d | ", o_length_mode_byp);
            $write("\n");
            $write("global_sum : ");
            display_fixed(o_global_sum);
            $write("\n");
            $write("64_sum : "); 
            display_fixed(o_sum64_0); 
            $write("\n");

            $write("32_sum : "); 
            display_fixed(o_sum32_0); $write(" | ");
            display_fixed(o_sum32_1);
            $write("\n");

            $write("16_sum : "); 
            display_fixed(o_sum16_0); $write(" | ");
            display_fixed(o_sum16_1); $write(" | ");
            display_fixed(o_sum16_2); $write(" | ");
            display_fixed(o_sum16_3);
            $write("\n\n");
        end
    end

    // Main Stimulus
    integer k;
    initial begin
        // Reset sequence
        i_rst         = 0; 
        i_en          = 0; 
        i_length_mode = 0; 
        i_valid       = 0; 
        i_in0_flat    = 0;
        i_in1_flat    = 0;
        #20; 
        i_rst = 1;
        #10; 
        i_rst = 0;
        i_en  = 1;
        #20;

        // Test Case 1:
        for (k=0; k<64; k=k+1) test_data[k] = 16'h0100; 
        put_data(2'd0); 

        // Test Case 2:
        for (k=0; k<64; k=k+1) test_data[k] = (k+1) * 10;
        put_data(4'd0);

        // Test Case 3:
        for (k=0; k<32; k=k+1) test_data[k] = 16'h0100;
        for (k=32; k<64; k=k+1) test_data[k] = 16'h0200;
        put_data(4'd1);

        // Test Case 4:
        for (k=0; k<64; k=k+1) test_data[k] = -16'h0100;
        put_data(4'd2);

        // Test Case 5:
        for (k=0; k<64; k=k+1) test_data[k] = k + 16'h0100;
        put_data(4'd0);

        // Test Case 6:
        for (k=0; k<64; k=k+1) test_data[k] = k + 16'hFD00;
        put_data(4'd0);

        // Test Case 7:
        for (k=0; k<64; k=k+1) test_data[k] = 16*k + 16'hFD00;
        put_data(4'd0);

        // Test Case 8:
        for (k=0; k<64; k=k+1) test_data[k] = 16*k + 16'h0500;
        put_data(4'd0);

        // Test Case 9:
        for (k=0; k<64; k=k+1) test_data[k] = 16'h0100; 
        put_data(2'd3); 
        for (k=0; k<64; k=k+1) test_data[k] = (k+1) * 10;
        put_data(4'd3);

        // Test Case 10:
        for (k=0; k<32; k=k+1) test_data[k] = 16'h0100;
        for (k=32; k<64; k=k+1) test_data[k] = 16'h0200;
        put_data(4'd4);
        for (k=0; k<64; k=k+1) test_data[k] = -16'h0100;
        put_data(4'd4);
        for (k=0; k<64; k=k+1) test_data[k] = k + 16'h0100;
        put_data(4'd4);

        // Test Case 11:
        for (k=0; k<64; k=k+1) test_data[k] = k + 16'hFD00;
        put_data(4'd4);
        for (k=0; k<64; k=k+1) test_data[k] = 16*k + 16'hFD00;
        put_data(4'd4);
        for (k=0; k<64; k=k+1) test_data[k] = 16*k + 16'h0500;
        put_data(4'd4);

        // Test Case 12:
        for (k=0; k<64; k=k+1) test_data[k] = 16'h0100; 
        put_data(2'd3); 
        for (k=0; k<64; k=k+1) test_data[k] = (k+1) * 10;
        put_data(4'd3);

        for (k=0; k<64; k=k+1) test_data[k] = k + 16'hFD00;
        put_data(4'd3);
        for (k=0; k<64; k=k+1) test_data[k] = 16*k + 16'hFD00;
        put_data(4'd3);

        // Test Case 13:
        for (k=0; k<32; k=k+1) test_data[k] = 16'h0100;
        for (k=32; k<64; k=k+1) test_data[k] = 16'h0200;
        put_data(4'd8);
        for (k=0; k<64; k=k+1) test_data[k] = -16'h0100;
        put_data(4'd8);
        for (k=0; k<64; k=k+1) test_data[k] = k + 16'h0100;
        put_data(4'd8);
        for (k=0; k<64; k=k+1) test_data[k] = k + 16'hFD00;
        put_data(4'd8);
        for (k=0; k<64; k=k+1) test_data[k] = 16*k + 16'hFD00;
        put_data(4'd8);
        for (k=0; k<64; k=k+1) test_data[k] = 16*k + 16'h0500;
        put_data(4'd8);
        for (k=0; k<64; k=k+1) test_data[k] = -16'h0100;
        put_data(4'd8);

        // Wait for pipeline to drain
        repeat(100) @(posedge i_clk);
        $display("Simulation Finished.");
        $finish;
    end
endmodule