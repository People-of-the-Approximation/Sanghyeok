module uart_tx (
    input  wire       i_clk,
    input  wire       i_rst,
    
    input  wire       i_start,
    input  wire [7:0] i_Byte_To_Send,

    output wire       o_tx_active,
    output  reg       o_tx_serial,
    output  reg       o_tx_done
);
    localparam BAUD_RATE    = 11'd868;
    localparam IDLE         = 3'b000;
    localparam TX_START_BIT = 3'b001;
    localparam TX_DATA_BITS = 3'b010;
    localparam TX_STOP_BIT  = 3'b011;
    localparam RESET        = 3'b100;
    
    reg  [2:0] r_state;
    reg [10:0] r_clk_count;
    reg  [2:0] r_bit_index;
    reg  [7:0] r_data_byte;
    reg        r_tx_enable;
    
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            r_state     <= IDLE;
            r_clk_count <= 11'd0;
            r_bit_index <= 3'd0;
            r_data_byte <= 8'd0;
            o_tx_done   <= 1'b0;
            r_tx_enable <= 1'b0;
            o_tx_serial <= 1'b1;
        end 
        else begin
            case (r_state)
                IDLE: begin
                    o_tx_serial <= 1'b1;
                    o_tx_done   <= 1'b0;
                    r_clk_count <= 11'd0;
                    r_bit_index <= 3'd0;
                    if (i_start) begin
                        r_tx_enable <= 1'b1;
                        r_data_byte <= i_Byte_To_Send;
                        r_state     <= TX_START_BIT;
                    end 
                    else begin
                        r_state <= IDLE;
                    end
                end
                TX_START_BIT: begin
                    o_tx_serial <= 1'b0;
                    if (r_clk_count < (BAUD_RATE-1)) begin
                        r_clk_count <= r_clk_count + 1'b1;
                        r_state     <= TX_START_BIT;
                    end 
                    else begin
                        r_clk_count <= 11'd0;
                        r_state     <= TX_DATA_BITS;
                    end
                end
                TX_DATA_BITS: begin
                    o_tx_serial <= r_data_byte[r_bit_index];
                    if (r_clk_count < (BAUD_RATE-1)) begin
                        r_clk_count <= r_clk_count + 1'b1;
                        r_state     <= TX_DATA_BITS;
                    end 
                    else begin
                        r_clk_count <= 11'd0;
                        if (r_bit_index == 3'b111) begin
                            r_bit_index <= 3'd0;
                            r_state     <= TX_STOP_BIT;
                        end 
                        else begin
                            r_bit_index <= r_bit_index + 1'b1;
                            r_state     <= TX_DATA_BITS;
                        end
                    end
                end
                TX_STOP_BIT: begin
                    o_tx_serial <= 1'b1;
                    if (r_clk_count < (BAUD_RATE-1)) begin
                        r_clk_count <= r_clk_count + 1'b1;
                        r_state     <= TX_STOP_BIT;
                    end 
                    else begin
                        o_tx_done <= 1'b1;
                        r_clk_count <= 11'd0;
                        r_state     <= RESET;
                        r_tx_enable <= 1'b0;
                    end
                end
                RESET: begin
                    o_tx_done <= 1'b0;
                    r_state   <= IDLE;
                end
                default: r_state <= IDLE;
            endcase
        end
    end

    assign o_tx_active = r_tx_enable;
endmodule