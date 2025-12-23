module max_tree_64 (
    input clk,
    input en,
    input rst,

    input [1:0] length_mode,

    input [63:0] valid_in,
    input [1023:0] in_flat,

    output valid_MAX_out,
    output [15:0] MAX_64_0,

    output [15:0] MAX_32_0,
    output [15:0] MAX_32_1,

    output [15:0] MAX_16_0,
    output [15:0] MAX_16_1,
    output [15:0] MAX_16_2,
    output [15:0] MAX_16_3,

    output [1:0] length_mode_bypass,
    output [63:0] valid_bypass_out,
    output [1023:0] in_bypass
);

    wire [63:0] stage_valid [0:6];
    wire [15:0] stage_data [0:6][0:63];

    reg [1:0] reg_length_mode_bypass [5:0];
    reg [63:0] reg_valid_bypass [0:5];
    reg [1023:0] reg_bypass [0:5];

    integer k;
    always @(posedge clk) begin
        if (rst) begin
            for (k = 0; k <= 5; k = k + 1) begin
                reg_length_mode_bypass[k] <= 2'b0;
                reg_valid_bypass[k] <= {64{1'b0}};
                reg_bypass[k] <= {64{16'd0}};
            end
        end
        else if (en) begin
            reg_length_mode_bypass[0] <= length_mode;
            reg_valid_bypass[0] <= valid_in;
            reg_bypass[0] <= in_flat;
            for (k = 0; k <= 4; k = k + 1) begin
                reg_length_mode_bypass[k+1] <= reg_length_mode_bypass[k];
                reg_valid_bypass[k+1] <= reg_valid_bypass[k];
                reg_bypass[k+1] <= reg_bypass[k];
            end
        end
    end

    assign stage_valid[0] = valid_in;

    genvar i, j;
    generate
        for (i = 0; i < 64; i = i + 1) begin
            assign stage_data[0][i] = in_flat[i*16 +: 16];
        end
    endgenerate
    
    generate
        for (j = 0; j < 6; j = j + 1) begin : stages
            for (i = 0; i < (64 >> (j+1)); i = i + 1) begin : comps
                max_comparator MAX(
                    .clk(clk),
                    .en(en),
                    .rst(rst),

                    .valid_A_in(stage_valid[j][2*i]),
                    .A_in(stage_data[j][2*i]),

                    .valid_B_in(stage_valid[j][2*i+1]),
                    .B_in(stage_data[j][2*i+1]),

                    .valid_out(stage_valid[j+1][i]),
                    .MAX_out(stage_data[j+1][i])
                );
            end
        end
    endgenerate

    reg [15:0] max_32_0_pipe;
    reg [15:0] max_32_1_pipe;

    reg [15:0] max_16_0_pipe [0:1];
    reg [15:0] max_16_1_pipe [0:1];
    reg [15:0] max_16_2_pipe [0:1];
    reg [15:0] max_16_3_pipe [0:1];

    always @(posedge clk) begin
        if (rst) begin

            max_32_0_pipe <= 16'd0;
            max_32_1_pipe <= 16'd0;

            max_16_0_pipe[0] <= 16'd0;
            max_16_1_pipe[0] <= 16'd0;
            max_16_2_pipe[0] <= 16'd0;
            max_16_3_pipe[0] <= 16'd0;

            max_16_0_pipe[1] <= 16'd0;
            max_16_1_pipe[1] <= 16'd0;
            max_16_2_pipe[1] <= 16'd0;
            max_16_3_pipe[1] <= 16'd0;
        end 
        else if (en) begin
            max_32_0_pipe <= stage_data[5][0];
            max_32_1_pipe <= stage_data[5][1];

            max_16_0_pipe[0] <= stage_data[4][0];
            max_16_1_pipe[0] <= stage_data[4][1];
            max_16_2_pipe[0] <= stage_data[4][2];
            max_16_3_pipe[0] <= stage_data[4][3];

            max_16_0_pipe[1] <= max_16_0_pipe[0];
            max_16_1_pipe[1] <= max_16_1_pipe[0];
            max_16_2_pipe[1] <= max_16_2_pipe[0];
            max_16_3_pipe[1] <= max_16_3_pipe[0];
        end
    end


    assign valid_MAX_out = stage_valid[6][0];

    assign MAX_64_0 = stage_data[6][0];

    assign MAX_32_0 = max_32_0_pipe;
    assign MAX_32_1 = max_32_1_pipe;

    assign MAX_16_0 = max_16_0_pipe[1];
    assign MAX_16_1 = max_16_1_pipe[1];
    assign MAX_16_2 = max_16_2_pipe[1];
    assign MAX_16_3 = max_16_3_pipe[1];

    assign length_mode_bypass = reg_length_mode_bypass[5];
    assign valid_bypass_out = reg_valid_bypass[5];
    assign in_bypass = reg_bypass[5];

endmodule

module max_comparator (
    input clk,
    input en,
    input rst,

    input valid_A_in,
    input signed [15:0] A_in,

    input valid_B_in,
    input signed [15:0] B_in,

    output reg valid_out,
    output reg signed [15:0] MAX_out
);

    always @(posedge clk) begin
        if (rst) begin
            MAX_out <= 16'd0;
            valid_out <= 1'b0;
        end 
        else if (en) begin
            MAX_out <= (A_in > B_in) ? A_in : B_in;
            valid_out <= valid_A_in & valid_B_in;
        end
    end
endmodule