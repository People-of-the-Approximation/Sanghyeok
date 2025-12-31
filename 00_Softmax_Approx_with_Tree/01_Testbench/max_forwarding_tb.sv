/*
`timescale 1ns/1ps

module max_forwarding_tb;

    // --- 신호 정의 ---
    reg         i_clk;
    reg         i_en;
    reg         i_rst;
    reg         i_valid_max;
    reg  [15:0] i_glob_max;
    reg  [3:0]  i_length_mode;
    reg [1023:0] i_in_flat;

    // Sub-max 입력들 (테스트용)
    reg  [15:0] i_max64_0, i_max32_0, i_max32_1;
    reg  [15:0] i_max16_0, i_max16_1, i_max16_2, i_max16_3;

    wire        o_valid_max;
    wire [15:0] o_total_max;
    wire [3:0]  o_length_mode_byp;
    wire [1023:0] o_in_byp;

    // --- 클럭 생성 (100MHz) ---
    initial i_clk = 0;
    always #5 i_clk = ~i_clk;

    // --- DUT 인스턴스화 ---
    max_forwarding DUT (
        .i_clk(i_clk), .i_en(i_en), .i_rst(i_rst),
        .i_valid_max(i_valid_max), .i_glob_max(i_glob_max),
        .i_length_mode(i_length_mode), .i_in_flat(i_in_flat),
        .o_valid_max(o_valid_max), .o_total_max(o_total_max),
        .o_length_mode_byp(o_length_mode_byp), .o_in_byp(o_in_byp),
        .i_max64_0(i_max64_0), .i_max32_0(i_max32_0), .i_max32_1(i_max32_1),
        .i_max16_0(i_max16_0), .i_max16_1(i_max16_1), .i_max16_2(i_max16_2), .i_max16_3(i_max16_3),
        .o_max64_0(), .o_max32_0(), .o_max32_1(),
        .o_max16_0(), .o_max16_1(), .o_max16_2(), .o_max16_3()
    );

    // --- [핵심] 연속 주입 태스크 (Gap-less Streaming) ---
    task send_stream_group;
        input [3:0] mode;      // i_length_mode
        input [15:0] base_val; // 데이터 식별용 시작값
        integer i, num_rows;
        begin
            // 사용자 정의: Mode 3=2rows, Mode 13=12rows (Bypass 제외)
            num_rows = (mode <= 4'd2) ? 1 : mode - 4'd1;

            for (i = 0; i < num_rows; i = i + 1) begin
                // 별도의 negedge 대기 없이 posedge 직후 신호 업데이트 (연속성 보장)
                i_valid_max   = 1'b1;
                i_length_mode = mode;
                // 마지막 행이 가장 큰 값을 가지도록 설정하여 Forwarding 확인 용이하게 함
                i_glob_max    = base_val + i; 
                i_in_flat     = {64{base_val + i}};
                @(posedge i_clk);
                #0.1; // Hold time 시뮬레이션
            end
            i_valid_max = 1'b0; // 그룹 전송 완료 후 일단 내림 (연속 호출 시 바로 1로 덮어씌워짐)
        end
    endtask

    // --- 결과 모니터링 로그 ---
    initial $timeformat(-9, 2, " ns", 10);

    always @(posedge i_clk) begin
        if (o_valid_max) begin
            $display("[%t] [OUTPUT] Final_Max: %d | Mode: %d | Data[15:0]: %h", 
                      $time, $signed(o_total_max), o_length_mode_byp, o_in_byp[15:0]);
        end
    end

    // --- 메인 테스트 시나리오 ---
    initial begin
        // 초기화
        i_rst = 0; i_en = 0; i_valid_max = 0; i_glob_max = 0;
        i_length_mode = 0; i_in_flat = 0;
        {i_max64_0, i_max32_0, i_max32_1, i_max16_0, i_max16_1, i_max16_2, i_max16_3} = 0;

        // 시스템 리셋
        #20; i_rst = 1; #10; i_rst = 0; i_en = 1; #20;

        $display("\n--- TEST: Gap-less Streaming (Mode 3 -> Mode 13 -> Mode 4) ---");
        
        // 1. Mode 3 (2 Rows): 100, 101 입력 -> 둘 다 101로 출력되어야 함
        send_stream_group(4'd3, 16'd100); 

        // 2. 이어서 바로 Mode 13 (12 Rows): 200~211 입력 -> 12개 모두 211로 출력되어야 함
        send_stream_group(4'd13, 16'd200);

        // 3. 이어서 바로 Mode 4 (3 Rows): 300~302 입력 -> 3개 모두 302로 출력되어야 함
        send_stream_group(4'd4, 16'd300);

        // 출력이 나올 때까지 12단 고정 지연 고려하여 충분히 대기
        #300;

        $display("\n--- TEST: Bypass Mode Order Check ---");
        send_stream_group(4'd0, 16'd999); // Bypass
        send_stream_group(4'd3, 16'd10);  // Mode 3 (2 Rows)
        send_group_with_idle(4'd1, 16'd888); // Bypass (Idle 포함 버전 호출 가능)

        #200;
        $display("Simulation Finished at %t", $time);
        $finish;
    end

    // 간격이 있는 입력을 테스트하고 싶을 때를 위한 서브 태스크
    task send_group_with_idle;
        input [3:0] mode;
        input [15:0] base_val;
        begin
            send_stream_group(mode, base_val);
            repeat(3) @(posedge i_clk); // 3클럭 유휴기(Idle) 발생
        end
    endtask

endmodule
*/
`timescale 1ns/1ps

module tb_forwarding_simple;

    reg         clk;
    reg         en;
    reg         rst;

    reg         i_valid_max;
    reg [15:0]  i_loc_max;
    reg [3:0]   i_length_mode;
    reg [15:0]  i_temp;

    wire        o_valid_max;
    wire [15:0] o_global_max;
    wire [3:0]  o_length_mode_byp;
    wire [15:0] o_temp;

    forwarding_test dut (
        .i_clk(clk),
        .i_en(en),
        .i_rst(rst),

        .i_valid_max(i_valid_max),
        .i_loc_max(i_loc_max),
        .i_length_mode(i_length_mode),
        .i_temp(i_temp),

        .o_valid_max(o_valid_max),
        .o_global_max(o_global_max),
        .o_length_mode_byp(o_length_mode_byp),
        .o_temp(o_temp)
    );

    // clock
    always #5 clk = ~clk;

    // -------------------------
    // group drive task
    // -------------------------
    task drive_group;
        input [3:0] length_mode;
        integer i;
        integer group_len;
        reg [15:0] base;
    begin
        group_len = (length_mode > 0) ? (length_mode - 2) : 1;
        base      = 16'd10 * length_mode;   // length별로 max가 다르게 보이게

        @(negedge clk);
        i_length_mode = length_mode;
        i_valid_max   = 1'b1;

        for (i = 0; i < group_len; i = i + 1) begin
            @(negedge clk);
            // 가운데 값이 최대가 되도록
            if (i == group_len/2)
                i_loc_max = base + 16'd20;  // MAX
            else
                i_loc_max = base + i;

            i_temp = {12'hABC, i[3:0]};
        end

        // input stop
        @(negedge clk);
        i_loc_max     = 0;
        i_temp        = 0;
        i_length_mode = 0;
    end
    endtask

    // -------------------------
    // main stimulus
    // -------------------------
    integer lm;
    initial begin
        clk = 0;
        en  = 1;
        rst = 1;

        i_valid_max   = 0;
        i_loc_max     = 0;
        i_length_mode = 0;
        i_temp        = 0;

        #20;
        rst = 0;

        // length_mode = 1 ~ 13
        for (lm = 1; lm <= 13; lm = lm + 1) begin
            $display("\n==== TEST length_mode = %0d ====", lm);
            drive_group(lm[3:0]);
        end
    i_valid_max = 0;

        $display("\n==== ALL TESTS DONE ====");
        #50;
        $finish;
    end

    // -------------------------
    // output monitor
    // -------------------------
    always @(posedge clk) begin
        if (o_valid_max) begin
            $display(
                "[OUT] t=%0t | len=%0d | temp=%h | global_max=%0d",
                $time,
                o_length_mode_byp,
                o_temp,
                $signed(o_global_max)
            );
        end
    end

    initial begin
        $dumpfile("tb_forwarding_simple.vcd");
        $dumpvars(0, tb_forwarding_simple);
    end

endmodule

