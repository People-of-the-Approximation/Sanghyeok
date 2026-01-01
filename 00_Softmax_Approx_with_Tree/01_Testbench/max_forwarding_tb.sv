`timescale 1ns/1ps

module max_forwarding_tb;

    // ----------------------------
    // clk/en/rst
    // ----------------------------
    reg clk;
    reg en;
    reg rst;

    // ----------------------------
    // DUT inputs
    // ----------------------------
    reg         i_valid_max;
    reg [15:0]  i_loc_max;
    reg [3:0]   i_length_mode;
    reg [1023:0] i_in_flat;

    reg [15:0]  i_max64_0;
    reg [15:0]  i_max32_0, i_max32_1;
    reg [15:0]  i_max16_0, i_max16_1, i_max16_2, i_max16_3;

    // ----------------------------
    // DUT outputs
    // ----------------------------
    wire         o_valid_max;
    wire [15:0]  o_global_max;
    wire [3:0]   o_length_mode_byp;
    wire [1023:0] o_in_byp;

    wire [15:0] o_max64_0;
    wire [15:0] o_max32_0, o_max32_1;
    wire [15:0] o_max16_0, o_max16_1, o_max16_2, o_max16_3;

    // ----------------------------
    // Instantiate DUT
    // ----------------------------
    max_forwarding dut (
        .i_clk(clk),
        .i_en(en),
        .i_rst(rst),

        .i_valid_max(i_valid_max),
        .i_loc_max(i_loc_max),
        .i_length_mode(i_length_mode),
        .i_in_flat(i_in_flat),

        .o_valid_max(o_valid_max),
        .o_global_max(o_global_max),
        .o_length_mode_byp(o_length_mode_byp),
        .o_in_byp(o_in_byp),

        .i_max64_0(i_max64_0),
        .i_max32_0(i_max32_0), .i_max32_1(i_max32_1),
        .i_max16_0(i_max16_0), .i_max16_1(i_max16_1), .i_max16_2(i_max16_2), .i_max16_3(i_max16_3),

        .o_max64_0(o_max64_0),
        .o_max32_0(o_max32_0), .o_max32_1(o_max32_1),
        .o_max16_0(o_max16_0), .o_max16_1(o_max16_1), .o_max16_2(o_max16_2), .o_max16_3(o_max16_3)
    );

    // ----------------------------
    // clock gen
    // ----------------------------
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // ============================================================
    // Reference model (TB 안에서 DUT 로직 그대로 따라감)
    // ============================================================

    reg [3:0]  exp_cnt;
    reg        exp_acc_rst_loc;
    reg [15:0] exp_max_shift [0:11];

    // acc_max reference (DUT acc_max 그대로)
    reg  signed [15:0] exp_max_acc;
    wire signed [15:0] exp_loc_s   = $signed(i_loc_max);
    wire signed [15:0] exp_max_front = (exp_max_acc > exp_loc_s) ? exp_max_acc : exp_loc_s;

    // bypass reference pipelines (DUT 12-stage)
    reg          exp_valid_pip [0:11];
    reg [3:0]    exp_len_pip   [0:11];
    reg [1023:0] exp_in_pip    [0:11];

    reg [15:0] exp_max64_0_pip [0:11];
    reg [15:0] exp_max32_0_pip [0:11], exp_max32_1_pip [0:11];
    reg [15:0] exp_max16_0_pip [0:11], exp_max16_1_pip [0:11], exp_max16_2_pip [0:11], exp_max16_3_pip [0:11];

    // comb decode (DUT와 동일)
    reg  exp_is_group;
    reg  [3:0] exp_w_length;
    reg  [11:0] exp_mask;
    wire exp_is_end = exp_is_group & i_valid_max & (exp_cnt == exp_w_length);

    integer k;

    always @(*) begin
        // is_group
        case (i_length_mode)
            4'd3,4'd4,4'd5,4'd6,4'd7,4'd8,4'd9,4'd10,4'd11,4'd12,4'd13: exp_is_group = 1'b1;
            default: exp_is_group = 1'b0;
        endcase
    end

    always @(*) begin
        // w_length = length_mode - 2  (3->1, ..., 13->11)
        case (i_length_mode)
            4'd3: exp_w_length = 4'd1;
            4'd4: exp_w_length = 4'd2;
            4'd5: exp_w_length = 4'd3;
            4'd6: exp_w_length = 4'd4;
            4'd7: exp_w_length = 4'd5;
            4'd8: exp_w_length = 4'd6;
            4'd9: exp_w_length = 4'd7;
            4'd10: exp_w_length = 4'd8;
            4'd11: exp_w_length = 4'd9;
            4'd12: exp_w_length = 4'd10;
            4'd13: exp_w_length = 4'd11;
            default: exp_w_length = 4'd0;
        endcase
    end

    always @(*) begin
        // mask
        case (i_length_mode)
            4'd3:  exp_mask = 12'b000000000011;
            4'd4:  exp_mask = 12'b000000000111;
            4'd5:  exp_mask = 12'b000000001111;
            4'd6:  exp_mask = 12'b000000011111;
            4'd7:  exp_mask = 12'b000000111111;
            4'd8:  exp_mask = 12'b000001111111;
            4'd9:  exp_mask = 12'b000011111111;
            4'd10: exp_mask = 12'b000111111111;
            4'd11: exp_mask = 12'b001111111111;
            4'd12: exp_mask = 12'b011111111111;
            4'd13: exp_mask = 12'b111111111111;
            default: exp_mask = 12'b000000000000;
        endcase
    end

    // reference sequential update
    always @(posedge clk) begin
        if (rst) begin
            exp_cnt         <= 4'd0;
            exp_acc_rst_loc <= 1'b0;
            exp_max_acc     <= $signed(16'h8000);

            for (k=0; k<12; k=k+1) begin
                exp_max_shift[k] <= 16'h8000;

                exp_valid_pip[k] <= 1'b0;
                exp_len_pip[k]   <= 4'd0;
                exp_in_pip[k]    <= 1024'd0;

                exp_max64_0_pip[k] <= 16'd0;
                exp_max32_0_pip[k] <= 16'd0; exp_max32_1_pip[k] <= 16'd0;
                exp_max16_0_pip[k] <= 16'd0; exp_max16_1_pip[k] <= 16'd0;
                exp_max16_2_pip[k] <= 16'd0; exp_max16_3_pip[k] <= 16'd0;
            end
        end
        else if (en) begin
            // ---- acc_max reference (DUT acc_max와 동일: i_rst_loc면 무조건 -inf로 리셋) ----
            if (exp_acc_rst_loc) begin
                exp_max_acc <= $signed(16'h8000);
            end
            else if (i_valid_max) begin
                exp_max_acc <= exp_max_front;
            end

            // ---- max forwarding shift reference ----
            if (exp_is_end && exp_mask[0])
                exp_max_shift[0] <= exp_max_front[15:0];
            else
                exp_max_shift[0] <= i_loc_max;

            for (k=1; k<12; k=k+1) begin
                if (exp_is_end && exp_mask[k])
                    exp_max_shift[k] <= exp_max_front[15:0];
                else
                    exp_max_shift[k] <= exp_max_shift[k-1];
            end

            // ---- cnt / local reset reference ----
            if (!i_valid_max) begin
                exp_cnt         <= 4'd0;
                exp_acc_rst_loc <= 1'b0;
            end
            else if (exp_is_end) begin
                exp_cnt         <= 4'd0;
                exp_acc_rst_loc <= 1'b1;
            end
            else begin
                if (exp_is_group) exp_cnt <= exp_cnt + 4'd1;
                else              exp_cnt <= 4'd0;
                exp_acc_rst_loc <= 1'b0;
            end

            // ---- bypass pipeline reference (DUT와 동일 12-stage) ----
            exp_valid_pip[0] <= i_valid_max;
            exp_len_pip[0]   <= i_length_mode;
            exp_in_pip[0]    <= i_in_flat;

            exp_max64_0_pip[0] <= i_max64_0;
            exp_max32_0_pip[0] <= i_max32_0; exp_max32_1_pip[0] <= i_max32_1;
            exp_max16_0_pip[0] <= i_max16_0; exp_max16_1_pip[0] <= i_max16_1;
            exp_max16_2_pip[0] <= i_max16_2; exp_max16_3_pip[0] <= i_max16_3;

            for (k=0; k<11; k=k+1) begin
                exp_valid_pip[k+1] <= exp_valid_pip[k];
                exp_len_pip[k+1]   <= exp_len_pip[k];
                exp_in_pip[k+1]    <= exp_in_pip[k];

                exp_max64_0_pip[k+1] <= exp_max64_0_pip[k];
                exp_max32_0_pip[k+1] <= exp_max32_0_pip[k];
                exp_max32_1_pip[k+1] <= exp_max32_1_pip[k];

                exp_max16_0_pip[k+1] <= exp_max16_0_pip[k];
                exp_max16_1_pip[k+1] <= exp_max16_1_pip[k];
                exp_max16_2_pip[k+1] <= exp_max16_2_pip[k];
                exp_max16_3_pip[k+1] <= exp_max16_3_pip[k];
            end
        end
    end

    // ============================================================
    // Checker
    // ============================================================
    integer err;
    initial err = 0;

    always @(posedge clk) begin
        if (!rst && en) begin
            #1; // DUT/REF NB update 이후 비교

            if (o_valid_max !== exp_valid_pip[11]) begin
                $display("[ERR] t=%0t valid mismatch: got=%b exp=%b", $time, o_valid_max, exp_valid_pip[11]);
                err = err + 1;
            end

            if (o_length_mode_byp !== exp_len_pip[11]) begin
                $display("[ERR] t=%0t len mismatch: got=%0d exp=%0d", $time, o_length_mode_byp, exp_len_pip[11]);
                err = err + 1;
            end

            if (o_in_byp !== exp_in_pip[11]) begin
                $display("[ERR] t=%0t in_flat mismatch", $time);
                err = err + 1;
            end

            if (o_global_max !== exp_max_shift[11]) begin
                $display("[ERR] t=%0t global_max mismatch: got=%0d(0x%04h) exp=%0d(0x%04h) | len_in=%0d",
                         $time, $signed(o_global_max), o_global_max, $signed(exp_max_shift[11]), exp_max_shift[11], i_length_mode);
                err = err + 1;
            end

            // max tree bypass check
            if (o_max64_0 !== exp_max64_0_pip[11]) begin $display("[ERR] t=%0t max64_0 mismatch", $time); err=err+1; end
            if (o_max32_0 !== exp_max32_0_pip[11]) begin $display("[ERR] t=%0t max32_0 mismatch", $time); err=err+1; end
            if (o_max32_1 !== exp_max32_1_pip[11]) begin $display("[ERR] t=%0t max32_1 mismatch", $time); err=err+1; end
            if (o_max16_0 !== exp_max16_0_pip[11]) begin $display("[ERR] t=%0t max16_0 mismatch", $time); err=err+1; end
            if (o_max16_1 !== exp_max16_1_pip[11]) begin $display("[ERR] t=%0t max16_1 mismatch", $time); err=err+1; end
            if (o_max16_2 !== exp_max16_2_pip[11]) begin $display("[ERR] t=%0t max16_2 mismatch", $time); err=err+1; end
            if (o_max16_3 !== exp_max16_3_pip[11]) begin $display("[ERR] t=%0t max16_3 mismatch", $time); err=err+1; end

            if (o_valid_max) begin
                $display("[OUT] t=%0t | len=%0d | global_max=%0d | max64=%0d",
                         $time, o_length_mode_byp, $signed(o_global_max), $signed(o_max64_0));
            end
        end
    end

    // ============================================================
    // Stimulus (규칙 준수)
    // ============================================================
    task drive_cycle;
        input        v;
        input [3:0]  lm;
        input [15:0] loc;
        input [15:0] tag;
        begin
            @(negedge clk);
            i_valid_max   <= v;
            i_length_mode <= lm;
            i_loc_max     <= loc;

            // i_in_flat: 16-bit tag를 64번 반복
            i_in_flat     <= {64{tag}};

            // tree max 입력들도 tag 기반으로 의미 있게 변화
            i_max64_0 <= tag + 16'd100;
            i_max32_0 <= tag + 16'd200;
            i_max32_1 <= tag + 16'd201;
            i_max16_0 <= tag + 16'd300;
            i_max16_1 <= tag + 16'd301;
            i_max16_2 <= tag + 16'd302;
            i_max16_3 <= tag + 16'd303;
        end
    endtask

    task run_group;
        input [3:0] lm;
        integer n, idx;
        reg [15:0] base;
        reg [15:0] loc;
        reg [15:0] tag;
        begin
            // 규칙:
            // lm=3..13 => valid 샘플 수 n = lm-1 (마지막 index = lm-2)
            // lm=0..2  => forwarding 없음, shift만 확인용으로 4샘플 넣음
            if (lm >= 4'd3 && lm <= 4'd13) n = lm - 1;
            else n = 4;

            base = 16'd1000 + (lm * 16'd50);

            $display("\n==== RUN length_mode=%0d | n_valid=%0d ====", lm, n);

            for (idx=0; idx<n; idx=idx+1) begin
                // global max가 확실히 마지막 샘플에서 나오게(= end cycle에서 포함되게)
                if (lm >= 4'd3 && lm <= 4'd13 && idx == (n-1))
                    loc = base + 16'd999;  // MAX at last sample (index lm-2)
                else
                    loc = base + idx;

                tag = {12'hA00, lm} + idx;  // 눈에 보이는 tag
                drive_cycle(1'b1, lm, loc, tag);
            end

            // 그룹 사이 규칙: 1클럭 bubble 넣어서 acc_rst_loc가 데이터랑 겹치지 않게 함
            drive_cycle(1'b0, 4'd0, 16'd0, 16'h0000);
        end
    endtask

    integer lm;
    initial begin
        // init
        en  = 1'b1;
        rst = 1'b1;

        i_valid_max   = 1'b0;
        i_loc_max     = 16'd0;
        i_length_mode = 4'd0;
        i_in_flat     = 1024'd0;

        i_max64_0 = 16'd0;
        i_max32_0 = 16'd0; i_max32_1 = 16'd0;
        i_max16_0 = 16'd0; i_max16_1 = 16'd0; i_max16_2 = 16'd0; i_max16_3 = 16'd0;

        // reset
        repeat (5) @(posedge clk);
        rst = 1'b0;

        // 0~13 전부 돌림 (0/1/2는 shift-only 확인)
        for (lm=0; lm<=13; lm=lm+1) begin
            run_group(lm[3:0]);
        end

        // flush
        repeat (50) @(posedge clk);

        if (err == 0) $display("\n===== PASS (no mismatch) =====");
        else          $display("\n===== FAIL (err=%0d) =====", err);

        $finish;
    end

    initial begin
        $dumpfile("max_forwarding_tb.vcd");
        $dumpvars(0, max_forwarding_tb);
    end

endmodule