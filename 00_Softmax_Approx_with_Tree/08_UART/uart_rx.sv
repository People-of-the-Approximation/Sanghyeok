module uart_rx (
    input  wire       i_clk,
    input  wire       i_rst,

    input  wire       i_rxd,

    output reg        o_rx_done,
    output wire [7:0] o_rxd
);

    reg r_data_received_R;
    reg r_data_received;

    reg [10:0] r_clk_cnt;
    reg  [2:0] r_bit_index;
    reg  [7:0] r_data_byte;

    reg  [2:0] r_state;
    
    localparam BAUD_RATE    = 11'd868; // 100MHz / 115200bps = 868
    localparam IDLE         = 3'b000;
    localparam RX_START_BIT = 3'b001;
    localparam RX_DATA_BITS = 3'b010;
    localparam RX_STOP_BIT  = 3'b011;
    localparam RESET        = 3'b100;
    
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            r_state           <= IDLE;
            r_clk_cnt         <= 11'd0;
            r_bit_index       <= 3'd0;
            r_data_received   <= 1'b0;
            r_data_received_R <= 1'b0;
            o_rx_done         <= 1'b0;
            r_data_byte       <= 8'd0;
        end 
        else begin
            r_data_received_R <= i_rxd;
            r_data_received   <= r_data_received_R;
            case (r_state)
                IDLE: begin
                    o_rx_done   <= 1'b0;
                    r_clk_cnt   <= 11'd0;
                    r_bit_index <= 3'd0;

                    if (r_data_received == 1'b0) begin
                        r_state <= RX_START_BIT;
                    end
                    else begin
                        r_state <= IDLE;
                    end
                end
                RX_START_BIT: begin
                    if (r_clk_cnt == ((BAUD_RATE - 1'b1) >> 1)) begin
                        if (r_data_received == 1'b0) begin
                            r_clk_cnt <= 11'd0;
                            r_state   <= RX_DATA_BITS;
                        end 
                        else begin
                            r_state <= IDLE;
                        end
                    end 
                    else begin
                        r_clk_cnt <= r_clk_cnt + 1'b1;
                        r_state <= RX_START_BIT;
                    end
                end
                RX_DATA_BITS: begin
                    if (r_clk_cnt < (BAUD_RATE - 1'b1)) begin
                        r_clk_cnt <= r_clk_cnt + 1'b1;
                        r_state   <= RX_DATA_BITS;
                    end else begin
                        r_clk_cnt <= 11'd0;
                        r_data_byte[r_bit_index] <= r_data_received;
                        if (r_bit_index == 3'b111) begin
                            r_bit_index <= 3'd0;
                            r_state     <= RX_STOP_BIT;
                        end
                        else begin
                            r_bit_index <= r_bit_index + 1'b1;
                            r_state     <= RX_DATA_BITS;
                        end
                    end
                end
                RX_STOP_BIT: begin
                    if (r_clk_cnt < (BAUD_RATE - 1'b1)) begin
                        r_clk_cnt <= r_clk_cnt + 1'b1;
                        r_state   <= RX_STOP_BIT;
                    end 
                    else begin
                        o_rx_done <= 1'b1;
                        r_clk_cnt <= 11'd0;
                        r_state   <= RESET;
                    end
                end
                RESET: begin
                    r_state   <= IDLE;
                    o_rx_done <= 1'b0;
                end
                default: r_state <= IDLE;
            endcase
        end
    end

    assign o_rxd = r_data_byte;
endmodule