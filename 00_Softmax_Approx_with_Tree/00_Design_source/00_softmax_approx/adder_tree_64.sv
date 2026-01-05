module add_tree_64 (
    // Operation signals
    input  wire          i_clk,
    input  wire          i_en,
    input  wire          i_rst,

    // Length mode input
    input  wire    [3:0] i_length_mode,

    // Data input signals
    input  wire          i_valid,
    input  wire [1023:0] i_in0_flat,
    input  wire [1023:0] i_in1_flat,

    // Data output signals
    output wire   [31:0] o_sum64_0,
    output wire   [31:0] o_sum32_0,
    output wire   [31:0] o_sum32_1,
    output wire   [31:0] o_sum16_0,
    output wire   [31:0] o_sum16_1,
    output wire   [31:0] o_sum16_2,
    output wire   [31:0] o_sum16_3,

    // Bypass outputs
    output wire    [3:0] o_length_mode_byp,
    output wire          o_valid_byp,
    output wire [1023:0] o_in0_byp
);
    // Stage data signals
    wire [31:0] stg_data [0:6][0:63];

    // Bypass registers (12 stages)
    reg    [3:0]  r_length_mode_byp [0:11];
    reg           r_valid_byp       [0:11];
    reg [1023:0]  r_in0_byp         [0:11];

    // Bypass pipeline (12 stages)
    always @(posedge i_clk) begin
        if (i_rst) begin
            for (integer k = 0; k <= 11; k = k + 1) begin
                r_length_mode_byp[k] <= 4'b0;
                r_valid_byp      [k] <= 1'b0;
                r_in0_byp        [k] <= 1024'd0;
            end
        end
        else if (i_en) begin
            r_length_mode_byp[0] <= i_length_mode;
            r_valid_byp      [0] <= i_valid;
            r_in0_byp        [0] <= i_in0_flat;
            for (integer k = 0; k <= 10; k = k + 1) begin
                r_length_mode_byp[k+1] <= r_length_mode_byp[k];
                r_valid_byp      [k+1] <= r_valid_byp      [k];
                r_in0_byp        [k+1] <= r_in0_byp        [k];
            end
        end
    end

    // Initial stage assignments
    // Sign extention for inputs
    generate
        for (genvar i = 0; i < 64; i = i + 1) begin : input_gen
            assign stg_data[0][i] = {{16{i_in1_flat[i*16 + 15]}}, i_in1_flat[i*16 +: 16]};
        end
    endgenerate
    // Adder tree generation (6 stages, each stage is 2-cycles)
    generate
        for (genvar j = 0; j < 6; j = j + 1) begin : stages
            for (genvar i = 0; i < (64 >> (j+1)); i = i + 1) begin : adders
                add_unit ADDER (
                    .i_clk(i_clk),
                    .i_en (i_en),
                    .i_rst(i_rst),

                    .i_A  (stg_data[j][2*i]),
                    .i_B  (stg_data[j][2*i+1]),
                    
                    .o_sum(stg_data[j+1][i])
                );
            end
        end
    endgenerate
    // Output pipelines for 32-mode and 16-mode
    // 2-stage pipe for 32-mode sums
    reg [31:0] sum32_0_pip [0:1];
    reg [31:0] sum32_1_pip [0:1];
    // 4-stage pipe for 16-mode sums
    reg [31:0] sum16_0_pip [0:3];
    reg [31:0] sum16_1_pip [0:3];
    reg [31:0] sum16_2_pip [0:3];
    reg [31:0] sum16_3_pip [0:3];

    // Pipeline registers
    always @(posedge i_clk) begin
        if (i_rst) begin
            for (integer k = 0; k < 2; k = k + 1) begin
                // 32-mode reset (2 stage)
                sum32_0_pip[k] <= 32'd0; 
                sum32_1_pip[k] <= 32'd0;
            end
            for (integer k = 0; k < 4; k = k + 1) begin
                // 16-mode reset (4 stages)
                sum16_0_pip[k] <= 32'd0; 
                sum16_1_pip[k] <= 32'd0;
                sum16_2_pip[k] <= 32'd0; 
                sum16_3_pip[k] <= 32'd0;
            end
        end
        else if (i_en) begin
            // 32-mode pipeline (2 stage)
            sum32_0_pip[0] <= stg_data[5][0];
            sum32_1_pip[0] <= stg_data[5][1];
            sum32_0_pip[1] <= sum32_0_pip[0];
            sum32_1_pip[1] <= sum32_1_pip[0];
            // 16-mode pipeline (4 stages)
            sum16_0_pip[0] <= stg_data[4][0];
            sum16_1_pip[0] <= stg_data[4][1];
            sum16_2_pip[0] <= stg_data[4][2];
            sum16_3_pip[0] <= stg_data[4][3];
            for (integer k = 0; k < 3; k = k + 1) begin
                sum16_0_pip[k+1] <= sum16_0_pip[k];
                sum16_1_pip[k+1] <= sum16_1_pip[k];
                sum16_2_pip[k+1] <= sum16_2_pip[k];
                sum16_3_pip[k+1] <= sum16_3_pip[k];
            end
        end
    end
    // Output assignments
    // 64-mode output
    assign o_sum64_0     = stg_data[6][0];
    // 32-mode outputs
    assign o_sum32_0     = sum32_0_pip[1];
    assign o_sum32_1     = sum32_1_pip[1];
    // 16-mode outputs
    assign o_sum16_0     = sum16_0_pip[3];
    assign o_sum16_1     = sum16_1_pip[3];
    assign o_sum16_2     = sum16_2_pip[3];
    assign o_sum16_3     = sum16_3_pip[3];
    // Bypass outputs
    assign o_length_mode_byp = r_length_mode_byp[11];
    assign o_valid_byp       = r_valid_byp      [11];
    assign o_in0_byp         = r_in0_byp        [11];

endmodule

module add_unit (
    // Operation signals
    input  wire        i_clk,
    input  wire        i_en,
    input  wire        i_rst,

    // Inputs
    input  wire [31:0] i_A,
    input  wire [31:0] i_B,

    // Output
    output wire [31:0] o_sum
);
    // Instantiate FXP Adder IP Core
    // 2-clock cycle latency
    add_FX16 IP_ADDER (
        .A  (i_A),
        .B  (i_B),
        .CLK(i_clk),
        .CE (i_en),
        .S  (o_sum)
    );
endmodule