module uart_block_rx #(
    parameter integer BLOCK_SIZE = 129,
    parameter integer ADDR_W = $clog2(BLOCK_SIZE)
)(
    input clk,
    input rst,
    input rxd,
    input consume,

    output reg block_ready,
    output reg [7:0] byte_count,
    output reg overrun,

    input [ADDR_W-1:0] rd_addr,
    output [7:0] rd_data
);
    reg [7:0] mem [0:BLOCK_SIZE-1];

    wire rx_done;
    wire [7:0] rx_byte;

    uart_rx u_rx (
        .clk(clk),
        .rst(rst),
        .Rx_Serial(rxd),
        .Rx_Done(rx_done),
        .Rx_Out(rx_byte)
    );

    assign rd_data = mem[rd_addr];
    reg [ADDR_W-1:0] wr_ptr;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= {ADDR_W{1'b0}};
            block_ready <= 1'b0;
            byte_count <= 8'd0;
            overrun <= 1'b0;
        end 
        else begin
            if (consume) begin
                wr_ptr <= {ADDR_W{1'b0}};
                block_ready <= 1'b0;
                byte_count <= 8'd0;
                overrun <= 1'b0;
            end
            if (rx_done) begin
                if (!block_ready) begin
                    mem[wr_ptr] <= rx_byte;
                    if (wr_ptr == BLOCK_SIZE-1) begin
                        block_ready <= 1'b1;
                        byte_count <= BLOCK_SIZE[7:0]; // 8'd129
                    end 
                    else begin
                        wr_ptr <= wr_ptr + 1'b1;
                        byte_count <= byte_count + 8'd1;
                    end
                end 
                else begin
                    overrun <= 1'b1;
                end
            end
        end
    end
endmodule
