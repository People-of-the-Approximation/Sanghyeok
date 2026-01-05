module acc_module (
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

    // Data global sum output
    output wire   [31:0] o_global_sum,
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
    // Data output signals
    wire    [31:0] w_sum64_0;
    wire    [31:0] w_sum32_0;
    wire    [31:0] w_sum32_1;
    wire    [31:0] w_sum16_0;
    wire    [31:0] w_sum16_1;
    wire    [31:0] w_sum16_2;
    wire    [31:0] w_sum16_3;

    // Bypass outputs
    wire     [3:0] w_length_mode_byp;
    wire           w_valid_byp;
    wire  [1023:0] w_in0_byp;

    add_tree_64 ADDER_TREE (
        .i_clk             (i_clk),
        .i_en              (i_en),
        .i_rst             (i_rst),
        
        .i_length_mode     (i_length_mode),

        .i_valid           (i_valid),
        .i_in0_flat        (i_in0_flat),
        .i_in1_flat        (i_in1_flat),

        .o_sum64_0         (w_sum64_0),
        .o_sum32_0         (w_sum32_0),
        .o_sum32_1         (w_sum32_1),
        .o_sum16_0         (w_sum16_0),
        .o_sum16_1         (w_sum16_1),
        .o_sum16_2         (w_sum16_2),
        .o_sum16_3         (w_sum16_3),

        .o_length_mode_byp (w_length_mode_byp),
        .o_valid_byp       (w_valid_byp),
        .o_in0_byp         (w_in0_byp)
    );

    acc_forwarding ACC_FORWARDING (
        .i_clk           (i_clk),
        .i_en            (i_en),
        .i_rst           (i_rst),
        .i_valid_sum     (w_valid_byp),
        .i_loc_sum       (w_sum64_0),
        .i_length_mode   (w_length_mode_byp),
        .i_in_flat       (w_in0_byp),

        .o_valid_sum       (o_valid_byp),
        .o_global_sum      (o_global_sum),
        .o_length_mode_byp (o_length_mode_byp),
        .o_in_byp          (o_in0_byp),

        .i_sum64_0      (w_sum64_0),
        .i_sum32_0      (w_sum32_0), 
        .i_sum32_1      (w_sum32_1),
        .i_sum16_0      (w_sum16_0), 
        .i_sum16_1      (w_sum16_1),
        .i_sum16_2      (w_sum16_2), 
        .i_sum16_3      (w_sum16_3),

        .o_sum64_0      (o_sum64_0),
        .o_sum32_0      (o_sum32_0),
        .o_sum32_1      (o_sum32_1),
        .o_sum16_0      (o_sum16_0),
        .o_sum16_1      (o_sum16_1),
        .o_sum16_2      (o_sum16_2),
        .o_sum16_3      (o_sum16_3)
    );

endmodule