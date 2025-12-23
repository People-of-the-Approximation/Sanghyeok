module stage3_pow2_approx(
    input clk,
    input en,
    input rst,

    input valid_in,
    input [15:0] in_x,

    output valid_out,
    output [15:0] pow_in_x,
    output [15:0] in_x_bypass
);
    reg [21:0] reg_stg_0;
    reg [32:0] reg_stg_1;

    wire [9:0] in_x_frac;
    wire [5:0] in_x_int;

    reg [4:0] shift;
    wire [15:0] result;

    assign in_x_frac = reg_stg_0[9:0];
    assign in_x_int = in_x[15:10];

    always @(posedge clk) begin
        if (rst) begin
            reg_stg_0 <= 22'd0;
            reg_stg_1 <= 33'd0;
        end
        else if (en) begin
            reg_stg_0 <= {valid_in, shift, in_x};
            reg_stg_1 <= {reg_stg_0[21], result, reg_stg_0[15:0]};
        end
    end

    always @(*) begin
        case (in_x_int)
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
            default: shift = 5'd16;
        endcase
    end

    assign result = {1'b1, in_x_frac, 5'b0_0000} >> reg_stg_0[20:16];

    assign valid_out = reg_stg_1[32];
    assign pow_in_x = reg_stg_1[31:16];
    assign in_x_bypass = reg_stg_1[15:0];

endmodule