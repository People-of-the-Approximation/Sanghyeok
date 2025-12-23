module softmax_approx(
    input clk,
    input en,
    input rst,

    input [1:0] length_mode,

    input valid_in,
    input [1023:0] in_x_flat,

    output valid_out,
    output [1023:0] prob_flat
);
    wire valid_max_out;
    wire [15:0] max_x;
    wire [63:0] valid_bypass_out;
    wire [1023:0] max_bypass;

    wire [15:0] in_x [0:63];

    wire [15:0] prob [0:63];
    wire [15:0] add_in [0:63];

    wire [15:0] y [0:63];
    wire [1023:0] y_flat;

    wire [1023:0] add_in_flat;
    wire [15:0] add_out;

    wire [1023:0] add_bypass_flat;
    wire [15:0] add_bypass [0:63];

    wire [63:0] valid_s1_arr;
    wire [63:0] valid_s2_arr;

    wire valid_s1;
    wire valid_s2;

    assign valid_s1 = &(valid_s1_arr);
    assign valid_out = &(valid_s2_arr);

    genvar i;
    generate
        for (i = 0; i < 64; i = i + 1) begin
            assign in_x[i] = max_bypass[i*16 +: 16];
            assign add_in_flat[i*16 +: 16] = add_in[i];
            assign y_flat[i*16 +: 16] = y[i];
            assign add_bypass[i] = add_bypass_flat[i*16 +: 16];
            assign prob_flat[i*16 +: 16] = prob[i];
        end
    endgenerate

    wire [15:0] MAX_64;
    wire [15:0] MAX_32 [0:1];
    wire [15:0] MAX_16 [0:3];

    wire [1:0] length_mode_stg_1;
    reg [15:0] max_stg_1 [0:63];

    reg [1:0] length_mode_bypass_11 [0:10];

    wire [15:0] ADD_64;
    wire [15:0] ADD_32 [0:1];
    wire [15:0] ADD_16 [0:3];

    wire [1:0] length_mode_stg_3;
    reg [15:0] add_stg_3 [0:63];

    integer k;
    always @(posedge clk) begin
        if (rst) begin
            for (k = 0; k <= 10; k = k + 1) begin
                length_mode_bypass_11[k] <= 2'd0;
            end
        end
        else if (en) begin
            length_mode_bypass_11[0] <= length_mode_stg_1;
            for (k = 0; k <= 9; k = k + 1) begin
                length_mode_bypass_11[k+1] <= length_mode_bypass_11[k];
            end
        end
    end

    max_tree_64 max_tree(
        .clk(clk),
        .en(en),
        .rst(rst),

        .length_mode(length_mode),

        .valid_in({64{valid_in}}),
        .in_flat(in_x_flat),

        .valid_MAX_out(valid_max_out),

        .MAX_64_0(MAX_64),

        .MAX_32_0(MAX_32[0]),
        .MAX_32_1(MAX_32[1]),

        .MAX_16_0(MAX_16[0]),
        .MAX_16_1(MAX_16[1]),
        .MAX_16_2(MAX_16[2]),
        .MAX_16_3(MAX_16[3]),

        .length_mode_bypass(length_mode_stg_1),

        .valid_bypass_out(valid_bypass_out),
        .in_bypass(max_bypass)
    );

    always @(*) begin
        case (length_mode_stg_1)
            2'd0: begin
                for (k = 0; k < 16; k = k + 1) begin
                    max_stg_1[k] = MAX_16[0];
                end
                for (k = 16; k < 32; k = k + 1) begin
                    max_stg_1[k] = MAX_16[1];
                end
                for (k = 32; k < 48; k = k + 1) begin
                    max_stg_1[k] = MAX_16[2];
                end
                for (k = 48; k < 64; k = k + 1) begin
                    max_stg_1[k] = MAX_16[3];
                end
            end
            2'd1: begin
                for (k = 0; k < 32; k = k + 1) begin
                    max_stg_1[k] = MAX_32[0];
                end
                for (k = 32; k < 64; k = k + 1) begin
                    max_stg_1[k] = MAX_32[1];
                end
            end
            2'd2: begin
                for (k = 0; k < 64; k = k + 1) begin
                    max_stg_1[k] = MAX_64;
                end
            end
            default: begin
                for (k = 0; k < 64; k = k + 1) begin
                    max_stg_1[k] = MAX_64;
                end
            end
        endcase
    end

    generate
        for (i = 0; i < 64; i = i + 1) begin
            RU FIRSTSTAGE(
                .clk(clk),
                .en(en),
                .rst(rst),

                .valid_in(valid_max_out & valid_bypass_out[i]),
                .in_0(max_stg_1[i]),
                .in_1(in_x[i]),

                .sel_mult(1'b1),
                .sel_mux(1'b1),

                .valid_out(valid_s1_arr[i]),
                .out_0(y[i]),
                .out_1(add_in[i])
            );
        end
    endgenerate

    add_tree_64 ADDT(
        .clk(clk),
        .en(en),
        .rst(rst),

        .length_mode(length_mode_bypass_11[10]),

        .valid_in(valid_s1),
        .in_0_flat(y_flat),
        .in_1_flat(add_in_flat),

        .in_1_sum_64_0(ADD_64),

        .in_1_sum_32_0(ADD_32[0]),
        .in_1_sum_32_1(ADD_32[1]),

        .in_1_sum_16_0(ADD_16[0]),
        .in_1_sum_16_1(ADD_16[1]),
        .in_1_sum_16_2(ADD_16[2]),
        .in_1_sum_16_3(ADD_16[3]),

        .length_mode_bypass(length_mode_stg_3),
        .valid_bypass_out(valid_s2),
        .in_bypass_flat(add_bypass_flat)
    );

    always @(*) begin
        case (length_mode_stg_3)
            2'd0: begin
                for (k = 0; k < 16; k = k + 1) begin
                    add_stg_3[k] = ADD_16[0];
                end
                for (k = 16; k < 32; k = k + 1) begin
                    add_stg_3[k] = ADD_16[1];
                end
                for (k = 32; k < 48; k = k + 1) begin
                    add_stg_3[k] = ADD_16[2];
                end
                for (k = 48; k < 64; k = k + 1) begin
                    add_stg_3[k] = ADD_16[3];
                end
            end
            2'd1: begin
                for (k = 0; k < 32; k = k + 1) begin
                    add_stg_3[k] = ADD_32[0];
                end
                for (k = 32; k < 64; k = k + 1) begin
                    add_stg_3[k] = ADD_32[1];
                end
            end
            2'd2: begin
                for (k = 0; k < 64; k = k + 1) begin
                    add_stg_3[k] = ADD_64;
                end
            end
            default: begin
                for (k = 0; k < 64; k = k + 1) begin
                    add_stg_3[k] = ADD_64;
                end
            end
        endcase
    end

    generate
        for (i = 0; i < 64; i = i + 1) begin
            RU SECONDSTAGE(
                .clk(clk),
                .en(en),
                .rst(rst),

                .valid_in(valid_s2),
                .in_0(add_stg_3[i]),
                .in_1(add_bypass[i]),

                .sel_mult(1'b0),
                .sel_mux(1'b0),

                .valid_out(valid_s2_arr[i]),
                .out_0(),
                .out_1(prob[i])
            );
        end
    endgenerate

endmodule