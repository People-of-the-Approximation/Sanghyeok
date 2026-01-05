module stage1_log2_approx(
    // Operation signals
    input  wire        i_clk,
    input  wire        i_en,
    // Reset signal (active high)
    input  wire        i_rst,

    // Data input signals
    input  wire        i_valid,
    // Input: Q22.10
    input  wire [31:0] i_in0,
    input  wire [15:0] i_in1,

    // Data output signals
    output wire        o_valid,
    output wire [15:0] o_log2_in0,
    // Bypass outputs
    output wire [15:0] o_in0_byp,
    output wire [15:0] o_in1_byp
);
    // Pipeline stage registers
    // Stage 0: Input Capture
    // Width: Valid(1) + In1(16) + In0(32) = 49 bits
    reg   [48:0] r_stg0;
    // Stage 1: LZC Result + Data Hold
    // Width: Valid(1) + ZeroCnt(5) + In1(16) + In0(32) = 54 bits
    // Note: We need full i_in0 to calculate fractional part in Stage 2 logic
    reg   [53:0] r_stg1;
    // Stage 2: Final Result
    // Width: Valid(1) + LogResult(16) + In1_Byp(16) + In0_Byp(16) = 49 bits
    reg   [48:0] r_stg2;

    // Internal Signals
    reg   [4:0]  zero_cnt;
    reg   [5:0]  int_part;
    wire  [31:0] shifted_val;
    wire  [9:0]  frac_part;
    wire  [15:0] result_log;

    // Sequential Logic : Pipeline Registers
    always @(posedge i_clk) begin
        if (i_rst) begin
            r_stg0 <= 49'd0;
            r_stg1 <= 54'd0;
            r_stg2 <= 49'd0;
        end
        else if (i_en) begin
            // Stage 0: Input registration
            r_stg0 <= {i_valid, i_in1, i_in0};
            // Stage 1: Leading zero count result & Pass data
            // r_stg0 Structure: {valid(48), in1(47:32), in0(31:0)}
            r_stg1 <= {r_stg0[48], zero_cnt, r_stg0[47:32], r_stg0[31:0]};
            // Stage 2: Log2 Approximation & Bypass formatting
            // r_stg1 Structure: {valid(53), zcnt(52:48), in1(47:32), in0(31:0)}
            // Bypass logic: in0 is truncated to 16 bits (r_stg1[15:0])
            r_stg2 <= {r_stg1[53], result_log, r_stg1[47:32], r_stg1[15:0]};
        end
    end

    // Combinational Logic : Stage 0 -> Stage 1 (LZC)
    always @(*) begin
        casex (r_stg0[31:0])
            32'b01xx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx: zero_cnt = 5'd1;
            32'b001x_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx: zero_cnt = 5'd2;
            32'b0001_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx: zero_cnt = 5'd3;
            32'b0000_1xxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx: zero_cnt = 5'd4;
            32'b0000_01xx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx: zero_cnt = 5'd5;
            32'b0000_001x_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx: zero_cnt = 5'd6;
            32'b0000_0001_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx: zero_cnt = 5'd7;
            32'b0000_0000_1xxx_xxxx_xxxx_xxxx_xxxx_xxxx: zero_cnt = 5'd8;
            32'b0000_0000_01xx_xxxx_xxxx_xxxx_xxxx_xxxx: zero_cnt = 5'd9;
            32'b0000_0000_001x_xxxx_xxxx_xxxx_xxxx_xxxx: zero_cnt = 5'd10;
            32'b0000_0000_0001_xxxx_xxxx_xxxx_xxxx_xxxx: zero_cnt = 5'd11;
            32'b0000_0000_0000_1xxx_xxxx_xxxx_xxxx_xxxx: zero_cnt = 5'd12;
            32'b0000_0000_0000_01xx_xxxx_xxxx_xxxx_xxxx: zero_cnt = 5'd13;
            32'b0000_0000_0000_001x_xxxx_xxxx_xxxx_xxxx: zero_cnt = 5'd14;
            32'b0000_0000_0000_0001_xxxx_xxxx_xxxx_xxxx: zero_cnt = 5'd15;
            32'b0000_0000_0000_0000_1xxx_xxxx_xxxx_xxxx: zero_cnt = 5'd16;
            32'b0000_0000_0000_0000_01xx_xxxx_xxxx_xxxx: zero_cnt = 5'd17;
            32'b0000_0000_0000_0000_001x_xxxx_xxxx_xxxx: zero_cnt = 5'd18;
            32'b0000_0000_0000_0000_0001_xxxx_xxxx_xxxx: zero_cnt = 5'd19;
            32'b0000_0000_0000_0000_0000_1xxx_xxxx_xxxx: zero_cnt = 5'd20;
            32'b0000_0000_0000_0000_0000_01xx_xxxx_xxxx: zero_cnt = 5'd21;
            32'b0000_0000_0000_0000_0000_001x_xxxx_xxxx: zero_cnt = 5'd22;
            32'b0000_0000_0000_0000_0000_0001_xxxx_xxxx: zero_cnt = 5'd23;
            32'b0000_0000_0000_0000_0000_0000_1xxx_xxxx: zero_cnt = 5'd24;
            32'b0000_0000_0000_0000_0000_0000_01xx_xxxx: zero_cnt = 5'd25;
            32'b0000_0000_0000_0000_0000_0000_001x_xxxx: zero_cnt = 5'd26;
            32'b0000_0000_0000_0000_0000_0000_0001_xxxx: zero_cnt = 5'd27;
            32'b0000_0000_0000_0000_0000_0000_0000_1xxx: zero_cnt = 5'd28;
            32'b0000_0000_0000_0000_0000_0000_0000_01xx: zero_cnt = 5'd29;
            32'b0000_0000_0000_0000_0000_0000_0000_001x: zero_cnt = 5'd30;
            32'b0000_0000_0000_0000_0000_0000_0000_0001: zero_cnt = 5'd31;
            default:                                     zero_cnt = 5'd0;
        endcase
    end

    // Combinational Logic : Stage 1 -> Stage 2 (Log Calc)
    // r_stg1 slices: [52:48]=zero_cnt, [31:0]=i_in0
    wire [4:0]  stg1_zero_cnt = r_stg1[52:48];
    wire [31:0] stg1_in0      = r_stg1[31:0];
    // 1. Integer Part Calculation for Q12.10 Input
    // Formula: log2_int = (31 - zero_cnt) - 10 = 21 - zero_cnt
    // This supports negative logs (e.g., if input < 1.0)
    // Combinational logic : integer part of log2
    always @(*) begin
        case (stg1_zero_cnt)
            5'd1:  int_part = 6'h15;
            5'd2:  int_part = 6'h14;
            5'd3:  int_part = 6'h13;
            5'd4:  int_part = 6'h12;
            5'd5:  int_part = 6'h11;
            5'd6:  int_part = 6'h10;
            5'd7:  int_part = 6'h0E;
            5'd8:  int_part = 6'h0D;
            5'd9:  int_part = 6'h0C;
            5'd10: int_part = 6'h0B;
            5'd11: int_part = 6'h0A;
            5'd12: int_part = 6'h09;
            5'd13: int_part = 6'h08;
            5'd14: int_part = 6'h07;
            5'd15: int_part = 6'h06;
            5'd16: int_part = 6'h05;
            5'd17: int_part = 6'h04;
            5'd18: int_part = 6'h03;
            5'd19: int_part = 6'h02;
            5'd20: int_part = 6'h01;
            5'd21: int_part = 6'h00;
            5'd22: int_part = 6'h3F;
            5'd23: int_part = 6'h3E;
            5'd24: int_part = 6'h3D;
            5'd25: int_part = 6'h3C;
            5'd26: int_part = 6'h3B;
            5'd27: int_part = 6'h3A;
            5'd28: int_part = 6'h39;
            5'd29: int_part = 6'h38;
            5'd30: int_part = 6'h37;
            5'd31: int_part = 6'h36;
            5'd0:  int_part = 6'h20;
            default: int_part = 6'h20;
        endcase
    end

    // Fractional Part Calculation (Mitchell's Approximation)
    // Shift the input left so the MSB is aligned to bit 31
    assign shifted_val = stg1_in0 << stg1_zero_cnt;
    // The fractional part comes from the bits immediately following the MSB.
    // Since MSB is at 31 after shift, we discard it (implicit 1) and take [30:21]
    assign frac_part = shifted_val[30:21];
    // Assemble Result (Q6.10)
    assign result_log = {int_part, frac_part};

    // Output Assignments
    // Valid signal and log2 output
    assign o_valid    = r_stg2[48];
    assign o_log2_in0 = r_stg2[47:32];
    // Bypass outputs
    assign o_in1_byp  = r_stg2[31:16];
    // Bypass output (truncated in0)
    assign o_in0_byp  = r_stg2[15:0];
endmodule