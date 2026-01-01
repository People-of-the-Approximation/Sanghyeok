module max_module (
    // Operation signals
    input  wire           i_clk,
    input  wire           i_en,
    input  wire           i_rst,

    // Length mode input
    input  wire     [3:0] i_length_mode,

    // Data input signals
    input  wire   [63:0]  i_valid,
    input  wire [1023:0]  i_in_flat,

    output wire           o_valid_max,
    output wire    [15:0] o_global_max,
    // Data output signals
    output wire    [15:0] o_max64_0,
    output wire    [15:0] o_max32_0,
    output wire    [15:0] o_max32_1,
    output wire    [15:0] o_max16_0,
    output wire    [15:0] o_max16_1,
    output wire    [15:0] o_max16_2,
    output wire    [15:0] o_max16_3,

    // Bypass outputs
    output wire     [3:0] o_length_mode_byp,
    output wire  [1023:0] o_in_byp
);
        // Data output signals
    wire    [15:0] w_max64_0;
    wire    [15:0] w_max32_0;
    wire    [15:0] w_max32_1;
    wire    [15:0] w_max16_0;
    wire    [15:0] w_max16_1;
    wire    [15:0] w_max16_2;
    wire    [15:0] w_max16_3;

    // Bypass outputs
    wire     [3:0] w_length_mode_byp;
    wire           w_valid_max;
    wire  [1023:0] w_in_byp;

    max_tree_64 MAX_TREE (
        .i_clk           (i_clk),
        .i_en            (i_en),
        .i_rst           (i_rst),

        .i_length_mode   (i_length_mode),

        .i_valid         (i_valid),
        .i_in_flat       (i_in_flat),

        .o_max64_0       (w_max64_0),
        .o_max32_0       (w_max32_0),
        .o_max32_1       (w_max32_1),
        .o_max16_0       (w_max16_0),
        .o_max16_1       (w_max16_1),
        .o_max16_2       (w_max16_2),
        .o_max16_3       (w_max16_3),
        .o_length_mode_byp (w_length_mode_byp),
        .o_valid_max       (w_valid_max),
        .o_in_byp          (w_in_byp)
    );

    max_forwarding MAX_FORWARDING (
        .i_clk           (i_clk),
        .i_en            (i_en),
        .i_rst           (i_rst),

        .i_valid_max     (w_valid_max),
        .i_loc_max       (w_max64_0),
        .i_length_mode   (w_length_mode_byp),
        .i_in_flat       (w_in_byp),

        .o_valid_max       (o_valid_max),
        .o_global_max      (o_global_max),
        .o_length_mode_byp (o_length_mode_byp),
        .o_in_byp          (o_in_byp),

        .i_max64_0      (w_max64_0),
        .i_max32_0      (w_max32_0), .i_max32_1      (w_max32_1),
        .i_max16_0      (w_max16_0), .i_max16_1      (w_max16_1),
        .i_max16_2      (w_max16_2), .i_max16_3      (w_max16_3),

        .o_max64_0      (o_max64_0),
        .o_max32_0      (o_max32_0), .o_max32_1      (o_max32_1),
        .o_max16_0      (o_max16_0), .o_max16_1      (o_max16_1),
        .o_max16_2      (o_max16_2), .o_max16_3      (o_max16_3)
    );
endmodule