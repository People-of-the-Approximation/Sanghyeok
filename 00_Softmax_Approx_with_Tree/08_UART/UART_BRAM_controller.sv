module uart_bram_controller(
    input  wire           i_clk,
    input  wire           i_rst,

    // UART Interface
    input  wire           i_rx_done,
    input  wire [7:0]     i_rxd,
    output reg            o_tx_start,
    output reg  [7:0]     o_tx_byte,
    input  wire           i_tx_done,

    // Interface to Softmax Core (External Access Ports)
    // Write Port (Port A)
    output reg            o_mem_cena,
    output reg            o_mem_wea,
    output reg      [4:0] o_mem_addra,
    output reg   [1027:0] o_mem_dina,

    // Read Port (Port B)
    output reg            o_mem_cenb,
    output reg      [4:0] o_mem_addrb,
    input  wire  [1027:0] i_mem_doutb,

    // Core Control
    output reg            o_core_start,
    input  wire           i_core_busy,

    // Debug State
    output wire [3:0]     o_debug_state
);

    // --- Parameters ---
    localparam BYTES_PER_ROW = 129; // 1028 bits = 128 bytes + 4 bits (약 129바이트 필요)
    localparam RX_ROW_COUNT  = 12;  // 입력 데이터 개수 (Addr 0~11)
    localparam TX_ROW_COUNT  = 12;  // 출력 데이터 개수 (Addr 12~23)
    localparam TX_START_ADDR = 12;  

    // --- States ---
    localparam S_IDLE        = 4'd0;
    localparam S_RX_ACC      = 4'd1;
    localparam S_RX_WRITE    = 4'd2;
    localparam S_CORE_START  = 4'd3;
    localparam S_CORE_WAIT   = 4'd4;
    localparam S_TX_REQ      = 4'd5;      // Cycle 0: 주소 인가
    localparam S_TX_WAIT_1   = 4'd6;      // Cycle 1: 첫 번째 대기 (추가됨/이름변경)
    localparam S_TX_WAIT_2   = 4'd7;      // Cycle 2: 두 번째 대기 (새로 추가)
    localparam S_TX_LOAD     = 4'd8;      // Cycle 3: 데이터 유효, 로드
    localparam S_TX_SEND     = 4'd9;
    localparam S_TX_CHECK    = 4'd10;     // 상태 번호 밀림 주의

    reg [3:0]    r_state;
    reg [1031:0] r_buffer;     // 129바이트 * 8 = 1032비트 (넉넉하게 잡음)
    reg [7:0]    r_byte_cnt;   // 바이트 카운터
    reg [4:0]    r_row_cnt;    // 행(Address) 카운터

    assign o_debug_state = r_state;

    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            r_state      <= S_IDLE;
            r_buffer     <= 0;
            r_byte_cnt   <= 0;
            r_row_cnt    <= 0;
            
            o_mem_cena   <= 0; 
            o_mem_wea   <= 0; 
            o_mem_addra <= 0; 
            o_mem_dina <= 0;
            o_mem_cenb   <= 0; 
            o_mem_addrb <= 0;
            o_tx_start   <= 0; 
            o_tx_byte   <= 0;
            o_core_start <= 0;
        end 
        else begin
            case (r_state)
                S_IDLE: begin
                    o_core_start <= 1'b0;
                    r_byte_cnt   <= 0;
                    r_row_cnt    <= 0;
                    // 첫 바이트가 들어오면 수신 시작
                    if (i_rx_done) begin
                        // MSB First로 가정하고 Shift Left
                        r_buffer <= {r_buffer[1023:0], i_rxd}; 
                        r_byte_cnt <= 1;
                        r_state    <= S_RX_ACC;
                    end
                end

                // 1. Data Reception Phase
                S_RX_ACC: begin
                    o_mem_cena <= 0; o_mem_wea <= 0; // 쓰기 비활성화

                    if (i_rx_done) begin
                        r_buffer <= {r_buffer[1023:0], i_rxd}; // Shift Left
                        
                        if (r_byte_cnt == BYTES_PER_ROW - 1) begin
                            r_state <= S_RX_WRITE;
                        end else begin
                            r_byte_cnt <= r_byte_cnt + 1;
                        end
                    end
                end

                S_RX_WRITE: begin
                    o_mem_cena  <= 1'b1;
                    o_mem_wea   <= 1'b1;
                    o_mem_addra <= r_row_cnt;
                    // 129바이트 중 하위 1028비트만 사용
                    o_mem_dina  <= r_buffer[1027:0]; 

                    if (r_row_cnt == RX_ROW_COUNT - 1) begin
                        r_state <= S_CORE_START; // 모든 입력 완료
                    end else begin
                        r_row_cnt  <= r_row_cnt + 1;
                        r_byte_cnt <= 0;
                        r_state    <= S_RX_ACC;  // 다음 줄 수신 대기
                    end
                end

                // 2. Computation Phase
                S_CORE_START: begin
                    o_mem_cena   <= 0; 
                    o_mem_wea    <= 0;
                    o_core_start <= 1'b1; // Start Trigger
                    r_state      <= S_CORE_WAIT;
                end

                S_CORE_WAIT: begin
                    o_core_start <= 1'b0;
                    
                    // Busy가 1이 되었다가 0으로 떨어질 때까지 대기
                    // 여기서는 간단히 Busy가 0이고 Start를 끈 직후가 아니면 완료로 간주
                    // (더 안전하게 하려면 Busy Rise -> Busy Fall 감지 로직 추가 권장)
                    if (i_core_busy == 1'b1) begin
                        // Busy 상태 유지
                    end else if (o_core_start == 0) begin
                        // Busy가 0이고 Start 명령을 내린 후라면 완료
                        r_row_cnt  <= TX_START_ADDR; // 12번지부터 읽기
                        r_state    <= S_TX_REQ;
                    end
                end

                // 3. Transmission Phase
                S_TX_REQ: begin
                    o_mem_cenb  <= 1'b1;
                    o_mem_addrb <= r_row_cnt;
                    r_state     <= S_TX_WAIT_1; // 첫 번째 대기로 이동
                end

                S_TX_WAIT_1: begin
                    // BRAM Read Latency Wait 1
                    o_mem_cenb  <= 1'b1; // Pulse 방식이라면 여기서 끔
                    r_state     <= S_TX_WAIT_2; // 두 번째 대기로 이동
                end

                S_TX_WAIT_2: begin
                    // BRAM Read Latency Wait 2
                    o_mem_cenb  <= 1'b0;
                    // 아무것도 안 하고 한 클럭 더 기다림
                    r_state     <= S_TX_LOAD;
                end

                S_TX_LOAD: begin
                    // 이제 데이터(i_mem_doutb)가 확실히 유효함
                    r_buffer[1031:4] <= i_mem_doutb; 
                    r_buffer[3:0]    <= 4'b0; 
                    
                    r_byte_cnt <= 0;
                    r_state    <= S_TX_SEND;
                end

                S_TX_SEND: begin
                    if (!i_tx_done) begin // 이전 전송 완료 상태가 아니면 (Idle)
                        o_tx_start <= 1'b1;
                        // 최상위 8비트 추출
                        o_tx_byte  <= r_buffer[1031:1024];
                        // 버퍼 Shift
                        r_buffer   <= {r_buffer[1023:0], 8'h00}; 
                        r_state    <= S_TX_CHECK;
                    end
                end

                S_TX_CHECK: begin
                    o_tx_start <= 1'b0;
                    if (i_tx_done) begin // 전송 완료 확인
                        if (r_byte_cnt == BYTES_PER_ROW - 1) begin
                            // 한 줄 전송 완료
                            if (r_row_cnt == TX_START_ADDR + TX_ROW_COUNT - 1) begin
                                r_state <= S_IDLE; // 모든 결과 전송 끝
                            end else begin
                                r_row_cnt <= r_row_cnt + 1;
                                r_state   <= S_TX_REQ; // 다음 줄 읽기 요청
                            end
                        end else begin
                            r_byte_cnt <= r_byte_cnt + 1;
                            r_state    <= S_TX_SEND; // 다음 바이트 전송
                        end
                    end
                end

                default: r_state <= S_IDLE;
            endcase
        end
    end

endmodule