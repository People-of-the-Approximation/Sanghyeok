module softmax_approx (
    // Operation signals
    input  wire           i_clk,
    input  wire           i_en,
    input  wire           i_rst,

    // Length mode input
    input  wire    [3:0]  i_length_mode,

    // Data input signals
    input  wire           i_valid,
    input  wire [1023:0]  i_in_x_flat,

    // Data output signals
    output wire           o_valid,
    output wire [1023:0]  o_prob_flat
);
    // Internal signals for Max Tree
    wire          w_valid_max_out;
    wire [1023:0] w_max_bypass;
    wire [15:0]   w_in_x [0:63];

    // Internal signals for First RU Stage (x_i - max)
    wire [15:0]   w_y [0:63];
    wire [1023:0] w_y_flat;
    wire [15:0]   w_add_in [0:63];
    wire [1023:0] w_add_in_flat;

    // Internal signals for Adder Tree
    wire [1023:0] w_add_byp_flat;
    wire [15:0]   w_add_byp [0:63];
    wire          w_valid_s1;
    wire          w_valid_s2;

    // Internal signals for Second RU Stage (log2_sum - y_i)
    wire [15:0]   w_prob [0:63];
    wire [63:0]   w_valid_s1_arr;
    wire [63:0]   w_valid_s2_arr;

    // Global valid signal assignments
    assign w_valid_s1 = &(w_valid_s1_arr);
    assign o_valid    = &(w_valid_s2_arr);

    // Max tree signals
    wire [15:0] w_max64;
    wire [15:0] w_max32 [0:1];
    wire [15:0] w_max16 [0:3];
    wire [3:0]  w_mode_stg1;
    reg  [15:0] r_max_stg1 [0:63];

    // Max forwarding signals
    wire [15:0] w_max64_f;
    wire [15:0] w_max32_f [0:1];
    wire [15:0] w_max16_f [0:3];
    wire [3:0]  w_mode_stg1_f;
    wire [1023:0] w_max_bypass_f;
    wire [15:0]   w_global_max;
    wire          w_valid_max;

    // Pipeline for mode selection (matches RU stage 1 latency)
    reg  [3:0]  r_mode_byp_11 [0:10];

    // Adder tree signals
    wire [15:0] w_sum64;
    wire [15:0] w_sum32 [0:1];
    wire [15:0] w_sum16 [0:3];
    wire [3:0]  w_mode_stg3;
    reg  [15:0] r_sum_stg3 [0:63];

    // acc forwarding signals
    wire [15:0] w_sum64_f;
    wire [15:0] w_sum32_f [0:1];
    wire [15:0] w_sum16_f [0:3];
    wire [3:0]  w_mode_stg3_f;
    wire [1023:0] w_sum_bypass_f;
    wire [15:0]   w_global_sum;
    wire          w_valid_sum;

    // Data flattening and unflattening
    genvar i;
    generate
        for (i = 0; i < 64; i = i + 1) begin : data_mapping
            assign w_in_x       [i]          = w_max_bypass_f[i*16 +: 16];
            assign w_add_in_flat[i*16 +: 16] = w_add_in      [i];
            assign w_y_flat     [i*16 +: 16] = w_y           [i];
            assign w_add_byp    [i]          = w_sum_bypass_f[i*16 +: 16];
            assign o_prob_flat  [i*16 +: 16] = w_prob        [i];
        end
    endgenerate

    // Mode bypass pipeline logic
    always @(posedge i_clk) begin
        if (i_rst) begin
            for (integer k = 0; k <= 10; k = k + 1) begin
                r_mode_byp_11[k] <= 4'd0;
            end
        end
        else if (i_en) begin
            r_mode_byp_11[0] <= w_mode_stg1_f;
            for (integer k = 0; k <= 9; k = k + 1) begin
                r_mode_byp_11[k+1] <= r_mode_byp_11[k];
            end
        end
    end

    // Max tree instantiation (6-stage pipeline)
    max_tree_64 MAXTREE (
        .i_clk(i_clk),
        .i_en (i_en),
        .i_rst(i_rst),

        .i_length_mode(i_length_mode),
        .i_valid      ({64{i_valid}}),
        .i_in_flat    (i_in_x_flat),

        .o_valid_max(w_valid_max_out),
        .o_max64_0  (w_max64),
        .o_max32_0  (w_max32[0]),
        .o_max32_1  (w_max32[1]),
        .o_max16_0  (w_max16[0]),
        .o_max16_1  (w_max16[1]),
        .o_max16_2  (w_max16[2]),
        .o_max16_3  (w_max16[3]),

        .o_length_mode_byp(w_mode_stg1),
        .o_valid_byp      (),
        .o_in_byp         (w_max_bypass)
    );

    max_forwarding MAX_FORWARDING(
        .i_clk(i_clk),
        .i_en(i_en),
        .i_rst(i_rst),

        .i_valid_max  (w_valid_max_out),
        .i_loc_max    (w_max64),
        .i_length_mode(w_mode_stg1),
        .i_in_flat    (w_max_bypass),

        .o_valid_max(w_valid_max),
        .o_global_max(w_global_max),
        .o_length_mode_byp(w_mode_stg1_f),
        .o_in_byp(w_max_bypass_f),

        .i_max64_0  (w_max64),
        .i_max32_0  (w_max32[0]), .i_max32_1  (w_max32[1]),
        .i_max16_0  (w_max16[0]), .i_max16_1  (w_max16[1]), .i_max16_2  (w_max16[2]), .i_max16_3  (w_max16[3]),
        .o_max64_0  (w_max64_f),
        .o_max32_0  (w_max32_f[0]), .o_max32_1  (w_max32_f[1]),
        .o_max16_0  (w_max16_f[0]), .o_max16_1  (w_max16_f[1]), .o_max16_2  (w_max16_f[2]), .o_max16_3  (w_max16_f[3])
    );

    // Combinational logic : broadcast max value based on mode
    always @(*) begin
        case (w_mode_stg1_f)
            2'd0: begin // 16-mode
                for (integer k = 0; k < 16; k = k + 1)  r_max_stg1[k] = w_max16_f[0];
                for (integer k = 16; k < 32; k = k + 1) r_max_stg1[k] = w_max16_f[1];
                for (integer k = 32; k < 48; k = k + 1) r_max_stg1[k] = w_max16_f[2];
                for (integer k = 48; k < 64; k = k + 1) r_max_stg1[k] = w_max16_f[3];
            end
            2'd1: begin // 32-mode
                for (integer k = 0; k < 32; k = k + 1)  r_max_stg1[k] = w_max32_f[0];
                for (integer k = 32; k < 64; k = k + 1) r_max_stg1[k] = w_max32_f[1];
            end
            2'd2: begin // 64-mode
                for (integer k = 0; k < 64; k = k + 1)  r_max_stg1[k] = w_max64_f;
            end
            default: begin
                for (integer k = 0; k < 64; k = k + 1)  r_max_stg1[k] = w_global_max;
            end
        endcase
    end

    // Stage 1: (x_i - max) * log2(e) and 2^(result)
    generate
        for (i = 0; i < 64; i = i + 1) begin : stage1_ru
            RU FIRSTSTAGE (
                .i_clk(i_clk),
                .i_en(i_en),
                .i_rst(i_rst),

                .i_valid(w_valid_max),
                .i_in0  (r_max_stg1[i]),
                .i_in1  (w_in_x[i]),

                .i_sel_mult(1'b1),
                .i_sel_mux (1'b1),

                .o_valid(w_valid_s1_arr[i]),
                .o_out0 (w_y[i]),
                .o_out1 (w_add_in[i])
            );
        end
    endgenerate

    // Adder tree instantiation (12-stage pipeline)
    add_tree_64 ADDTREE (
        .i_clk(i_clk),
        .i_en (i_en),
        .i_rst(i_rst),

        .i_length_mode(r_mode_byp_11[10]),
        .i_valid      (w_valid_s1),
        .i_in0_flat   (w_y_flat),
        .i_in1_flat   (w_add_in_flat),

        .o_sum64_0(w_sum64),
        .o_sum32_0(w_sum32[0]),
        .o_sum32_1(w_sum32[1]),
        .o_sum16_0(w_sum16[0]),
        .o_sum16_1(w_sum16[1]),
        .o_sum16_2(w_sum16[2]),
        .o_sum16_3(w_sum16[3]),

        .o_length_mode_byp(w_mode_stg3),
        .o_valid_byp      (w_valid_s2),
        .o_in0_byp        (w_add_byp_flat)
    );

    acc_forwarding ADD_FORWARDING(
        .i_clk(i_clk),
        .i_en(i_en),
        .i_rst(i_rst),

        .i_valid_sum  (w_valid_s2),
        .i_loc_sum    (w_sum64),
        .i_length_mode(w_mode_stg3),
        .i_in_flat    (w_add_byp_flat),

        .o_valid_sum(w_valid_sum),
        .o_global_sum(w_global_sum),
        .o_length_mode_byp(w_mode_stg3_f),
        .o_in_byp(w_sum_bypass_f),

        .i_sum64_0 (w_sum64),
        .i_sum32_0 (w_sum32[0]), .i_sum32_1 (w_sum32[1]),
        .i_sum16_0 (w_sum16[0]), .i_sum16_1 (w_sum16[1]), .i_sum16_2 (w_sum16[2]), .i_sum16_3 (w_sum16[3]),
        .o_sum64_0 (w_sum64_f),
        .o_sum32_0 (w_sum32_f[0]), .o_sum32_1 (w_sum32_f[1]),
        .o_sum16_0 (w_sum16_f[0]), .o_sum16_1 (w_sum16_f[1]), .o_sum16_2 (w_sum16_f[2]), .o_sum16_3 (w_sum16_f[3])
    );
    // Combinational logic : broadcast sum value based on mode
    always @(*) begin
        case (w_mode_stg3_f)
            2'd0: begin // 16-mode
                for (integer k = 0; k < 16; k = k + 1)  r_sum_stg3[k] = w_sum16_f[0];
                for (integer k = 16; k < 32; k = k + 1) r_sum_stg3[k] = w_sum16_f[1];
                for (integer k = 32; k < 48; k = k + 1) r_sum_stg3[k] = w_sum16_f[2];
                for (integer k = 48; k < 64; k = k + 1) r_sum_stg3[k] = w_sum16_f[3];
            end
            2'd1: begin // 32-mode
                for (integer k = 0; k < 32; k = k + 1)  r_sum_stg3[k] = w_sum32_f[0];
                for (integer k = 32; k < 64; k = k + 1) r_sum_stg3[k] = w_sum32_f[1];
            end
            2'd2: begin // 64-mode
                for (integer k = 0; k < 64; k = k + 1)  r_sum_stg3[k] = w_sum64_f;
            end
            default: begin
                for (integer k = 0; k < 64; k = k + 1)  r_sum_stg3[k] = w_global_sum;
            end
        endcase
    end

    // Stage 2: (log2_sum - y_i) and final division via pow2
    generate
        for (i = 0; i < 64; i = i + 1) begin : stage3_ru
            RU THIRDSTAGE (
                .i_clk(i_clk),
                .i_en (i_en),
                .i_rst(i_rst),

                .i_valid(w_valid_sum),
                .i_in0  (r_sum_stg3[i]),
                .i_in1  (w_add_byp[i]),

                .i_sel_mult(1'b0),
                .i_sel_mux (1'b0),

                .o_valid(w_valid_s2_arr[i]),
                .o_out0 (),
                .o_out1 (w_prob[i])
            );
        end
    endgenerate

endmodule