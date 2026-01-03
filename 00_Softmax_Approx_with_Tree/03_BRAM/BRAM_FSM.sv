module BRAM_FSM(
    // Operation control signals
    input  wire          i_clk,
    input  wire          i_en,
    input  wire          i_rst,

    // Start Pulse
    input  wire          i_start,
    // Busy Signal
    output reg           o_busy,

    // BRAM Interface
    // Port A: Write Only
    output reg           o_cena,   // Chip Enable
    output reg           o_wea,    // Write Enable
    output reg     [4:0] o_addra,  // Address
    output wire [1027:0] o_dina,   // Data Input (Result to BRAM)
    // Port B: Read Only
    output reg           o_cenb,   // Chip Enable
    output wire    [4:0] o_addrb,  // Address
    input  wire [1027:0] i_doutb,  // Data Output (Source from BRAM)

    // Softmax Interface (FSM -> Softmax)
    output wire   [4:0]  o_length_mode, // Mode bits
    output wire          o_valid,       // Start pulse
    output wire [1023:0] o_in_x_flat,   // Input features

    // Softmax Interface (Softmax -> FSM)
    input  wire          i_valid,    // Result valid from Softmax
    input  wire [1023:0] i_prob_flat // Computed result
);

    // State definitions
    // Read FSM States (Port B control)
    localparam S_R_IDLE  = 3'd0;
    localparam S_R_READ  = 3'd1; // Asserting addresses
    localparam S_R_DONE  = 3'd2; // Finished reading
    localparam S_R_WAIT  = 3'd4; // Waiting for Write FSM to finish

    // Write FSM States (Port A control)
    localparam S_W_IDLE  = 3'd0;
    localparam S_W_WAIT  = 3'd1; // Waiting for Softmax i_valid
    localparam S_W_WRITE = 3'd2; // Writing results to Port A
    localparam S_W_DONE  = 3'd3; // Finished writing

    // Internal Registers
    reg [2:0] r_read_state;
    reg [4:0] r_read_addr;
    reg [2:0] r_valid;

    assign o_valid       = r_valid[2];
    assign o_length_mode = i_doutb[1027:1024];
    assign o_in_x_flat   = i_doutb[1023:0];

    reg [2:0] r_write_state;
    reg [4:0] r_write_addr;
    reg [1023:0] r_dina_buffer;

    // Logic assignments
    assign o_addrb = r_read_addr;
    assign o_addra = r_write_addr;
    assign o_dina  = {4'b0000, r_dina_buffer}; // Combine mode + result


    // 1. Read FSM (Port B & Softmax Input)
    always @(posedge i_clk) begin
        if (i_rst) begin
            r_read_state  <= S_R_IDLE;
            r_read_addr   <= 5'd0;
            o_busy        <= 1'b0;
            o_cenb        <= 1'b0;
            r_valid       <= 3'b000;
        end 
        else if (i_en) begin
            r_valid[1] <= r_valid[0];
            r_valid[2] <= r_valid[1];
            case (r_read_state)
                S_R_IDLE: begin
                    if (i_start) begin
                        r_read_state <= S_R_READ;
                        r_read_addr  <= 5'd0;
                        o_cenb       <= 1'b1;
                        o_busy       <= 1'b1;
                        r_valid[0]   <= 1'b1;
                    end
                end
                S_R_READ: begin
                    if (r_read_addr == 5'd11) begin
                        r_read_state <= S_R_DONE;
                        r_read_addr  <= 5'd0;
                        r_valid[0]   <= 1'b0;
                    end 
                    else begin
                        r_read_addr  <= r_read_addr + 5'd1;
                    end
                end
                S_R_DONE: begin
                    o_cenb        <= 1'b0;
                    r_read_state  <= S_R_WAIT;
                end
                S_R_WAIT: begin
                    if (r_write_state == S_W_DONE) begin
                        r_read_state <= S_R_IDLE;
                        o_busy       <= 1'b0;
                    end
                end
            endcase
        end
    end

    // 2. Write FSM (Port A & Softmax Output)
    always @(posedge i_clk) begin
        if (i_rst) begin
            r_write_state <= S_W_IDLE;
            r_write_addr  <= 5'd0;
            o_cena        <= 1'b0; // Inactive High
            o_wea         <= 1'b0;
            r_dina_buffer <= 1024'd0;
        end else if (i_en) begin
            r_dina_buffer <= i_prob_flat;
            case (r_write_state)
                S_W_IDLE: begin
                    // Start waiting when Read FSM begins processing
                    if (r_read_state == S_R_READ) begin
                        r_write_state <= S_W_WAIT;
                        r_write_addr  <= 5'd12; // Starting Write Address
                    end
                end
                S_W_WAIT: begin
                    // Wait for the first valid result from Softmax
                    if (i_valid) begin
                        r_write_state <= S_W_WRITE;
                        o_cena        <= 1'b1; // Activate BRAM Port A
                        o_wea         <= 1'b1; // Enable Write
                    end
                end
                S_W_WRITE: begin
                    if (r_write_addr == 5'd23) begin
                        r_write_state <= S_W_DONE;
                    end else begin
                        r_write_addr <= r_write_addr + 5'd1;
                    end
                end
                S_W_DONE: begin
                    o_cena        <= 1'b0;
                    o_wea         <= 1'b0;
                    r_write_state <= S_W_IDLE;
                    r_write_addr  <= 5'd12;
                end
                default: r_write_state <= S_W_IDLE;
            endcase
        end
    end
endmodule

module BRAM (
    // Operation signals
    input  wire          i_clk,

    // Data signals A (Write Port)
    input  wire          i_cena,
    input  wire          i_wea,
    input  wire    [4:0] i_addra,
    input  wire [1027:0] i_dina,

    // Data signals B (Read Port)
    input  wire          i_cenb,
    input  wire    [4:0] i_addrb,
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