module fpga_softmax_top(
    input  wire       i_clk,  // System Clock (e.g., 50MHz or 100MHz)
    input  wire       i_rst,  // System Reset

    // UART Hardware Pins
    input  wire       i_rxd,
    output wire       o_txd,

    // Debug LEDs (Optional)
    output wire [3:0] o_led
);

    // --- Signals ---
    wire        w_rx_done;
    wire [7:0]  w_rx_data;
    wire        w_tx_start;
    wire [7:0]  w_tx_data;
    wire        w_tx_done;
    wire        w_tx_active;

    // Controller <-> Softmax Core Connections
    wire         ctrl_cena;
    wire         ctrl_wea;
    wire    [7:0] ctrl_addra;
    wire [1027:0] ctrl_dina;
    
    wire         ctrl_cenb;
    wire    [7:0] ctrl_addrb;
    wire [1027:0] ctrl_doutb;

    wire        ctrl_start_core;
    wire        core_busy;
    wire  [7:0] ctrl_core_depth;

    uart_rx  u_rx(
        .i_clk(i_clk), 
        .i_rst(i_rst), 
        .i_rxd(i_rxd),
        .o_rx_done(w_rx_done), 
        .o_rxd(w_rx_data)
    );

    uart_tx u_tx(
        .i_clk(i_clk), 
        .i_rst(i_rst),
        .i_start(w_tx_start), 
        .i_Byte_To_Send(w_tx_data),
        .o_tx_active(w_tx_active), 
        .o_tx_serial(o_txd), 
        .o_tx_done(w_tx_done)
    );

    // --- 2. Controller ---
    uart_bram_controller u_ctrl(
        .i_clk(i_clk),
        .i_rst(i_rst),
        
        // UART
        .i_rx_done(w_rx_done), 
        .i_rxd(w_rx_data),
        .o_tx_start(w_tx_start), 
        .o_tx_byte(w_tx_data), 
        .i_tx_done(w_tx_done),
        
        // Memory Access (External Ports of Softmax Core)
        .o_mem_cena(ctrl_cena), 
        .o_mem_wea(ctrl_wea),
        .o_mem_addra(ctrl_addra), 
        .o_mem_dina(ctrl_dina),
        .o_mem_cenb(ctrl_cenb), 
        .o_mem_addrb(ctrl_addrb),
        .i_mem_doutb(ctrl_doutb),
        
        // Core Control
        .o_core_start(ctrl_start_core), 
        .i_core_busy(core_busy),
        .o_core_depth(ctrl_core_depth),
        .o_debug_state(o_led)
    );

    // --- 3. Softmax Core (The DUT) ---
    // 이전에 작성한 softmax_core (BRAM arbitration 포함)
    softmax_core u_core (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_en(1'b1),            // 항상 Enable
        .i_start(ctrl_start_core),
        .o_busy(core_busy),
        .i_depth(ctrl_core_depth),

        // External Write Interface (Connected to Controller)
        .i_ext_cena(ctrl_cena),
        .i_ext_wea(ctrl_wea),
        .i_ext_addra(ctrl_addra),
        .i_ext_dina(ctrl_dina),

        // External Read Interface (Connected to Controller)
        .i_ext_cenb(ctrl_cenb),
        .i_ext_addrb(ctrl_addrb),
        .o_ext_doutb(ctrl_doutb)
    );

endmodule