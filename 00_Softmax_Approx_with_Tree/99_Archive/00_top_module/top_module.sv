module top_module(
    input wire i_clk,
    input wire i_rst
);
    // Busy Signal
    wire           o_busy;

    // BRAM Interface
    // Port A: Write Only
    wire           o_cena;   // Chip Enable
    wire           o_wea;    // Write Enable
    wire     [4:0] o_addra;  // Address
    wire  [1027:0] o_dina;   // Data Input (Result to BRAM)
    // Port B: Read Only
    wire           o_cenb;   // Chip Enable
    wire     [4:0] o_addrb;  // Address
    wire  [1027:0] i_doutb;  // Data Output (Source from BRAM)

    // Softmax Interface (FSM -> Softmax)
    wire     [3:0] o_length_mode; // Mode bits
    wire           o_valid;       // Start pulse
    wire  [1023:0] o_in_x_flat;   // Input features

    // Softmax Interface (Softmax -> FSM)
    wire          i_valid;    // Result valid from Softmax
    wire [1023:0] i_prob_flat; // Computed result

    reg i_en;
    reg i_start;
    reg test_state;
    
    localparam TEST_IDLE = 1'b0;
    localparam TEST_START= 1'b1;
    // Generate enable and start signals
    always @(posedge i_clk) begin
        if (i_rst) begin
            i_en    <= 1'b0;
            i_start <= 1'b0;
            test_state <= TEST_IDLE;
        end 
        else begin
            if (test_state == TEST_IDLE) begin
                i_en    <= 1'b1;
                i_start <= 1'b1;
                test_state <= TEST_START;
            end 
            else begin
                i_en    <= 1'b1;
                i_start <= 1'b0;
            end
        end
    end

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

    ILA_toptest ILA_inst (
        .clk(i_clk), // input wire clk
        .probe0(i_clk), // input wire [0:0]  probe0  
        .probe1(i_rst), // input wire [0:0]  probe1 
        .probe2(o_busy), // input wire [0:0]  probe2 
        .probe3(o_cena), // input wire [0:0]  probe3 
        .probe4(o_wea), // input wire [0:0]  probe4 
        .probe5(o_addra), // input wire [4:0]  probe5 
        .probe6(o_dina), // input wire [1027:0]  probe6 
        .probe7(o_cenb), // input wire [0:0]  probe7 
        .probe8(o_addrb), // input wire [4:0]  probe8 
        .probe9(i_doutb), // input wire [1027:0]  probe9 
        .probe10(o_length_mode), // input wire [3:0]  probe10 
        .probe11(o_valid), // input wire [0:0]  probe11 
        .probe12(o_in_x_flat), // input wire [1023:0]  probe12 
        .probe13(i_valid), // input wire [0:0]  probe13 
        .probe14(i_prob_flat), // input wire [1023:0]  probe14 
        .probe15(i_en), // input wire [0:0]  probe15 
        .probe16(i_start), // input wire [0:0]  probe16 
        .probe17(test_state) // input wire [0:0]  probe17
    );
    
endmodule