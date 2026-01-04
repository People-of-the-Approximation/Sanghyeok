module uart_softmax64_top (
    input clk,
    input rst_n,
    input rxd,
    output txd
);

    wire rst = ~rst_n;

    wire block_ready;
    wire [7:0] byte_count;
    wire overrun;

    reg consume;
    reg [7:0] rd_addr;
    wire [7:0] rd_data;

    uart_block_rx #(.BLOCK_SIZE(129)) u_buf (
        .clk(clk),
        .rst(rst),
        .rxd(rxd),
        .consume(consume),

        .block_ready(block_ready),
        .byte_count(byte_count),
        .overrun(overrun),

        .rd_addr(rd_addr),
        .rd_data(rd_data)
    );

    localparam integer N = 64;

    reg sm_valid_in;
    wire sm_valid_out;
    reg [N*16-1:0] in_x_flat_reg;
    wire [N*16-1:0] prob_flat_wire;

    reg [7:0] payload_len;
    reg [1:0] length_mode_reg;

    softmax_approx u_softmax (
        .clk(clk),
        .en(1'b1),
        .rst(rst),
        .length_mode(length_mode_reg),
        .valid_in(sm_valid_in),
        .in_x_flat(in_x_flat_reg),
        .valid_out(sm_valid_out),
        .prob_flat(prob_flat_wire)
    );

    wire tx_active;
    wire tx_done;
    reg tx_start;
    reg [7:0] tx_byte;

    uart_tx u_tx (
        .clk(clk),
        .rst(rst),
        .start(tx_start),
        .Byte_To_Send(tx_byte),
        .Tx_Active(tx_active),
        .Tx_Serial(txd),
        .Tx_Done(tx_done)
    );

    localparam integer WORDS = 64;
    localparam integer OUT_BYTES = 128;

    localparam [3:0] S_WAIT_BLK = 4'd0;
    localparam [3:0] S_PREP_ALL = 4'd1;
    localparam [3:0] S_RD_LEN = 4'd2;
    localparam [3:0] S_RD_LO = 4'd3;
    localparam [3:0] S_RD_HI = 4'd4;
    localparam [3:0] S_SM_PULSE = 4'd5;
    localparam [3:0] S_SM_WAIT = 4'd6;
    localparam [3:0] S_LATCH_OUT = 4'd7;
    localparam [3:0] S_TX_BYTES = 4'd8;
    localparam [3:0] S_CONSUME = 4'd9;
    localparam [3:0] S_WAIT_CLR = 4'd10;

    reg [3:0] state;

    reg [5:0] widx;
    reg [7:0] tx_byte_idx;
    reg [7:0] base_addr;
    reg [7:0] lo_byte;
    reg wait_tx_done;

    reg [15:0] y_word [0:N-1];

    integer i;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_WAIT_BLK;
            widx <= 6'd0;
            tx_byte_idx <= 8'd0;
            base_addr <= 8'd0;
            lo_byte <= 8'd0;
            rd_addr <= 8'd0;
            in_x_flat_reg <= {N*16{1'b0}};
            sm_valid_in <= 1'b0;
            for (i=0; i<N; i=i+1)begin
                y_word[i] <= 16'd0;
            end
            tx_start <= 1'b0;
            tx_byte <= 8'd0;
            wait_tx_done <= 1'b0;
            consume <= 1'b0;
            payload_len <= 8'd64;
            length_mode_reg <= 2'd2;
        end 
        else begin
            sm_valid_in <= 1'b0;
            tx_start <= 1'b0;
            consume <= 1'b0;
            case (state)
                S_WAIT_BLK: begin
                    if (block_ready) state <= S_PREP_ALL;
                end
                S_PREP_ALL: begin
                    widx <= 6'd0;
                    base_addr <= 8'd1;
                    rd_addr <= 8'd0;
                    state <= S_RD_LEN;
                end
                S_RD_LEN: begin
                    payload_len <= rd_data;
                    if (rd_data == 8'd0 || rd_data > 8'd64) begin
                        length_mode_reg <= 2'd2;
                    end
                    else if (rd_data <= 8'd16) begin
                        length_mode_reg <= 2'd0;
                    end 
                    else if (rd_data <= 8'd32) begin
                        length_mode_reg <= 2'd1;
                    end
                    else begin
                        length_mode_reg <= 2'd2;
                    end
                    rd_addr <= base_addr;
                    state <= S_RD_LO;
                end
                S_RD_LO: begin
                    lo_byte <= rd_data;
                    rd_addr <= base_addr + 8'd1;
                    state <= S_RD_HI;
                end
                S_RD_HI: begin
                    in_x_flat_reg[16*widx +: 16] <= {rd_data, lo_byte};
                    if (widx == (WORDS-1)) begin
                        state <= S_SM_PULSE;
                    end 
                    else begin
                        widx <= widx + 6'd1;
                        base_addr <= base_addr + 8'd2;
                        rd_addr <= base_addr + 8'd2;
                        state <= S_RD_LO;
                    end
                end
                S_SM_PULSE: begin
                    sm_valid_in <= 1'b1;
                    state <= S_SM_WAIT;
                end
                S_SM_WAIT: begin
                    if (sm_valid_out) begin
                        state <= S_LATCH_OUT;
                    end
                end
                S_LATCH_OUT: begin
                    for (i=0; i<N; i=i+1) begin
                        y_word[i] <= prob_flat_wire[16*i +: 16];
                    end
                    tx_byte_idx <= 8'd0;
                    wait_tx_done <= 1'b0;
                    state <= S_TX_BYTES;
                end
                S_TX_BYTES: begin
                    if (!wait_tx_done) begin
                        if (!tx_active) begin
                            tx_byte <= (tx_byte_idx[0] == 1'b0)
                                ? y_word[tx_byte_idx[7:1]][7:0]
                                : y_word[tx_byte_idx[7:1]][15:8];
                            tx_start <= 1'b1;
                            wait_tx_done <= 1'b1;
                        end
                    end 
                    else begin
                        if (tx_done) begin
                            wait_tx_done <= 1'b0;
                            if (tx_byte_idx == (OUT_BYTES-1)) begin
                                state <= S_CONSUME;
                            end 
                            else begin
                                tx_byte_idx <= tx_byte_idx + 8'd1;
                            end
                        end
                    end
                end
                S_CONSUME: begin
                    consume <= 1'b1;
                    state <= S_WAIT_CLR;
                end
                S_WAIT_CLR: begin
                    if (!block_ready) begin
                        state <= S_WAIT_BLK;
                    end
                end
                default: state <= S_WAIT_BLK;
            endcase
        end
    end
endmodule
