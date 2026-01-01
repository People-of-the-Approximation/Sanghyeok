module acc_forwarding (
    input  wire           i_clk,
    input  wire           i_en,
    input  wire           i_rst,

    input  wire           i_valid_sum,
    input  wire    [15:0] i_loc_sum,
    input  wire     [3:0] i_length_mode,
    input  wire  [1023:0] i_in_flat,

    output wire           o_valid_sum,
    output wire    [15:0] o_global_sum,
    output wire     [3:0] o_length_mode_byp,
    output wire  [1023:0] o_in_byp,

    input  wire    [15:0] i_sum64_0,
    input  wire    [15:0] i_sum32_0, i_sum32_1,
    input  wire    [15:0] i_sum16_0, i_sum16_1, i_sum16_2, i_sum16_3,

    output wire    [15:0] o_sum64_0,
    output wire    [15:0] o_sum32_0, o_sum32_1,
    output wire    [15:0] o_sum16_0, o_sum16_1, o_sum16_2, o_sum16_3
);

    reg [11:0] r_valid_pip;
    reg [15:0] r_temp_pip   [0:11];
    reg [15:0] r_sum_shift  [0:11];
    reg [3:0]  r_length_byp [0:11];

    reg [3:0]  r_cnt;
    reg        r_acc_rst_loc;

    reg [11:0] r_load_mask;

wire [15:0] w_sum_front_s;
wire [15:0] w_sum_acc_s;

acc_add u_acc_add (
    .i_clk       (i_clk),
    .i_en        (i_en),
    .i_rst       (i_rst),
    .i_rst_loc   (r_acc_rst_loc),

    .i_valid     (i_valid_sum),
    .i_data      (i_loc_sum),

    .o_sum_front (w_sum_front_s),
    .o_sum_acc   (w_sum_acc_s)
);


    reg        w_is_group;
    reg  [3:0] w_length;
    wire       w_is_end;

    always @(*) begin
        case (i_length_mode)
            4'd0:    w_is_group = 1'b0;
            4'd1:    w_is_group = 1'b0;
            4'd2:    w_is_group = 1'b0;
            4'd3:    w_is_group = 1'b1;
            4'd4:    w_is_group = 1'b1;
            4'd5:    w_is_group = 1'b1;
            4'd6:    w_is_group = 1'b1;
            4'd7:    w_is_group = 1'b1;
            4'd8:    w_is_group = 1'b1;
            4'd9:    w_is_group = 1'b1;
            4'd10:   w_is_group = 1'b1;
            4'd11:   w_is_group = 1'b1;
            4'd12:   w_is_group = 1'b1;
            4'd13:   w_is_group = 1'b1;
            default: w_is_group = 1'b0;
        endcase
    end

    always @(*) begin
        case (i_length_mode)
            4'd0:    w_length = 4'd0;
            4'd1:    w_length = 4'd0;
            4'd2:    w_length = 4'd0;
            4'd3:    w_length = 4'd1;
            4'd4:    w_length = 4'd2;
            4'd5:    w_length = 4'd3;
            4'd6:    w_length = 4'd4;
            4'd7:    w_length = 4'd5;
            4'd8:    w_length = 4'd6;
            4'd9:    w_length = 4'd7;
            4'd10:   w_length = 4'd8;
            4'd11:   w_length = 4'd9;
            4'd12:   w_length = 4'd10;
            4'd13:   w_length = 4'd11;
            default: w_length = 4'd0;
        endcase
    end

    always @(*) begin
        case (i_length_mode)
            4'd0:    r_load_mask = 12'b000000000000;
            4'd1:    r_load_mask = 12'b000000000000;
            4'd2:    r_load_mask = 12'b000000000000;
            4'd3:    r_load_mask = 12'b000000000011;
            4'd4:    r_load_mask = 12'b000000000111;
            4'd5:    r_load_mask = 12'b000000001111;
            4'd6:    r_load_mask = 12'b000000011111;
            4'd7:    r_load_mask = 12'b000000111111;
            4'd8:    r_load_mask = 12'b000001111111;
            4'd9:    r_load_mask = 12'b000011111111;
            4'd10:   r_load_mask = 12'b000111111111;
            4'd11:   r_load_mask = 12'b001111111111;
            4'd12:   r_load_mask = 12'b011111111111;
            4'd13:   r_load_mask = 12'b111111111111;
            default: r_load_mask = 12'b000000000000;
        endcase
    end

    assign w_is_end = w_is_group & i_valid_sum & (r_cnt == w_length);

    always @(posedge i_clk) begin
        if (i_rst) begin
            r_cnt         <= 4'd0;
            r_acc_rst_loc <= 1'b0;
            for (integer k=0; k<12; k=k+1) begin
                r_sum_shift [k] <= 16'h0000;
            end
        end
        else if (i_en) begin
            if (w_is_end && r_load_mask[0]) begin
                r_sum_shift[0] <= w_sum_front_s;
            end
            else begin
                r_sum_shift[0] <= i_loc_sum;
            end
            for (integer k=1; k<12; k=k+1) begin
                if (w_is_end && r_load_mask[k]) begin
                    r_sum_shift[k] <= w_sum_front_s;
                end
                else begin
                    r_sum_shift[k] <= r_sum_shift[k-1];
                end
            end
            if (~i_valid_sum) begin
                r_cnt         <= 4'd0;
                r_acc_rst_loc <= 1'b0;
            end
            else if (w_is_end) begin
                r_cnt         <= 4'd0;
                r_acc_rst_loc <= 1'b1;
            end
            else begin
                if (w_is_group) begin
                    r_cnt <= r_cnt + 4'd1;
                    r_acc_rst_loc <= 1'b0;
                end 
                else begin
                    r_cnt <= 4'd0;
                    r_acc_rst_loc <= 1'b1;
                end
            end
        end
    end

    reg          r_valid_sum_pip   [0:11];
    reg [3:0]    r_length_mode_byp [0:11];
    reg [1023:0] r_in_flat_pip     [0:11];
    reg [15:0]   r_sum64_0_pip [0:11];
    reg [15:0]   r_sum32_0_pip [0:11], r_sum32_1_pip [0:11];
    reg [15:0]   r_sum16_0_pip [0:11], r_sum16_1_pip [0:11], r_sum16_2_pip [0:11], r_sum16_3_pip [0:11];

    always @(posedge i_clk) begin
        if (i_rst) begin
            for (integer k = 0; k <= 11; k = k + 1) begin
                r_valid_sum_pip  [k] <= 1'b0; 
                r_length_mode_byp[k] <= 4'b0;
                r_in_flat_pip    [k]   <= 1024'd0;
                r_sum64_0_pip    [k]   <= 16'd0;
                r_sum32_0_pip    [k]   <= 16'd0; r_sum32_1_pip    [k]   <= 16'd0;
                r_sum16_0_pip    [k]   <= 16'd0; r_sum16_1_pip    [k]   <= 16'd0;
                r_sum16_2_pip    [k]   <= 16'd0; r_sum16_3_pip    [k]   <= 16'd0;
            end
        end else if (i_en) begin
            r_valid_sum_pip[0] <= i_valid_sum;
            r_length_mode_byp[0] <= i_length_mode;
            r_in_flat_pip[0] <= i_in_flat;
            r_sum64_0_pip[0] <= i_sum64_0;
            r_sum32_0_pip[0] <= i_sum32_0; r_sum32_1_pip[0] <= i_sum32_1;
            r_sum16_0_pip[0] <= i_sum16_0; r_sum16_1_pip[0] <= i_sum16_1;
            r_sum16_2_pip[0] <= i_sum16_2; r_sum16_3_pip[0] <= i_sum16_3;
            for (integer k = 0; k <= 10; k = k + 1) begin
                r_valid_sum_pip[k+1]   <= r_valid_sum_pip[k];
                r_length_mode_byp[k+1] <= r_length_mode_byp[k];
                r_in_flat_pip[k+1]     <= r_in_flat_pip[k];
                r_sum64_0_pip[k+1]     <= r_sum64_0_pip[k];
                r_sum32_0_pip[k+1]     <= r_sum32_0_pip[k]; r_sum32_1_pip[k+1] <= r_sum32_1_pip[k];
                r_sum16_0_pip[k+1]     <= r_sum16_0_pip[k]; r_sum16_1_pip[k+1] <= r_sum16_1_pip[k];
                r_sum16_2_pip[k+1]     <= r_sum16_2_pip[k]; r_sum16_3_pip[k+1] <= r_sum16_3_pip[k];
            end
        end
    end

    assign o_valid_sum       = r_valid_sum_pip[11];
    assign o_global_sum      = r_sum_shift[11];
    assign o_length_mode_byp = r_length_mode_byp[11];
    assign o_in_byp          = r_in_flat_pip[11];

    assign o_sum64_0 = r_sum64_0_pip[11];
    assign o_sum32_0 = r_sum32_0_pip[11]; assign o_sum32_1 = r_sum32_1_pip[11];
    assign o_sum16_0 = r_sum16_0_pip[11]; assign o_sum16_1 = r_sum16_1_pip[11];
    assign o_sum16_2 = r_sum16_2_pip[11]; assign o_sum16_3 = r_sum16_3_pip[11];
endmodule

module acc_add (
    // Operation signals
    input  wire               i_clk,
    input  wire               i_en,

    // Reset signals
    input  wire               i_rst,       // Global reset
    input  wire               i_rst_loc,   // Local reset (group boundary)

    // Data inputs
    input  wire               i_valid,
    input  wire signed [15:0] i_data,

    // Data outputs
    output wire signed [15:0] o_sum_front, // combinational: acc + i_data
    output reg  signed [15:0] o_sum_acc    // registered accumulator
);

    // combinational "front" result
    assign o_sum_front = $signed(o_sum_acc) + $signed(i_data);

    always @(posedge i_clk) begin
        if (i_rst | i_rst_loc) begin
            o_sum_acc <= 16'd0;
        end
        else if (i_en & i_valid) begin
            o_sum_acc <= o_sum_front;
        end
    end
endmodule