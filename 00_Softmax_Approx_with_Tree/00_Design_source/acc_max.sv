/*
module max_forwarding (
    input  wire           i_clk,
    input  wire           i_en,
    input  wire           i_rst,

    input  wire           i_valid_max,
    input  wire signed [15:0] i_glob_max, // signed 명시

    input  wire    [3:0]  i_length_mode,
    input  wire [1023:0]  i_in_flat,

    output wire           o_valid_max,
    output wire    [15:0] o_total_max,
    output wire    [3:0]  o_length_mode_byp,
    output wire [1023:0]  o_in_byp,

    // Sub-max inputs (max_tree_64로부터 입력)
    input  wire    [15:0] i_max64_0,
    input  wire    [15:0] i_max32_0, i_max32_1,
    input  wire    [15:0] i_max16_0, i_max16_1, i_max16_2, i_max16_3,

    // Sub-max outputs (12단 지연 후 출력)
    output wire    [15:0] o_max64_0,
    output wire    [15:0] o_max32_0, o_max32_1,
    output wire    [15:0] o_max16_0, o_max16_1, o_max16_2, o_max16_3
);

    // --- 파이프라인 레지스터 (12단) ---
    reg          r_valid_max_pip   [0:11];
    reg [3:0]    r_length_mode_byp [0:11];
    reg [1023:0] r_in_flat_pip     [0:11];
    reg [15:0]   r_max64_0_pip [0:11], r_max32_0_pip [0:11], r_max32_1_pip [0:11];
    reg [15:0]   r_max16_0_pip [0:11], r_max16_1_pip [0:11], r_max16_2_pip [0:11], r_max16_3_pip [0:11];

    always @(posedge i_clk) begin
        if (i_rst) begin
            for (integer k = 0; k <= 11; k = k + 1) begin
                r_valid_max_pip[k] <= 1'b0; r_length_mode_byp[k] <= 4'b0;
                r_in_flat_pip[k]   <= 1024'd0;
                // ... 나머지 sub-max pip 초기화 생략 (동일 구조)
            end
        end else if (i_en) begin
            r_valid_max_pip[0] <= i_valid_max;
            r_length_mode_byp[0] <= i_length_mode;
            r_in_flat_pip[0] <= i_in_flat;
            r_max64_0_pip[0] <= i_max64_0;
            r_max32_0_pip[0] <= i_max32_0; r_max32_1_pip[0] <= i_max32_1;
            r_max16_0_pip[0] <= i_max16_0; r_max16_1_pip[0] <= i_max16_1;
            r_max16_2_pip[0] <= i_max16_2; r_max16_3_pip[0] <= i_max16_3;

            for (integer k = 0; k <= 10; k = k + 1) begin
                r_valid_max_pip[k+1]   <= r_valid_max_pip[k];
                r_length_mode_byp[k+1] <= r_length_mode_byp[k];
                r_in_flat_pip[k+1]     <= r_in_flat_pip[k];
                r_max64_0_pip[k+1]     <= r_max64_0_pip[k];
                r_max32_0_pip[k+1]     <= r_max32_0_pip[k]; r_max32_1_pip[k+1] <= r_max32_1_pip[k];
                r_max16_0_pip[k+1]     <= r_max16_0_pip[k]; r_max16_1_pip[k+1] <= r_max16_1_pip[k];
                r_max16_2_pip[k+1]     <= r_max16_2_pip[k]; r_max16_3_pip[k+1] <= r_max16_3_pip[k];
            end
        end
    end

    // --- Max Forwarding & Accumulation 로직 ---
    reg [15:0] r_total_max_shift [0:11];
    reg [11:0] r_parallel_load;
    reg [11:0] r_parallel_load_cnt;
    reg        r_acc_reset;
    reg [3:0]  r_acc_cnt;
    reg [15:0] r_acc_max;

    wire [15:0] w_acc_max = ($signed(r_acc_max) > $signed(i_glob_max)) ? r_acc_max : i_glob_max;

    // 마스크 비트 조정: Reset 시점에 데이터는 이미 1칸 이상 밀려있음
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

    // 누적 및 Reset 제어 통합
    always @(posedge i_clk) begin
        if (i_rst) begin
            r_acc_max       <= 16'h8000;
            r_acc_cnt       <= 4'd0;
            r_parallel_load <= 12'd0;
            r_acc_reset     <= 1'b0;
        end else if (i_en) begin
            if (r_acc_reset) begin
                // 완료 직후 클럭: 마스크 주입 및 초기화
                r_parallel_load <= r_parallel_load_cnt;
                r_acc_max       <= 16'h8000;
                r_acc_cnt       <= 4'd0;
                r_acc_reset     <= 1'b0;
            end else if (i_valid_max) begin
                r_acc_max       <= w_acc_max;
                r_parallel_load <= 12'd0;
                if (r_acc_cnt == i_length_mode - 4'd2) begin
                    r_acc_reset <= 1'b1;
                end else begin
                    r_acc_cnt   <= r_acc_cnt + 4'd1;
                end
            end else begin
                r_parallel_load <= 12'd0;
            end
        end
    end

    // 병렬 로드 쉬프트 레지스터
    always @(posedge i_clk) begin
        if (i_rst) begin
            for (integer k = 0; k <= 11; k = k + 1) r_total_max_shift[k] <= 16'h8000;
        end else if (i_en) begin
            r_total_max_shift[0] <= r_parallel_load[0] ? w_acc_max : i_glob_max;
            for (integer k = 1; k <= 11; k = k + 1) begin
                if (r_parallel_load[k]) r_total_max_shift[k] <= w_acc_max;
                else                    r_total_max_shift[k] <= r_total_max_shift[k-1];
            end
        end
    end

    // --- 출력 할당 ---
    assign o_valid_max       = r_valid_max_pip[11];
    assign o_total_max       = r_total_max_shift[11];
    assign o_length_mode_byp = r_length_mode_byp[11];
    assign o_in_byp          = r_in_flat_pip[11];

    assign o_max64_0 = r_max64_0_pip[11];
    assign o_max32_0 = r_max32_0_pip[11]; assign o_max32_1 = r_max32_1_pip[11];
    assign o_max16_0 = r_max16_0_pip[11]; assign o_max16_1 = r_max16_1_pip[11];
    assign o_max16_2 = r_max16_2_pip[11]; assign o_max16_3 = r_max16_3_pip[11];

endmodule
*/


module forwarding_test (
    // Operation signals
    input  wire           i_clk,
    input  wire           i_en,
    input  wire           i_rst,

    input  wire    [15:0] i_loc_max,     // 현재 입력되는 Local Max
    input  wire    [3:0]  i_length_mode, // 현재 그룹의 길이 모드
    input  wire    [15:0] i_temp,        // 동기화할 데이터 (Payload)

    output wire    [15:0] o_global_max,      // 12클럭 뒤 정렬된 Global Max
    output wire    [3:0]  o_length_mode_byp, // 12클럭 뒤 모드
    output wire    [15:0] o_temp             // 12클럭 뒤 데이터
);

    // --- 1. 파이프라인 레지스터 선언 ---
    reg [15:0] r_temp_pip   [0:11]; // 데이터 파이프라인
    reg [15:0] r_max_shift  [0:11]; // Max값 파이프라인 (Forwarding 대상)
    reg [3:0]  r_length_byp [0:11]; // 모드 파이프라인

    // --- 2. 제어 신호 및 내부 변수 ---
    reg [3:0]  r_cnt;           // 그룹 내 데이터 카운터
    reg        r_acc_rst_loc;   // acc_max를 위한 로컬 리셋 신호
    reg [11:0] r_load_mask;     // 병렬 로드 위치를 지정하는 마스크

    // acc_max 연결 와이어
    wire [15:0] w_max_front; // 현재 입력까지 포함한 최신 Max
    wire [15:0] w_max_acc;   // 레지스터에 저장된 이전 Max

    // --- 3. acc_max 인스턴스화 ---
    acc_max u_acc_max (
        .i_clk       (i_clk),
        .i_en        (i_en),
        .i_rst       (i_rst),
        .i_rst_loc   (r_acc_rst_loc), // 그룹 종료 시 리셋 트리거
        .i_valid_max (1'b1),          // forwarding_test는 항상 valid하다고 가정 (Testbench 제어)
        .i_loc_max   (i_loc_max),
        .o_max_front (w_max_front),   // Combinational Output (Current Max)
        .o_max_acc   (w_max_acc)      // Registered Output
    );

    // --- 4. 마스크 로직 (Combinational) ---
    // i_length_mode에 따라 파이프라인의 어디까지 덮어쓸지 결정
    always @(*) begin
        case (i_length_mode)
            4'd3:    r_load_mask = 12'b0000_0000_0011; // 2개 (index 0, 1)
            4'd4:    r_load_mask = 12'b0000_0000_0111; // 3개 (index 0, 1, 2)
            4'd5:    r_load_mask = 12'b0000_0000_1111; // 4개
            4'd6:    r_load_mask = 12'b0000_0001_1111; // 5개
            4'd7:    r_load_mask = 12'b0000_0011_1111; // 6개
            4'd8:    r_load_mask = 12'b0000_0111_1111; // 7개
            4'd9:    r_load_mask = 12'b0000_1111_1111; // 8개
            4'd10:   r_load_mask = 12'b0001_1111_1111; // 9개
            4'd11:   r_load_mask = 12'b0011_1111_1111; // 10개
            4'd12:   r_load_mask = 12'b0111_1111_1111; // 11개
            4'd13:   r_load_mask = 12'b1111_1111_1111; // 12개 (전체)
            default: r_load_mask = 12'b0000_0000_0001; // 기본 1개
        endcase
    end

    // --- 5. 메인 시퀀셜 로직 ---
    always @(posedge i_clk) begin
        if (i_rst) begin
            r_cnt         <= 4'd0;
            r_acc_rst_loc <= 1'b0;
            for (integer k=0; k<12; k=k+1) begin
                r_temp_pip[k]   <= 16'd0;
                r_max_shift[k]  <= 16'h8000;
                r_length_byp[k] <= 4'd0;
            end
        end 
        else if (i_en) begin
            // 5-1. 기본 파이프라인 쉬프트
            r_temp_pip[0]   <= i_temp;
            r_length_byp[0] <= i_length_mode;
            r_max_shift[0]  <= i_loc_max; // 일단 현재 값 넣음 (나중에 덮어씌워질 수 있음)

            for (integer k=1; k<12; k=k+1) begin
                r_temp_pip[k]   <= r_temp_pip[k-1];
                r_length_byp[k] <= r_length_byp[k-1];
                r_max_shift[k]  <= r_max_shift[k-1];
            end

            // 5-2. 카운터 및 Forwarding 제어
            // Mode 3 (2 items) -> Count 0, 1 (Reset at 1)
            if (r_cnt == i_length_mode - 4'd2) begin
                // [그룹 종료 시점!]
                // 마스크에 해당하는 모든 파이프라인 레지스터를 '최종 Max(w_max_front)'로 덮어씀
                for (integer k=0; k<12; k=k+1) begin
                    if (r_load_mask[k]) begin
                        r_max_shift[k] <= w_max_front;
                    end
                end
                
                // 다음 그룹을 위해 카운터 초기화 및 acc_max 리셋 신호 생성
                r_cnt         <= 4'd0;
                r_acc_rst_loc <= 1'b1; // 다음 클럭에 acc_max 리셋됨
            end 
            else begin
                r_cnt         <= r_cnt + 4'd1;
                r_acc_rst_loc <= 1'b0;
            end
        end
    end

    // --- 6. 출력 연결 (12단 지연) ---
    assign o_global_max      = r_max_shift[11];
    assign o_length_mode_byp = r_length_byp[11];
    assign o_temp            = r_temp_pip[11];

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
