`timescale 1ns/1ps

module acc_max_tb;

    // Parameters & Signals
    reg         i_clk;
    reg         i_en;
    reg         i_rst;
    reg          i_valid_max;
    reg   [15:0] i_max64_0;
    reg    [3:0] i_length_mode;
    reg [1023:0] i_in_flat;

    wire        o_valid_max;
    wire [15:0] o_max64_0;
    wire [3:0]  o_length_mode_byp;
    wire [1023:0] o_in_byp;

    // Clock Generation (100MHz)
    initial i_clk = 0;
    always #5 i_clk = ~i_clk;

    // DUT Instantiation
    acc_max DUT (
        .i_clk(i_clk),
        .i_en(i_en),
        .i_rst(i_rst),
        .i_valid_max(i_valid_max),
        .i_max64_0(i_max64_0),
        .i_length_mode(i_length_mode),
        .i_in_flat(i_in_flat),
        .o_valid_max(o_valid_max),
        .o_max64_0(o_max64_0),
        .o_length_mode_byp(o_length_mode_byp),
        .o_in_byp(o_in_byp)
    );

    // --- 자동화된 그룹 전송 태스크 ---
    // 사용자는 mode 값만 주면, 태스크가 내부에서 행의 개수를 판단하여 전송함
    task send_group;
        input [3:0] mode;      // i_length_mode 값
        input [15:0] start_val; // 데이터 식별을 위한 시작 값
        integer i;
        integer num_rows;
        begin
            // 모드에 따른 행 개수 결정 로직
            if (mode <= 4'd2) num_rows = 1;              // Bypass
            else              num_rows = mode - 4'd1;   // Mode 3 -> 2rows, Mode 13 -> 12rows

            for (i = 0; i < num_rows; i = i + 1) begin
                @(negedge i_clk);
                i_valid_max   = 1;
                i_length_mode = mode;
                i_max64_0     = start_val + i;
                i_in_flat     = {64{start_val + i}}; // 16비트씩 동일 데이터로 채움
                @(posedge i_clk);
                #1; // Hold time 확보
                i_valid_max   = 0;
            end
        end
    endtask

    // --- 결과 모니터링 ---
    initial begin
        $timeformat(-9, 2, " ns", 10);
    end

    always @(posedge i_clk) begin
        if (o_valid_max) begin
            $display("[%t] OUT: Valid | Final_Max: %d | Mode: %d | Data_Low: %h", 
                      $time, $signed(o_max64_0), o_length_mode_byp, o_in_byp[15:0]);
        end
    end

    // --- 메인 테스트 시나리오 ---
    initial begin
        // 초기화
        i_rst = 0; i_en = 0; i_valid_max = 0;
        i_max64_0 = 0; i_length_mode = 0; i_in_flat = 0;

        // Reset 처리
        #20; i_rst = 1; 
        #10; i_rst = 0; i_en = 1; 
        #20;

        $display("\n--- Test 1: Mode 3 (2 Rows) Basic ---");
        // 결과: 501이 최대값으로 2번 출력되어야 함
        send_group(4'd3, 16'd500); 

        #100;

        $display("\n--- Test 2: Continuous Streaming (Mode 13 then Mode 3) ---");
        $display("Checking back-to-back injection and FIFO handling...");
        // 12개 행(Max 111) 바로 뒤에 2개 행(Max 2001) 주입
        fork
            begin
                send_group(4'd13, 16'd100);  // 12 rows
                send_group(4'd3,  16'd2000); // 2 rows
            end
        join

        #250; // 모든 출력이 나올 때까지 충분히 대기

        $display("\n--- Test 3: Multiple Small Groups (FIFO Push/Pop check) ---");
        // 짧은 그룹 3개를 연달아 주입하여 FIFO가 순차적으로 처리하는지 확인
        send_group(4'd3, 16'd10);
        send_group(4'd3, 16'd20);
        send_group(4'd3, 16'd30);

        #150;
        
        $display("\n--- Test 4: Mixed Bypass and Accumulation ---");
        // Bypass(1개) -> Mode 4(3개) -> Bypass(1개)
        send_group(4'd0, 16'd999);  // Bypass
        send_group(4'd4, 16'd100);  // Mode 4 (3 rows)
        send_group(4'd1, 16'd888);  // Bypass

        #300;
        $display("\nSimulation Finished at %t", $time);
        $finish;
    end

endmodule