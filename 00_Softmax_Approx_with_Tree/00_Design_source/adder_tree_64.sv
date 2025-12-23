module add_tree_64 (
    input clk,
    input en,
    input rst,

    input [1:0] length_mode,

    input valid_in,
    input [1023:0] in_0_flat,
    input [1023:0] in_1_flat,

    output [15:0] in_1_sum_64_0,

    output [15:0] in_1_sum_32_0,
    output [15:0] in_1_sum_32_1,

    output [15:0] in_1_sum_16_0,
    output [15:0] in_1_sum_16_1,
    output [15:0] in_1_sum_16_2,
    output [15:0] in_1_sum_16_3,

    output [1:0] length_mode_bypass,
    output valid_bypass_out,
    output [1023:0] in_bypass_flat
);

    wire [15:0] stage_data [0:6][0:63];

    reg [1:0] reg_length_mode_bypass [5:0];
    reg [11:0] reg_valid_bypass;
    reg [1023:0] reg_bypass [0:11];

    integer k;
    always @(posedge clk) begin
        if (rst) begin
            for (k = 0; k <= 11; k = k + 1) begin
                reg_length_mode_bypass[k] <= 2'b0;
                reg_valid_bypass[k] <= 1'b0;
                reg_bypass[k] <= {64{16'd0}};
            end
        end
        else if (en) begin
            reg_length_mode_bypass[0] <= length_mode;
            reg_valid_bypass[0] <= valid_in;
            reg_bypass[0] <= in_0_flat;
            for (k = 0; k <= 10; k = k + 1) begin
                reg_length_mode_bypass[k+1] <= reg_length_mode_bypass[k];
                reg_valid_bypass[k+1] <= reg_valid_bypass[k];
                reg_bypass[k+1] <= reg_bypass[k];
            end
        end
    end

    genvar i, j;
    generate
        for (i = 0; i < 64; i = i + 1) begin
            assign stage_data[0][i] = in_1_flat[i*16 +: 16];
        end
    endgenerate
    
    generate
        for (j = 0; j < 6; j = j + 1) begin : stages
            for (i = 0; i < (64 >> (j+1)); i = i + 1) begin : adders
                add_FX16 ADD (
                    .A(stage_data[j][2*i]),
                    .B(stage_data[j][2*i+1]),
                    .CLK(clk),
                    .CE(en),
                    .S(stage_data[j+1][i])
                );
            end
        end
    endgenerate

    reg [15:0] in_1_sum_32_0_pipe [0:1];
    reg [15:0] in_1_sum_32_1_pipe [0:1];

    reg [15:0] in_1_sum_16_0_pipe [0:3];
    reg [15:0] in_1_sum_16_1_pipe [0:3];
    reg [15:0] in_1_sum_16_2_pipe [0:3];
    reg [15:0] in_1_sum_16_3_pipe [0:3];

    always @(posedge clk) begin
        if (rst) begin
            in_1_sum_32_0_pipe[0] <= 16'd0;
            in_1_sum_32_1_pipe[0] <= 16'd0;

            in_1_sum_32_0_pipe[1] <= 16'd0;
            in_1_sum_32_1_pipe[1] <= 16'd0;

            in_1_sum_16_0_pipe[0] <= 16'd0;
            in_1_sum_16_1_pipe[0] <= 16'd0;
            in_1_sum_16_2_pipe[0] <= 16'd0;
            in_1_sum_16_3_pipe[0] <= 16'd0;

            in_1_sum_16_0_pipe[1] <= 16'd0;
            in_1_sum_16_1_pipe[1] <= 16'd0;
            in_1_sum_16_2_pipe[1] <= 16'd0;
            in_1_sum_16_3_pipe[1] <= 16'd0;

            in_1_sum_16_0_pipe[2] <= 16'd0;
            in_1_sum_16_1_pipe[2] <= 16'd0;
            in_1_sum_16_2_pipe[2] <= 16'd0;
            in_1_sum_16_3_pipe[2] <= 16'd0;

            in_1_sum_16_0_pipe[3] <= 16'd0;
            in_1_sum_16_1_pipe[3] <= 16'd0;
            in_1_sum_16_2_pipe[3] <= 16'd0;
            in_1_sum_16_3_pipe[3] <= 16'd0;
        end
        else if (en) begin
            in_1_sum_32_0_pipe[0] <= stage_data[5][0];
            in_1_sum_32_1_pipe[0] <= stage_data[5][1];

            in_1_sum_32_0_pipe[1] <= in_1_sum_32_0_pipe[0];
            in_1_sum_32_1_pipe[1] <= in_1_sum_32_1_pipe[0];

            in_1_sum_16_0_pipe[0] <= stage_data[4][0];
            in_1_sum_16_1_pipe[0] <= stage_data[4][1];
            in_1_sum_16_2_pipe[0] <= stage_data[4][2];
            in_1_sum_16_3_pipe[0] <= stage_data[4][3];

            in_1_sum_16_0_pipe[1] <= in_1_sum_16_0_pipe[0];
            in_1_sum_16_1_pipe[1] <= in_1_sum_16_1_pipe[0];
            in_1_sum_16_2_pipe[1] <= in_1_sum_16_2_pipe[0];
            in_1_sum_16_3_pipe[1] <= in_1_sum_16_3_pipe[0];

            in_1_sum_16_0_pipe[2] <= in_1_sum_16_0_pipe[1];
            in_1_sum_16_1_pipe[2] <= in_1_sum_16_1_pipe[1];
            in_1_sum_16_2_pipe[2] <= in_1_sum_16_2_pipe[1];
            in_1_sum_16_3_pipe[2] <= in_1_sum_16_3_pipe[1];

            in_1_sum_16_0_pipe[3] <= in_1_sum_16_0_pipe[2];
            in_1_sum_16_1_pipe[3] <= in_1_sum_16_1_pipe[2];
            in_1_sum_16_2_pipe[3] <= in_1_sum_16_2_pipe[2];
            in_1_sum_16_3_pipe[3] <= in_1_sum_16_3_pipe[2];
        end
    end


    assign in_1_sum_64_0 = stage_data[6][0];

    assign in_1_sum_32_0 = in_1_sum_32_0_pipe[1];
    assign in_1_sum_32_1 = in_1_sum_32_1_pipe[1];

    assign in_1_sum_16_0 = in_1_sum_16_0_pipe[3];
    assign in_1_sum_16_1 = in_1_sum_16_1_pipe[3];
    assign in_1_sum_16_2 = in_1_sum_16_2_pipe[3];
    assign in_1_sum_16_3 = in_1_sum_16_3_pipe[3];

    assign length_mode_bypass = reg_length_mode_bypass[5];
    assign valid_bypass_out = reg_valid_bypass[11];
    assign in_bypass_flat = reg_bypass[11];

endmodule