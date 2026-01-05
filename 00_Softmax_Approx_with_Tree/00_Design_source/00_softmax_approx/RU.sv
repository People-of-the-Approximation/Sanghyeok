module RU (
    // Operation signals
    input  wire        i_clk,
    input  wire        i_en,
    // Reset signal (active high)
    input  wire        i_rst,

    // Control signals
    input  wire        i_sel_mult,
    input  wire        i_sel_mux,

    // Data input signals
    input  wire        i_valid,
    input  wire [31:0] i_in0,
    input  wire [15:0] i_in1,

    // Data output signals
    output wire        o_valid,
    output wire [15:0] o_out0,
    output wire [15:0] o_out1
);
    // Stage1 log2 approximation signals
    wire [15:0] w_log_in0;
    wire [15:0] w_in0_byp;
    wire [15:0] w_in1_byp;

    // Subtraction and multiplication inputs
    wire [15:0] w_sub_in;
    wire [15:0] w_mult_in;

    // Subtraction and multiplication outputs
    wire [15:0] w_sub_result;
    wire [31:0] w_mult_result;

    // Pipeline valid signal for stage3
    wire      w_valid_log;
    reg [5:0] valid_pip;

    // Pipeline valid signal
    always @(posedge i_clk) begin
        if (i_rst) begin
            valid_pip <= 6'd0;
        end
        else if (i_en) begin
            valid_pip[0] <= w_valid_log;
            for (integer i=1; i<6; i=i+1) begin
                valid_pip[i] <= valid_pip[i-1];
            end
        end
    end

    // Mux for mode selection
    assign w_mult_in = i_sel_mult ? 16'h05C4  : 16'h0400;
    assign w_sub_in  = i_sel_mux  ? w_in0_byp : w_log_in0;

    // Substraction : S = A - B
    // in1_byp - sub_in
    // 2 clock cycles latency
    sub_FX16 SUB(
        .A  (w_in1_byp),
        .B  (w_sub_in),
        .CLK(i_clk),
        .CE (i_en),
        .S  (w_sub_result)
    );

    // Multiplication : P = A * B
    // sub_result * mult_in
    // 4 clock cycles latency
    mult_FX16 MULT(
        .CLK(i_clk),
        .A  (w_sub_result),
        .B  (w_mult_in),
        .CE (i_en),
        .P  (w_mult_result)
    );

    // Stage1 log2
    // 3-stage pipeline
    stage1_log2_approx STAGE1 (
        .i_clk     (i_clk),
        .i_en      (i_en),
        .i_rst     (i_rst),

        .i_valid   (i_valid),
        .i_in0     (i_in0),
        .i_in1     (i_in1),

        .o_valid   (w_valid_log),
        .o_log2_in0(w_log_in0),

        .o_in0_byp (w_in0_byp),
        .o_in1_byp (w_in1_byp)
    );

    // Stage3 pow2
    // 2-stage pipeline
    stage3_pow2_approx STAGE2 (
        .i_clk     (i_clk),
        .i_en      (i_en),
        .i_rst     (i_rst),

        .i_valid   (valid_pip[5]),
        .i_x       (w_mult_result[25:10]),

        .o_valid   (o_valid),
        .o_pow_x   (o_out1),
        .o_x_byp   (o_out0)
    );

endmodule