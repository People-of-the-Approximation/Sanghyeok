module softmax_core(
    // System Signals
    input  wire          i_clk,
    input  wire          i_rst,
    input  wire          i_en,
    input  wire          i_start,
    output wire          o_busy,

    // External Memory Interface (CPU or Controller Access)
    // External Write Port (Port A)
    input  wire          i_ext_cena,   // External Chip Enable
    input  wire          i_ext_wea,    // External Write Enable
    input  wire    [4:0] i_ext_addra,  // External Address
    input  wire [1027:0] i_ext_dina,   // External Data Input
    
    // External Read Port (Port B)
    input  wire          i_ext_cenb,   // External Chip Enable
    input  wire    [4:0] i_ext_addrb,  // External Address
    output wire [1027:0] o_ext_doutb   // External Data Output
);
    // Signals from BRAM_FSM (Core Internal)
    wire          core_cena;
    wire          core_wea;
    wire    [4:0] core_addra;
    wire [1027:0] core_dina;
    
    wire          core_cenb;
    wire    [4:0] core_addrb;
    wire [1027:0] core_doutb;

    // Softmax Interface Signals (Between FSM and Approx Core)
    wire    [3:0] w_length_mode;
    wire          w_valid_to_soft;
    wire [1023:0] w_in_x_flat;
    wire          w_valid_from_soft;
    wire [1023:0] w_prob_flat;

    // Final MUXed Signals to BRAM
    wire          final_cena;
    wire          final_wea;
    wire    [4:0] final_addra;
    wire [1027:0] final_dina;
    
    wire          final_cenb;
    wire    [4:0] final_addrb;
    wire [1027:0] final_doutb;

    // Busy Signal Buffer
    wire          w_busy;

    // BRAM_FSM: Controls the Logic Flow
    BRAM_FSM fsm_inst(
        .i_clk        (i_clk),
        .i_en         (i_en),
        .i_rst        (i_rst),
        .i_start      (i_start),
        .o_busy       (w_busy),       // Indicates if Core is working
        
        // FSM Access to BRAM
        .o_cena       (core_cena),
        .o_wea        (core_wea),
        .o_addra      (core_addra),
        .o_dina       (core_dina),
        
        .o_cenb       (core_cenb),
        .o_addrb      (core_addrb),
        .i_doutb      (core_doutb),   // Takes Data from MUXed BRAM output
        
        // Interface with Softmax Core
        .o_length_mode(w_length_mode),
        .o_valid      (w_valid_to_soft),
        .o_in_x_flat  (w_in_x_flat),
        .i_valid      (w_valid_from_soft),
        .i_prob_flat  (w_prob_flat)
    );

    // Softmax Arithmetic Core
    softmax_approx softmax_inst(
        .i_clk        (i_clk),
        .i_en         (i_en),
        .i_rst        (i_rst),
        .i_length_mode(w_length_mode),
        .i_valid      (w_valid_to_soft),
        .i_in_x_flat  (w_in_x_flat),
        .o_valid      (w_valid_from_soft),
        .o_prob_flat  (w_prob_flat)
    );
    
    // Port A (Write Path)
    assign final_cena  = (w_busy) ? core_cena  : i_ext_cena;
    assign final_wea   = (w_busy) ? core_wea   : i_ext_wea;
    assign final_addra = (w_busy) ? core_addra : i_ext_addra;
    assign final_dina  = (w_busy) ? core_dina  : i_ext_dina;

    // Port B (Read Path)
    assign final_cenb  = (w_busy) ? core_cenb  : i_ext_cenb;
    assign final_addrb = (w_busy) ? core_addrb : i_ext_addrb;

    // Data Routing (Read Data from BRAM)
    // Both FSM and External Output need the BRAM data
    assign core_doutb  = final_doutb; 
    assign o_ext_doutb = final_doutb;

    // Output Busy Signal
    assign o_busy = w_busy;
    
    BRAM bram_inst(
        .i_clk   (i_clk),
        
        // Port A Connections (MUXed)
        .i_cena  (final_cena),
        .i_wea   (final_wea),
        .i_addra (final_addra),
        .i_dina  (final_dina),
        
        // Port B Connections (MUXed)
        .i_cenb  (final_cenb),
        .i_addrb (final_addrb),
        .o_doutb (final_doutb)
    );

endmodule