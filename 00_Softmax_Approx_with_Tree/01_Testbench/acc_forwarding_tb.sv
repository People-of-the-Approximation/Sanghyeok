`timescale 1ns/1ps

module acc_forwarding_tb;

    // ----------------------------
    // clk/en/rst
    // ----------------------------
    reg clk;
    reg en;
    reg rst;

    // ----------------------------
    // DUT inputs
    // ----------------------------
    reg         i_valid_sum;          // ★ MOD
    reg [15:0]  i_loc_sum;            // ★ MOD
    reg [3:0]   i_length_mode;
    reg [1023:0] i_in_flat;

    reg [15:0]  i_sum64_0;
    reg [15:0]  i_sum32_0, i_sum32_1;
    reg [15:0]  i_sum16_0, i_sum16_1, i_sum16_2, i_sum16_3;

    // ----------------------------
    // DUT outputs
    // ----------------------------
    wire         o_valid_sum;          // ★ MOD
    wire [15:0]  o_global_sum;         // ★ MOD
    wire [3:0]   o_length_mode_byp;
    wire [1023:0] o_in_byp;

    wire [15:0] o_sum64_0;
    wire [15:0] o_sum32_0, o_sum32_1;
    wire [15:0] o_sum16_0, o_sum16_1, o_sum16_2, o_sum16_3;

    // ----------------------------
    // Instantiate DUT
    // ----------------------------
    acc_forwarding dut (              // ★ MOD
        .i_clk(clk),
        .i_en(en),
        .i_rst(rst),

        .i_valid_sum(i_valid_sum),
        .i_loc_sum(i_loc_sum),
        .i_length_mode(i_length_mode),
        .i_in_flat(i_in_flat),

        .o_valid_sum(o_valid_sum),
        .o_global_sum(o_global_sum),
        .o_length_mode_byp(o_length_mode_byp),
        .o_in_byp(o_in_byp),

        .i_sum64_0(i_sum64_0),
        .i_sum32_0(i_sum32_0), .i_sum32_1(i_sum32_1),
        .i_sum16_0(i_sum16_0), .i_sum16_1(i_sum16_1),
        .i_sum16_2(i_sum16_2), .i_sum16_3(i_sum16_3),

        .o_sum64_0(o_sum64_0),
        .o_sum32_0(o_sum32_0), .o_sum32_1(o_sum32_1),
        .o_sum16_0(o_sum16_0), .o_sum16_1(o_sum16_1),
        .o_sum16_2(o_sum16_2), .o_sum16_3(o_sum16_3)
    );

    // ----------------------------
    // clock gen
    // ----------------------------
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // ============================================================
    // Reference model (acc_add 기반)
    // ============================================================

    reg [3:0]  exp_cnt;
    reg        exp_acc_rst_loc;
    reg signed [15:0] exp_sum_acc;
    wire signed [15:0] exp_sum_front = exp_sum_acc + $signed(i_loc_sum);

    reg signed [15:0] exp_sum_shift [0:11];

    reg          exp_valid_pip [0:11];
    reg [3:0]    exp_len_pip   [0:11];
    reg [1023:0] exp_in_pip    [0:11];

    reg [15:0] exp_sum64_0_pip [0:11];
    reg [15:0] exp_sum32_0_pip [0:11], exp_sum32_1_pip [0:11];
    reg [15:0] exp_sum16_0_pip [0:11], exp_sum16_1_pip [0:11];
    reg [15:0] exp_sum16_2_pip [0:11], exp_sum16_3_pip [0:11];

    reg exp_is_group;
    reg [3:0] exp_w_length;
    reg [11:0] exp_mask;
    wire exp_is_end = exp_is_group & i_valid_sum & (exp_cnt == exp_w_length);

    integer k;

    always @(*) begin
        exp_is_group = (i_length_mode >= 4'd3 && i_length_mode <= 4'd13);
        exp_w_length = exp_is_group ? (i_length_mode - 4'd2) : 4'd0;
        exp_mask     = exp_is_group ? (12'hFFF >> (13 - i_length_mode)) : 12'h000;
    end

    always @(posedge clk) begin
        if (rst) begin
            exp_cnt <= 0;
            exp_acc_rst_loc <= 0;
            exp_sum_acc <= 0;
            for (k=0; k<12; k=k+1) begin
                exp_sum_shift[k] <= 0;
                exp_valid_pip[k] <= 0;
                exp_len_pip[k] <= 0;
                exp_in_pip[k] <= 0;
                exp_sum64_0_pip[k] <= 0;
                exp_sum32_0_pip[k] <= 0; exp_sum32_1_pip[k] <= 0;
                exp_sum16_0_pip[k] <= 0; exp_sum16_1_pip[k] <= 0;
                exp_sum16_2_pip[k] <= 0; exp_sum16_3_pip[k] <= 0;
            end
        end
        else if (en) begin
            if (exp_acc_rst_loc)
                exp_sum_acc <= 0;
            else if (i_valid_sum)
                exp_sum_acc <= exp_sum_front;

            if (exp_is_end && exp_mask[0])
                exp_sum_shift[0] <= exp_sum_front;
            else
                exp_sum_shift[0] <= i_loc_sum;

            for (k=1; k<12; k=k+1)
                exp_sum_shift[k] <= (exp_is_end && exp_mask[k]) ? exp_sum_front
                                                                : exp_sum_shift[k-1];

            if (!i_valid_sum) begin
                exp_cnt <= 0;
                exp_acc_rst_loc <= 0;
            end
            else if (exp_is_end) begin
                exp_cnt <= 0;
                exp_acc_rst_loc <= 1;
            end
            else begin
                exp_cnt <= exp_is_group ? exp_cnt + 1 : 0;
                exp_acc_rst_loc <= 0;
            end

            exp_valid_pip[0] <= i_valid_sum;
            exp_len_pip[0]   <= i_length_mode;
            exp_in_pip[0]    <= i_in_flat;

            exp_sum64_0_pip[0] <= i_sum64_0;
            exp_sum32_0_pip[0] <= i_sum32_0; exp_sum32_1_pip[0] <= i_sum32_1;
            exp_sum16_0_pip[0] <= i_sum16_0; exp_sum16_1_pip[0] <= i_sum16_1;
            exp_sum16_2_pip[0] <= i_sum16_2; exp_sum16_3_pip[0] <= i_sum16_3;

            for (k=0; k<11; k=k+1) begin
                exp_valid_pip[k+1] <= exp_valid_pip[k];
                exp_len_pip[k+1]   <= exp_len_pip[k];
                exp_in_pip[k+1]    <= exp_in_pip[k];
                exp_sum64_0_pip[k+1] <= exp_sum64_0_pip[k];
                exp_sum32_0_pip[k+1] <= exp_sum32_0_pip[k];
                exp_sum32_1_pip[k+1] <= exp_sum32_1_pip[k];
                exp_sum16_0_pip[k+1] <= exp_sum16_0_pip[k];
                exp_sum16_1_pip[k+1] <= exp_sum16_1_pip[k];
                exp_sum16_2_pip[k+1] <= exp_sum16_2_pip[k];
                exp_sum16_3_pip[k+1] <= exp_sum16_3_pip[k];
            end
        end
    end

    // ============================================================
    // Checker
    // ============================================================
    integer err = 0;
    always @(posedge clk) begin
        #1;
        if (!rst && en && o_valid_sum) begin
            if (o_global_sum !== exp_sum_shift[11]) begin
                $display("[ERR] t=%0t sum mismatch got=%0d exp=%0d",
                         $time, $signed(o_global_sum), $signed(exp_sum_shift[11]));
                err = err + 1;
            end
        end
    end

    // ============================================================
    // Stimulus
    // ============================================================
    task drive_cycle;
        input v;
        input [3:0] lm;
        input [15:0] loc;
        input [15:0] tag;
        begin
            @(negedge clk);
            i_valid_sum   <= v;
            i_length_mode <= lm;
            i_loc_sum     <= loc;
            i_in_flat     <= {64{tag}};
            i_sum64_0 <= tag;
            i_sum32_0 <= tag + 1; i_sum32_1 <= tag + 2;
            i_sum16_0 <= tag + 3; i_sum16_1 <= tag + 4;
            i_sum16_2 <= tag + 5; i_sum16_3 <= tag + 6;
        end
    endtask

    task run_group;
        input [3:0] lm;
        integer n, i;
        reg [15:0] loc;
        begin
            n = (lm >= 3) ? (lm - 1) : 4;
            for (i=0; i<n; i=i+1) begin
                loc = 16'd5 + i; // ★ small values (overflow safe)
                drive_cycle(1'b1, lm, loc, 16'h0100 + i);
            end
            drive_cycle(1'b0, 4'd0, 16'd0, 16'd0);
        end
    endtask

    integer lm;
    initial begin
        en = 1;
        rst = 1;
        i_valid_sum = 0;
        i_loc_sum = 0;
        i_length_mode = 0;
        i_in_flat = 0;

        repeat (5) @(posedge clk);
        rst = 0;

        for (lm=0; lm<=13; lm=lm+1)
            run_group(lm[3:0]);

        repeat (50) @(posedge clk);

        if (err == 0) $display("===== PASS =====");
        else $display("===== FAIL (%0d errors) =====", err);

        $finish;
    end

    initial begin
        $dumpfile("acc_forwarding_tb.vcd");
        $dumpvars(0, acc_forwarding_tb);
    end

endmodule