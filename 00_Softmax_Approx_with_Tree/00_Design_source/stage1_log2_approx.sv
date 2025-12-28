module stage1_log2_approx(
    // Operation signals
    input  wire        i_clk,
    input  wire        i_en,
    // Reset signal (active high)
    input  wire        i_rst,

    // Data input signals
    input  wire        i_valid,
    input  wire [15:0] i_in0,
    input  wire [15:0] i_in1,

    // Data output signals
    output wire        o_valid,
    output wire [15:0] o_log2_in0,

    // Bypass outputs
    output wire [15:0] o_in0_byp,
    output wire [15:0] o_in1_byp
);
    // Pipeline stage registers
    // 3-stage pipeline
    reg [32:0] reg_stg0;
    reg [36:0] reg_stg1;
    reg [48:0] reg_stg2;

    // Internal signals
    reg [3:0] zero_cnt;
    reg [5:0] int_part;

    // Wires for intermediate signals
    wire [15:0] frac_part;
    wire [15:0] result;

    // Sequential logic for pipeline registers
    always @(posedge i_clk) begin
        if (i_rst) begin
            reg_stg0 <= 33'd0;
            reg_stg1 <= 37'd0;
            reg_stg2 <= 49'd0;
        end
        else if (i_en) begin
            // Stage 0: Input registration
            reg_stg0 <= {i_valid, i_in1, i_in0};
            // Stage 1: Leading zero count
            reg_stg1 <= {reg_stg0[32], zero_cnt, reg_stg0[31:0]};
            // Stage 2: Log2 approximation
            reg_stg2 <= {reg_stg1[36], result, reg_stg1[31:0]};
        end
    end

    // Combinational logic : zero counter
    always @(*) begin
        casex (reg_stg0[15:0])
            16'b01xx_xxxx_xxxx_xxxx: zero_cnt = 4'b0001;
            16'b001x_xxxx_xxxx_xxxx: zero_cnt = 4'b0010;
            16'b0001_xxxx_xxxx_xxxx: zero_cnt = 4'b0011;
            16'b0000_1xxx_xxxx_xxxx: zero_cnt = 4'b0100;
            16'b0000_01xx_xxxx_xxxx: zero_cnt = 4'b0101;
            16'b0000_001x_xxxx_xxxx: zero_cnt = 4'b0110;
            16'b0000_0001_xxxx_xxxx: zero_cnt = 4'b0111;
            16'b0000_0000_1xxx_xxxx: zero_cnt = 4'b1000;
            16'b0000_0000_01xx_xxxx: zero_cnt = 4'b1001;
            16'b0000_0000_001x_xxxx: zero_cnt = 4'b1010;
            16'b0000_0000_0001_xxxx: zero_cnt = 4'b1011;
            16'b0000_0000_0000_1xxx: zero_cnt = 4'b1100;
            16'b0000_0000_0000_01xx: zero_cnt = 4'b1101;
            16'b0000_0000_0000_001x: zero_cnt = 4'b1110;
            16'b0000_0000_0000_0001: zero_cnt = 4'b1111;
            default:                 zero_cnt = 4'b0000;
        endcase
    end

    // Combinational logic for integer part of log2
    always @(*) begin
        case (reg_stg1[35:32])
            4'b0001: int_part = 6'b00_0100;
            4'b0010: int_part = 6'b00_0011;
            4'b0011: int_part = 6'b00_0010;
            4'b0100: int_part = 6'b00_0001;
            4'b0101: int_part = 6'b00_0000;
            4'b0110: int_part = 6'b11_1111;
            4'b0111: int_part = 6'b11_1110;
            4'b1000: int_part = 6'b11_1101;
            4'b1001: int_part = 6'b11_1100;
            4'b1010: int_part = 6'b11_1011;
            4'b1011: int_part = 6'b11_1010;
            4'b1100: int_part = 6'b11_1001;
            4'b1101: int_part = 6'b11_1000;
            4'b1110: int_part = 6'b11_0111;
            4'b1111: int_part = 6'b11_0110;
            default: int_part = 6'b10_0000;
            // Temp signal ...
        endcase
    end

    // Calculation of fractional part
    assign frac_part  = reg_stg1[15:0] << reg_stg1[35:32];
    // Final result assembly
    assign result     = {int_part, frac_part[14:5]};

    // Output assignments
    // Valid signal and log2 output
    assign o_valid    = reg_stg2[48];
    assign o_log2_in0 = reg_stg2[47:32];
    // Bypass outputs
    assign o_in0_byp  = reg_stg2[31:16];
    assign o_in1_byp  = reg_stg2[15:0];
endmodule