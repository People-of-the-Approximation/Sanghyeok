module max_forwarding (
    // Operation signals
    input  wire          i_clk,
    input  wire          i_en,
    // Reset signal (active high)
    input  wire          i_rst,

    input  wire          i_valid_max,
    input  wire   [15:0] i_glob_max,

    input  wire    [3:0] i_length_mode,
    input  wire [1023:0] i_in_flat,

    output wire          o_valid_max,
    output wire   [15:0] o_total_max,

    output wire    [3:0] o_length_mode_byp,
    output wire [1023:0] o_in_byp,

    // 64-mode max inputs
    output wire   [15:0] i_max64_0,
    // 32-mode max inputs
    output wire   [15:0] i_max32_0,
    output wire   [15:0] i_max32_1,
    // 16-mode max inputs
    output wire   [15:0] i_max16_0,
    output wire   [15:0] i_max16_1,
    output wire   [15:0] i_max16_2,
    output wire   [15:0] i_max16_3,

    // 64-mode max outputs
    output wire   [15:0] o_max64_0,
    // 32-mode max outputs
    output wire   [15:0] o_max32_0,
    output wire   [15:0] o_max32_1,
    // 16-mode max outputs
    output wire   [15:0] o_max16_0,
    output wire   [15:0] o_max16_1,
    output wire   [15:0] o_max16_2,
    output wire   [15:0] o_max16_3

);
    reg          r_valid_max_pip   [0:11];
    reg    [3:0] r_length_mode_byp [0:11];
    reg [1023:0] r_in_flat_pip     [0:11];

    reg   [15:0] r_max64_0_pip     [0:11];

    reg   [15:0] r_max32_0_pip     [0:11];
    reg   [15:0] r_max32_1_pip     [0:11];

    reg   [15:0] r_max16_0_pip     [0:11];
    reg   [15:0] r_max16_1_pip     [0:11];
    reg   [15:0] r_max16_2_pip     [0:11];
    reg   [15:0] r_max16_3_pip     [0:11];

    always @(posedge i_clk) begin
        if (i_rst) begin
            for (integer k = 0; k <= 11; k = k + 1) begin
                r_valid_max_pip   [k] <= 1'b0;
                r_length_mode_byp [k] <= 4'b0;
                r_in_flat_pip     [k] <= {64{16'd0}};
                r_max64_0_pip     [k] <= 16'd0;
                r_max32_0_pip     [k] <= 16'd0;
                r_max32_1_pip     [k] <= 16'd0;
                r_max16_0_pip     [k] <= 16'd0;
                r_max16_1_pip     [k] <= 16'd0;
                r_max16_2_pip     [k] <= 16'd0;
                r_max16_3_pip     [k] <= 16'd0;
            end
        end
        else if (i_en) begin
            r_valid_max_pip   [0] <= i_valid_max;
            r_length_mode_byp [0] <= i_length_mode;
            r_in_flat_pip     [0] <= i_in_flat;

            r_max64_0_pip     [0] <= i_max64_0;

            r_max32_0_pip     [0] <= i_max32_0;
            r_max32_1_pip     [0] <= i_max32_1;

            r_max16_0_pip     [0] <= i_max16_0;
            r_max16_1_pip     [0] <= i_max16_1;
            r_max16_2_pip     [0] <= i_max16_2;
            r_max16_3_pip     [0] <= i_max16_3;
            for (integer k = 0; k <= 10; k = k + 1) begin
                r_valid_max_pip   [k+1] <= r_valid_max_pip   [k];
                r_length_mode_byp [k+1] <= r_length_mode_byp [k];
                r_in_flat_pip     [k+1] <= r_in_flat_pip     [k];

                r_max64_0_pip     [k+1] <= r_max64_0_pip     [k];

                r_max32_0_pip     [k+1] <= r_max32_0_pip     [k];
                r_max32_1_pip     [k+1] <= r_max32_1_pip     [k];

                r_max16_0_pip     [k+1] <= r_max16_0_pip     [k];
                r_max16_1_pip     [k+1] <= r_max16_1_pip     [k];
                r_max16_2_pip     [k+1] <= r_max16_2_pip     [k];
                r_max16_3_pip     [k+1] <= r_max16_3_pip     [k];
            end
        end
    end

    reg   [15:0] r_total_max_shift [0:11];
    reg   [11:0] r_parallel_load;
    reg   [11:0] r_parallel_load_cnt;
    reg          r_acc_reset;
    reg    [3:0] r_acc_cnt;

    wire  [15:0] w_acc_max;
    reg   [15:0] r_acc_max;

    assign w_acc_max = $signed(r_acc_max) > $signed(i_glob_max) ? r_acc_max : i_glob_max;

    always @(*) begin
        case (i_length_mode)
            4'd0, 4'd1, 4'd2:  r_parallel_load_cnt = 12'b000000000000;
            4'd3:              r_parallel_load_cnt = 12'b000000000011;
            4'd4:              r_parallel_load_cnt = 12'b000000000111;
            4'd5:              r_parallel_load_cnt = 12'b000000001111;
            4'd6:              r_parallel_load_cnt = 12'b000000011111;
            4'd7:              r_parallel_load_cnt = 12'b000000111111;
            4'd8:              r_parallel_load_cnt = 12'b000001111111;
            4'd9:              r_parallel_load_cnt = 12'b000011111111;
            4'd10:             r_parallel_load_cnt = 12'b000111111111;
            4'd11:             r_parallel_load_cnt = 12'b001111111111;
            4'd12:             r_parallel_load_cnt = 12'b011111111111;
            4'd13:             r_parallel_load_cnt = 12'b111111111111;
            default:           r_parallel_load_cnt = 12'b000000000000;
        endcase
    end

    always @(posedge i_clk) begin
        if (i_rst) begin
            r_acc_max       <= 16'h8000;
            r_acc_cnt       <= 4'd0;
            r_parallel_load <= 12'd0;
            r_acc_reset     <= 1'b0;
        end
        if (r_acc_reset) begin
            r_acc_max       <= 16'h8000;
            r_acc_cnt       <= 4'd0;
            r_parallel_load <= 12'd0;
            r_acc_reset     <= 1'b0;
        end
        else if (r_acc_cnt == i_length_mode - 4'd2) begin
            r_acc_max       <= w_acc_max;
            r_parallel_load <= r_parallel_load_cnt;
            r_acc_cnt       <= r_acc_cnt + 4'd1;
            r_acc_reset     <= 1'b1;
        end
        else if (i_en) begin
            r_acc_max       <= w_acc_max;
            r_parallel_load <= 12'd0;
            r_acc_cnt       <= r_acc_cnt + 4'd1;
            r_acc_reset     <= 1'b0;
        end
    end

    always @(posedge i_clk) begin
        if (i_rst) begin
            for (integer k = 0; k <= 11; k = k + 1) begin
                r_total_max_shift[k] <= 16'h8000;
            end
        end
        else if (i_en) begin
            r_total_max_shift[0] <= r_parallel_load[0] ? w_acc_max : i_glob_max;
            for (integer k = 1; k <= 11; k = k + 1) begin
                if (r_parallel_load[k]) begin
                    r_total_max_shift[k] <= w_acc_max;
                end
                else begin
                    r_total_max_shift[k] <= r_total_max_shift[k-1];
                end
            end
        end
    end

    assign o_valid_max       = r_valid_max_pip[11];
    assign o_total_max       = r_total_max_shift[11];
    assign o_length_mode_byp = r_length_mode_byp[11];
    assign o_in_byp          = r_in_flat_pip[11];

    assign o_max64_0 = r_max64_0_pip[11];

    assign o_max32_0 = r_max32_0_pip[11]; 
    assign o_max32_1 = r_max32_1_pip[11];

    assign o_max16_0 = r_max16_0_pip[11]; 
    assign o_max16_1 = r_max16_1_pip[11];
    assign o_max16_2 = r_max16_2_pip[11]; 
    assign o_max16_3 = r_max16_3_pip[11];
endmodule

module acc_max(
    // Operation signals
    input  wire               i_clk,
    input  wire               i_en,
    // Reset signal (active high, Global Reset)
    input  wire               i_rst,
    // Reset signal (active high, Local Reset)
    input  wire               i_rst_loc,

    // Data inputs
    input  wire               i_valid_max,
    input  wire signed [15:0] i_loc_max,

    // Data outputs
    output wire signed [15:0] o_max_front,
    output reg  signed [15:0] o_max_acc
);
    assign o_max_front = ($signed(o_max_acc) > $signed(i_loc_max)) ? o_max_acc : i_loc_max;

    always @(posedge i_clk) begin
        if (i_rst | i_rst_loc) begin
            o_max_acc <= $signed(16'h8000);
        end
        else if (i_en & i_valid_max) begin
            o_max_acc <= o_max_front;
        end
    end
endmodule