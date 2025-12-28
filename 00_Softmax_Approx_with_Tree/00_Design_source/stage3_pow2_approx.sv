module stage3_pow2_approx(
    // Operation signals
    input  wire        i_clk,
    input  wire        i_en,
    // Reset signal (active high)
    input  wire        i_rst,

    // Data input signals
    input  wire        i_valid,
    input  wire [15:0] i_x,

    // Data output signals
    output wire        o_valid,
    output wire [15:0] o_pow_x,
    output wire [15:0] o_x_bypass
);
    // Pipeline stage registers
    // 2-stage pipeline
    reg  [21:0] reg_stg0;
    reg  [32:0] reg_stg1;

    // Internal signals
    wire  [9:0] x_frac;
    wire  [5:0] x_int;


    reg   [4:0] shift;
    wire [15:0] result;

    assign x_frac = reg_stg0[9:0];
    assign x_int  = i_x[15:10];
    
    always @(posedge i_clk) begin
        if (i_rst) begin
            reg_stg0 <= 22'd0;
            reg_stg1 <= 33'd0;
        end
        else if (i_en) begin
            reg_stg0 <= {i_valid, shift, i_x};
            reg_stg1 <= {reg_stg0[21], result, reg_stg0[15:0]};
        end
    end

    always @(*) begin
        case (x_int)
            6'b110110: shift = 5'd15;
            6'b110111: shift = 5'd14;
            6'b111000: shift = 5'd13;
            6'b111001: shift = 5'd12;
            6'b111010: shift = 5'd11;
            6'b111011: shift = 5'd10;
            6'b111100: shift = 5'd9;
            6'b111101: shift = 5'd8;
            6'b111110: shift = 5'd7;
            6'b111111: shift = 5'd6;
            6'b000000: shift = 5'd5;
            6'b000001: shift = 5'd4;
            6'b000010: shift = 5'd3;
            6'b000011: shift = 5'd2;
            6'b000100: shift = 5'd1;
            6'b000101: shift = 5'd0;
            default:   shift = 5'd16;
        endcase
    end

    assign result = {1'b1, x_frac, 5'b0_0000} >> reg_stg0[20:16];

    assign o_valid    = reg_stg1[32];
    assign o_pow_x    = reg_stg1[31:16];
    assign o_x_bypass = reg_stg1[15:0];

endmodule