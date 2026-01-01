`timescale 1ns/1ps

module softmax_tb;

    // Test Data Patterns
    localparam [1023:0] my_x_0 = {8{16'h061D, 16'h061D, 16'hFDE2, 16'h0B13, 16'hFBCF, 16'h0B26, 16'h042B, 16'hF5BE}};
    localparam [1023:0] my_x_1 = {8{16'hFA60, 16'h042D, 16'hFFBF, 16'hF46A, 16'h0A79, 16'hF8B9, 16'hFBCC, 16'hF55D}};
    localparam [1023:0] my_x_2 = {8{16'h00F7, 16'h0AC0, 16'h0A99, 16'h09D6, 16'hFF4D, 16'hF72D, 16'hFF90, 16'h0B2A}};

    // Operation signals
    reg         i_clk;
    reg         i_en;
    reg         i_rst;

    // Control and Data signals
    reg           i_valid;
    reg  [3:0]    i_length_mode;
    reg  [1023:0] i_in_x_flat;

    // Output signals
    wire          o_valid;
    wire [1023:0] o_prob_flat;

    // Array for monitoring
    wire [15:0] w_prob_arr [0:63];

    // Clock Generation (100MHz)
    initial i_clk = 0;
    always #5 i_clk = ~i_clk;

    // Unflatten output for easy monitoring
    genvar idx;
    generate
        for (idx = 0; idx < 64; idx = idx + 1) begin : out_map
            assign w_prob_arr[idx] = o_prob_flat[16*idx +: 16];
        end
    endgenerate

    // DUT Instantiation
    softmax_approx DUT (
        .i_clk(i_clk),
        .i_en(i_en),
        .i_rst(i_rst),
        .i_length_mode(i_length_mode),
        .i_valid(i_valid),
        .i_in_x_flat(i_in_x_flat),
        .o_valid(o_valid),
        .o_prob_flat(o_prob_flat)
    );

    // Task to display fixed-point value as real (Q6.10)
    task display_fixed;
        input [15:0] val;
        real real_val;
        begin
            real_val = $itor($signed(val)) / 1024.0;
            $write("%f ", real_val);
        end
    endtask

    // Result Monitor
    always @(posedge i_clk) begin
        if (o_valid) begin
            $display("Mode: %0d", DUT.w_mode_stg3);
            $write  ("Results: ");
            for (integer j = 0; j < 64; j = j + 1) begin
                if (j % 8 == 0) $write("\n  ");
                display_fixed(w_prob_arr[j]);
            end
            $display("\n");
        end
    end

    // Main Stimulus
    initial begin
        // Initialize
        i_in_x_flat   = 0;
        i_valid       = 0;
        i_en          = 0;
        i_length_mode = 0;
        
        // Reset sequence
        #2;  i_rst = 1;
        #10; i_rst = 0;
        #10; i_en  = 1; 

        // Start Data Injection
        $display("Softmax Integration Test Start");

        // Mode 0: 16-length
        #10; i_in_x_flat = my_x_0; i_valid = 1; i_length_mode = 0;
        #10; i_in_x_flat = my_x_1; i_valid = 1; i_length_mode = 0;
        #10; i_in_x_flat = my_x_2; i_valid = 1; i_length_mode = 0;
        #10; i_in_x_flat = my_x_0; i_valid = 1; i_length_mode = 1;
        #10; i_in_x_flat = my_x_1; i_valid = 1; i_length_mode = 1;
        #10; i_in_x_flat = my_x_2; i_valid = 1; i_length_mode = 1;
        #10; i_in_x_flat = my_x_0; i_valid = 1; i_length_mode = 2;
        #10; i_in_x_flat = my_x_1; i_valid = 1; i_length_mode = 2;
        #10; i_in_x_flat = my_x_2; i_valid = 1; i_length_mode = 2;
        #10; i_in_x_flat = my_x_0; i_valid = 1; i_length_mode = 3;
        #10; i_in_x_flat = my_x_1; i_valid = 1; i_length_mode = 3;
        #10; i_in_x_flat = my_x_0; i_valid = 1; i_length_mode = 4;
        #10; i_in_x_flat = my_x_1; i_valid = 1; i_length_mode = 4;
        #10; i_in_x_flat = my_x_2; i_valid = 1; i_length_mode = 4;
        #10; i_in_x_flat = my_x_0; i_valid = 1; i_length_mode = 5;
        #10; i_in_x_flat = my_x_1; i_valid = 1; i_length_mode = 5;
        #10; i_in_x_flat = my_x_2; i_valid = 1; i_length_mode = 5;
        #10; i_in_x_flat = my_x_0; i_valid = 1; i_length_mode = 5;
        #10; i_valid = 0;

        // Wait for pipeline to drain
        #800;
        $display("Simulation Finished");
        $finish;
    end

endmodule