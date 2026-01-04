module uart_bram_controller(
    // System Signals
    input  wire          i_clk,
    input  wire          i_rst,

    // UART Interface
    input  wire          i_rx_done,
    input  wire    [7:0] i_rxd,
    output reg           o_tx_start,
    output reg     [7:0] o_tx_byte,
    input  wire          i_tx_done,

    // Interface to Softmax Core (External Access Ports)
    // Write Port (Port A)
    output reg           o_mem_cena,
    output reg           o_mem_wea,
    output reg     [7:0] o_mem_addra,
    output reg  [1027:0] o_mem_dina,
    // Read Port (Port B)
    output reg           o_mem_cenb,
    output reg     [7:0] o_mem_addrb,
    input  wire [1027:0] i_mem_doutb,

    // Core Control
    output reg           o_core_start,
    output reg     [7:0] o_core_depth,
    input  wire          i_core_busy,

    // Debug State
    output wire    [3:0] o_debug_state
);

    localparam BYTES_PER_ROW = 129;

    localparam S_IDLE         = 4'd0;
    localparam S_RX_ACC       = 4'd1;
    localparam S_RX_WRITE     = 4'd2;
    localparam S_CORE_START   = 4'd3;
    localparam S_CORE_WAIT    = 4'd4;
    localparam S_TX_REQ       = 4'd5;
    localparam S_TX_WAIT_1    = 4'd6;
    localparam S_TX_WAIT_2    = 4'd7;
    localparam S_TX_LOAD      = 4'd8;
    localparam S_TX_SEND      = 4'd9;
    localparam S_TX_CHECK     = 4'd10;
    localparam S_RX_WAIT_DATA = 4'd11;

    reg [3:0]    r_state;
    reg [1031:0] r_buffer;
    reg [7:0]    r_byte_cnt;
    reg [7:0]    r_row_cnt;

    assign o_debug_state = r_state;

    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            r_state      <= S_IDLE;
            r_buffer     <= 0;
            r_byte_cnt   <= 0;
            r_row_cnt    <= 0;
            o_mem_cena   <= 0; 
            o_mem_wea    <= 0; 
            o_mem_addra  <= 0; 
            o_mem_dina   <= 0;
            o_mem_cenb   <= 0; 
            o_mem_addrb  <= 0;
            o_tx_start   <= 0; 
            o_tx_byte    <= 0;
            o_core_start <= 0;
            o_core_depth <= 0;
        end 
        else begin
            case (r_state)
                S_IDLE: begin
                    o_core_start <= 1'b0;
                    r_byte_cnt   <= 0;
                    r_row_cnt    <= 0;
                    if (i_rx_done) begin
                        o_core_depth <= i_rxd;
                        r_state      <= S_RX_WAIT_DATA;
                    end
                end
                S_RX_WAIT_DATA: begin
                    if (i_rx_done) begin
                        r_buffer   <= {r_buffer[1023:0], i_rxd};
                        r_byte_cnt <= 1;
                        r_state    <= S_RX_ACC;
                    end
                end
                S_RX_ACC: begin
                    o_mem_cena <= 0; o_mem_wea <= 0;
                    if (i_rx_done) begin
                        r_buffer <= {r_buffer[1023:0], i_rxd};
                        if (r_byte_cnt == BYTES_PER_ROW - 1) begin
                            r_state <= S_RX_WRITE;
                        end else begin
                            r_byte_cnt <= r_byte_cnt + 1;
                        end
                    end
                end
                S_RX_WRITE: begin
                    o_mem_cena  <= 1'b1;
                    o_mem_wea   <= 1'b1;
                    o_mem_addra <= r_row_cnt;
                    o_mem_dina  <= r_buffer[1027:0]; 
                    if (r_row_cnt == o_core_depth) begin
                        r_state <= S_CORE_START;
                    end else begin
                        r_row_cnt  <= r_row_cnt + 1;
                        r_byte_cnt <= 0;
                        r_state    <= S_RX_ACC;
                    end
                end
                S_CORE_START: begin
                    o_mem_cena   <= 0; 
                    o_mem_wea    <= 0;
                    o_core_start <= 1'b1;
                    r_state      <= S_CORE_WAIT;
                end
                S_CORE_WAIT: begin
                    o_core_start <= 1'b0;
                    if (i_core_busy == 1'b1) begin
                    end else if (o_core_start == 0) begin
                        r_row_cnt <= 0; 
                        r_state   <= S_TX_REQ;
                    end
                end
                S_TX_REQ: begin
                    o_mem_cenb  <= 1'b1;
                    o_mem_addrb <= r_row_cnt;
                    r_state     <= S_TX_WAIT_1;
                end
                S_TX_WAIT_1: begin
                    o_mem_cenb  <= 1'b1;
                    r_state     <= S_TX_WAIT_2;
                end
                S_TX_WAIT_2: begin
                    o_mem_cenb  <= 1'b0;
                    r_state     <= S_TX_LOAD;
                end
                S_TX_LOAD: begin
                    r_buffer[1027:0]    <= i_mem_doutb; 
                    r_buffer[1031:1028] <= 4'b0; 
                    r_byte_cnt <= 0;
                    r_state    <= S_TX_SEND;
                end
                S_TX_SEND: begin
                    if (!i_tx_done) begin
                        o_tx_start <= 1'b1;
                        o_tx_byte  <= r_buffer[1031:1024];
                        r_buffer   <= {r_buffer[1023:0], 8'h00}; 
                        r_state    <= S_TX_CHECK;
                    end
                end
                S_TX_CHECK: begin
                    o_tx_start <= 1'b0;
                    if (i_tx_done) begin
                        if (r_byte_cnt == BYTES_PER_ROW - 1) begin
                            if (r_row_cnt == o_core_depth) begin
                                r_state <= S_IDLE;
                            end else begin
                                r_row_cnt <= r_row_cnt + 1;
                                r_state   <= S_TX_REQ;
                            end
                        end else begin
                            r_byte_cnt <= r_byte_cnt + 1;
                            r_state    <= S_TX_SEND;
                        end
                    end
                end
                default: r_state <= S_IDLE;
            endcase
        end
    end
endmodule