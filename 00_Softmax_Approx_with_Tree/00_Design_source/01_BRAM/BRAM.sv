module BRAM (
    // Operation signals
    input  wire          i_clk,

    // Data signals A (Write Port)
    input  wire          i_cena,
    input  wire          i_wea,
    input  wire    [7:0] i_addra,
    input  wire [1027:0] i_dina,

    // Data signals B (Read Port)
    input  wire          i_cenb,
    input  wire    [7:0] i_addrb,
    output wire [1027:0] o_doutb
);

    // BRAM IP Instance
    BRAM_16 BRAM_INST (
        .clka (i_clk),
        .ena  (i_cena),
        .wea  (i_wea),
        .addra(i_addra),
        .dina (i_dina),

        .clkb (i_clk),
        .enb  (i_cenb),
        .addrb(i_addrb),
        .doutb(o_doutb)
    );
endmodule