module BRAM_FSM_tb;
    // Operation control signals
    reg           i_clk;
    reg           i_en;
    reg           i_rst;

    // Start Pulse
    reg           i_start;
    // Busy Signal
    wire           o_busy;

    // BRAM Interface
    // Port A: Write Only
    wire           o_cena;   // Chip Enable
    wire           o_wea;    // Write Enable
    wire    [4:0]  o_addra;  // Address
    wire  [1027:0] o_dina;   // Data Input (Result to BRAM)
    // Port B: Read Only
    wire           o_cenb;   // Chip Enable
    wire    [4:0]  o_addrb;  // Address
    wire  [1027:0] i_doutb;  // Data Output (Source from BRAM)

    // Softmax Interface (FSM -> Softmax)
    wire    [3:0]  o_length_mode; // Mode bits
    wire           o_valid;       // Start pulse
    wire  [1023:0] o_in_x_flat;   // Input features

    // Softmax Interface (Softmax -> FSM)
    wire          i_valid;    // Result valid from Softmax
    wire [1023:0] i_prob_flat; // Computed result

    // Instantiate the BRAM_FSM module
    BRAM_FSM UUT(
        .i_clk(i_clk),
        .i_en(i_en),
        .i_rst(i_rst),
        .i_start(i_start),
        .o_busy(o_busy),
        .o_cena(o_cena),
        .o_wea(o_wea),
        .o_addra(o_addra),
        .o_dina(o_dina),
        .o_cenb(o_cenb),
        .o_addrb(o_addrb),
        .i_doutb(i_doutb),
        .o_length_mode(o_length_mode),
        .o_valid(o_valid),
        .o_in_x_flat(o_in_x_flat),
        .i_valid(i_valid),
        .i_prob_flat(i_prob_flat)
    );

   BRAM BRAM_inst(
        // Operation signals
        .i_clk(i_clk),

        // Data signals A (Write Port)
        .i_cena(o_cena),
        .i_wea(o_wea),
        .i_addra(o_addra),
        .i_dina(o_dina),

        // Data signals B (Read Port)
        .i_cenb(o_cenb),
        .i_addrb(o_addrb),
        .o_doutb(i_doutb)
    );

    softmax_approx softmax_inst(
        .i_clk(i_clk),
        .i_en(i_en),
        .i_rst(i_rst),
        .i_length_mode(o_length_mode),
        
        .i_valid(o_valid),
        .i_in_x_flat(o_in_x_flat),

        .o_valid(i_valid),
        .o_prob_flat(i_prob_flat)
    );


    // Clock generation
    initial i_clk = 0;
    always #5 i_clk = ~i_clk;

    initial begin
        // Initialize signals
        i_en    = 1'b1;
        i_rst   = 1'b1;
        i_start = 1'b0;

        // Release reset
        #15;
        i_rst = 1'b0;

        // Start the FSM
        #10;
        i_start = 1'b1;
        #10;
        i_start = 1'b0;

        #800;
        $finish;
    end
    
endmodule