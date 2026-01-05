module fpga_softmax_top(
    // System Signals
    input  wire       i_clk,
    input  wire       i_rstn, 

    // UART Hardware Pins
    input  wire       i_rxd,
    output wire       o_txd,

    // Debug LEDs
    output wire [3:0] o_led,
    output wire       o_led_busy
);
    wire i_rst;
    assign i_rst = ~i_rstn;

    wire        w_rx_done;
    wire [7:0]  w_rx_data;
    wire        w_tx_start;
    wire [7:0]  w_tx_data;
    wire        w_tx_done;
    wire        w_tx_active;

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

    uart_bram_controller u_ctrl(
        .i_clk(i_clk),
        .i_rst(i_rst),
        
        .i_rx_done(w_rx_done), 
        .i_rxd(w_rx_data),
        .o_tx_start(w_tx_start), 
        .o_tx_byte(w_tx_data), 
        .i_tx_done(w_tx_done),
        
        .o_mem_cena(ctrl_cena), 
        .o_mem_wea(ctrl_wea),
        .o_mem_addra(ctrl_addra), 
        .o_mem_dina(ctrl_dina),
        .o_mem_cenb(ctrl_cenb), 
        .o_mem_addrb(ctrl_addrb),
        .i_mem_doutb(ctrl_doutb),
        
        .o_core_start(ctrl_start_core), 
        .i_core_busy(core_busy),
        .o_core_depth(ctrl_core_depth),
        .o_debug_state(o_led)
    );

    softmax_core u_core (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_en(1'b1),
        .i_start(ctrl_start_core),
        .o_busy(core_busy),
        .i_depth(ctrl_core_depth),

        .i_ext_cena(ctrl_cena),
        .i_ext_wea(ctrl_wea),
        .i_ext_addra(ctrl_addra),
        .i_ext_dina(ctrl_dina),

        .i_ext_cenb(ctrl_cenb),
        .i_ext_addrb(ctrl_addrb),
        .o_ext_doutb(ctrl_doutb)
    );

    assign o_led_busy = core_busy;
endmodule