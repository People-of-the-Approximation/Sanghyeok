`timescale 1ns/1ps

module RU_tb;
    // Operation signals
    reg         i_clk;
    reg         i_en;
    // Reset signal (active high)
    reg         i_rst;

    // Control signals
    reg         i_sel_mult;
    reg         i_sel_mux;

    // Data input signals
    reg         i_valid;
    reg  [31:0] i_in0;
    reg  [15:0] i_in1;

    // Data output signals
    wire        o_valid;
    wire [15:0] o_out0;
    wire [15:0] o_out1;

    // Clock generation
    initial i_clk = 0;
    always #5 i_clk = ~i_clk;

    RU RU_test(
        .i_clk     (i_clk),
        .i_en      (i_en),
        .i_rst     (i_rst),

        .i_sel_mult(i_sel_mult),
        .i_sel_mux (i_sel_mux),

        .i_valid   (i_valid),
        .i_in0     (i_in0),
        .i_in1     (i_in1),

        .o_valid   (o_valid),
        .o_out0    (o_out0),
        .o_out1    (o_out1)
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

    task put_data;
        input [31:0] data0;
        input [15:0] data1;
        begin
            @(negedge i_clk);
            #2.5;
            i_valid = 1'b1;
            i_in0 = data0;
            i_in1 = data1;
            @(posedge i_clk);
            #2.5;
            i_valid = 1'b0;
        end
    endtask

    always @(posedge i_clk) begin
        if (o_valid) begin
            $write("out_0 (scaled diff) = "); 
            display_fixed(o_out0); 
            $write("\n");
            $write("out_1 (pow2 approx) = "); 
            display_fixed(o_out1); 
            $write("\n");
        end
    end

    initial begin
        i_rst = 0; 
        i_en = 0; 
        i_valid = 0;
        i_in0 = 0; 
        i_in1 = 0;
        i_sel_mult = 0; 
        i_sel_mux = 0;

        #20; 
        i_rst = 1;
        #10; 
        i_rst = 0;
        i_en = 1;
        #20;

        $display("=== RU Module Test Start ===");
        i_sel_mux = 1;  
        i_sel_mult = 1;
        put_data(32'h00000800, 16'h0400);
        put_data(32'h00000C00, 16'h0C00);
        put_data(32'h00001000, 16'h0400);
        put_data(32'h00000400, 16'h0800);
        put_data(32'h00002D44, 16'hE125); 
        put_data(32'h00001000, 16'h1000); 
        put_data(32'h00000000, 16'hFC00);
        put_data(32'h00001800, 16'h1400);
        #150;
        i_sel_mux = 0; 
        i_sel_mult = 0;
        put_data(32'h00000800, 16'h0400);
        put_data(32'h00000C00, 16'h0C00);
        put_data(32'h00001000, 16'h0400);
        put_data(32'h00000400, 16'h0800);
        put_data(32'h00002D44, 16'hE125); 
        put_data(32'h00001000, 16'h1000); 
        put_data(32'h00000000, 16'hFC00);
        put_data(32'h00001800, 16'h1400);
        
        #120;
        $display("=== RU Module Test End ===");
        $finish;
    end

endmodule