module max_tree_64 (
    // Operation signals
    input  wire          i_clk,
    input  wire          i_en,
    input  wire          i_rst,

    // Length mode input
    input  wire    [1:0] i_length_mode,

    // Data input signals
    input  wire   [63:0] i_valid,
    input  wire [1023:0] i_in_flat,

    // Data output signals
    // Max valid signals
    output wire          o_valid_max,
    // 64-mode max output
    output wire   [15:0] o_max64_0,
    // 32-mode max outputs
    output wire   [15:0] o_max32_0,
    output wire   [15:0] o_max32_1,
    // 16-mode max outputs
    output wire   [15:0] o_max16_0,
    output wire   [15:0] o_max16_1,
    output wire   [15:0] o_max16_2,
    output wire   [15:0] o_max16_3,

    // Bypass outputs
    output wire    [1:0] o_length_mode_byp,
    output wire   [63:0] o_valid_byp,
    output wire [1023:0] o_in_byp
);
    // Stage valid and data signals
    wire [63:0] stg_valid [0:6];
    wire [15:0] stg_data  [0:6][0:63];

    // Bypass registers (6 stages)
    reg    [1:0] r_length_mode_byp [0:5];
    reg   [63:0] r_valid_byp       [0:5];
    reg [1023:0] r_byp             [0:5];

    // Bypass pipeline (6 stages)
    always @(posedge i_clk) begin
        if (i_rst) begin
            for (integer k = 0; k <= 5; k = k + 1) begin
                r_length_mode_byp[k] <= 2'b0;
                r_valid_byp      [k] <= {64{1'b0}};
                r_byp            [k] <= {64{16'd0}};
            end
        end
        else if (i_en) begin
            r_length_mode_byp[0] <= i_length_mode;
            r_valid_byp      [0] <= i_valid;
            r_byp            [0] <= i_in_flat;
            for (integer k = 0; k <= 4; k = k + 1) begin
                r_length_mode_byp[k+1] <= r_length_mode_byp[k];
                r_valid_byp      [k+1] <= r_valid_byp      [k];
                r_byp            [k+1] <= r_byp            [k];
            end
        end
    end

    // Initial stage assignments
    assign stg_valid[0] = i_valid;
    // Flattened input to stage data
    generate
        for (genvar i = 0; i < 64; i = i + 1) begin
            assign stg_data[0][i] = i_in_flat[i*16 +: 16];
        end
    endgenerate
    // Max tree generation
    generate
        for (genvar j = 0; j < 6; j = j + 1) begin : stages
            for (genvar i = 0; i < (64 >> (j+1)); i = i + 1) begin : comps
                max_comparator MAX(
                    .i_clk(i_clk),    
                    .i_en (i_en),
                    .i_rst(i_rst),

                    .i_valid_A(stg_valid[j][2*i]),
                    .i_A      (stg_data [j][2*i]),

                    .i_valid_B(stg_valid[j][2*i+1]),
                    .i_B      (stg_data [j][2*i+1]),

                    .o_valid (stg_valid[j+1][i]),
                    .o_max   (stg_data [j+1][i])
                );
            end
        end
    endgenerate
    // Output pipelines for 32-mode and 16-mode
    // 1-stage pipeline for 32-mode
    reg [15:0] max32_0_pip;
    reg [15:0] max32_1_pip;
    // 2-stage pipeline for 16-mode
    reg [15:0] max16_0_pip [0:1];
    reg [15:0] max16_1_pip [0:1];
    reg [15:0] max16_2_pip [0:1];
    reg [15:0] max16_3_pip [0:1];

    // Pipeline registers
    always @(posedge i_clk) begin
        if (i_rst) begin
            // 32-mode reset (1 stage)
            max32_0_pip <= 16'd0;
            max32_1_pip <= 16'd0;

            // 16-mode reset (2 stages)
            for (integer k = 0; k < 2; k = k + 1) begin
                max16_0_pip[k] <= 16'd0;
                max16_1_pip[k] <= 16'd0;
                max16_2_pip[k] <= 16'd0;
                max16_3_pip[k] <= 16'd0;
            end
        end 
        else if (i_en) begin
            // 32-mode pipeline (1 stage)
            max32_0_pip <= stg_data[5][0];
            max32_1_pip <= stg_data[5][1];
            // 16-mode pipeline (2 stages)
            max16_0_pip[0] <= stg_data[4][0];
            max16_1_pip[0] <= stg_data[4][1];
            max16_2_pip[0] <= stg_data[4][2];
            max16_3_pip[0] <= stg_data[4][3];
            for (integer k = 1; k < 2; k = k + 1) begin
                max16_0_pip[k] <= max16_0_pip[k-1];
                max16_1_pip[k] <= max16_1_pip[k-1];
                max16_2_pip[k] <= max16_2_pip[k-1];
                max16_3_pip[k] <= max16_3_pip[k-1];
            end
        end
    end
    // Output assignments
    // Max valid output
    assign o_valid_max = stg_valid[6][0];
    // 64-mode output
    assign o_max64_0   = stg_data[6][0];
    // 32-mode outputs
    assign o_max32_0   = max32_0_pip;
    assign o_max32_1   = max32_1_pip;
    // 16-mode outputs
    assign o_max16_0   = max16_0_pip[1];
    assign o_max16_1   = max16_1_pip[1];
    assign o_max16_2   = max16_2_pip[1];
    assign o_max16_3   = max16_3_pip[1];
    // Bypass outputs
    assign o_length_mode_byp = r_length_mode_byp[5];
    assign o_valid_byp       = r_valid_byp      [5];
    assign o_in_byp          = r_byp            [5];

endmodule

module max_comparator (
    // Operation signals
    input i_clk,
    input i_en,
    input i_rst,

    // Input A
    input i_valid_A,
    input signed [15:0] i_A,

    // Input B
    input i_valid_B,
    input signed [15:0] i_B,

    // Output
    output reg o_valid,
    output reg signed [15:0] o_max
);
    // Max logic
    always @(posedge i_clk) begin
        if (i_rst) begin
            o_max   <= 16'd0;
            o_valid <= 1'b0;
        end 
        else if (i_en) begin
            o_max   <= (i_A > i_B) ? i_A : i_B;
            o_valid <= i_valid_A & i_valid_B;
        end
    end
endmodule