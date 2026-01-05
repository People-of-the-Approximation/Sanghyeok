`timescale 1ns/1ps

module tb_softmax;

    // (1) Clock definition
    reg     clk;
    initial begin
        clk = 0;
        forever #(10) clk = ~clk; // 50MHz Clock
    end
    
    // (2) Signal definition
    wire          tester_en;
    wire          tester_start;
    wire          tester_rst;
    wire          tester_busy;
    wire    [7:0] tester_depth;

    // External Write Port (Port A)
    wire          tester_ext_cena;
    wire          tester_ext_wea;
    wire    [7:0] tester_ext_addra;
    wire [1027:0] tester_ext_dina;

    // External Read Port (Port B)
    wire          tester_ext_cenb;
    wire    [7:0] tester_ext_addrb;
    wire [1027:0] tester_ext_doutb;

    // (3) Module Instantiation (DUT)
    softmax_core dut_inst(
        .i_clk          (clk),
        .i_rst          (tester_rst),
        .i_en           (tester_en),
        .i_start        (tester_start),
        .o_busy         (tester_busy),
        .i_depth        (tester_depth),

        // External Write Port
        .i_ext_cena     (tester_ext_cena),
        .i_ext_wea      (tester_ext_wea),
        .i_ext_addra    (tester_ext_addra),
        .i_ext_dina     (tester_ext_dina),

        // External Read Port
        .i_ext_cenb     (tester_ext_cenb),
        .i_ext_addrb    (tester_ext_addrb),
        .o_ext_doutb    (tester_ext_doutb)
    );
    
    // (4) Tester Instantiation
    softmax_tester tester_inst(
        .i_clk          (clk),
        .o_depth        (tester_depth),
        
        .o_rst          (tester_rst),
        .o_en           (tester_en),
        .o_start        (tester_start),
        .i_busy         (tester_busy),

        // Write Control
        .o_ext_cena     (tester_ext_cena),
        .o_ext_wea      (tester_ext_wea),
        .o_ext_addra    (tester_ext_addra),
        .o_ext_dina     (tester_ext_dina),

        // Read Control
        .o_ext_cenb     (tester_ext_cenb),
        .o_ext_addrb    (tester_ext_addrb),
        .i_ext_doutb    (tester_ext_doutb)
    );
    
endmodule

module softmax_tester(
    input  wire           i_clk,
    output  reg     [7:0] o_depth,
    
    // System Control
    output reg            o_rst,
    output reg            o_en,
    output reg            o_start,
    input  wire           i_busy,

    // Write Port Interface
    output reg            o_ext_cena,
    output reg            o_ext_wea,
    output reg      [7:0] o_ext_addra,
    output reg   [1027:0] o_ext_dina,

    // Read Port Interface
    output reg            o_ext_cenb,
    output reg      [7:0] o_ext_addrb,
    input  wire  [1027:0] i_ext_doutb
);

    // Memory Depth Constants
    localparam DEPTH  = 17; // Address 0 to 11

    // Internal Memory for Verification
    reg [1027:0] local_input_data  [0:16]; // Buffer for Input Hex
    reg [1027:0] golden_output_data[0:16]; // Buffer for Expected Output Hex
    reg [1027:0] read_back_data    [0:16]; // Buffer for Read Result

    integer i;

    initial begin
        // 1. Initialize Signals & Load Data
        initialization();
        load_hex_files();

        // 2. Reset System
        reset_pulse();
        #100;

        // 3. Write Input Data to BRAM (External Access)
        write_input_data();

        // 4. Trigger Softmax Core
        start_pulse();

        // 5. Wait for Computation to Finish
        // Wait for busy to go HIGH then LOW
        wait(i_busy == 1'b1); 
        wait(i_busy == 1'b0);
        #100; // Safety margin

        // 6. Read Result from BRAM (External Access)
        // Checks data with 2-cycle latency
        verify_output_data();

        store_hex_files();

        // 7. Finish
        $display("Simulation Finished Successfully.");
        $finish;
    end

    //==========================================================================
    // Tasks Definitions
    //==========================================================================

    task initialization;
        begin
            o_rst       = 1'b1; // Active High Reset assumed based on code
            o_en        = 1'b1;
            o_start     = 1'b0;
            
            // Disable External Access initially
            o_ext_cena  = 1'b0; 
            o_ext_wea   = 1'b0;
            o_ext_addra = 5'd0;
            o_ext_dina  = 1028'd0;

            o_ext_cenb  = 1'b0;
            o_ext_addrb = 5'd0;

            o_depth     = DEPTH; // Set Depth to 12 for this test
        end
    endtask

    task load_hex_files;
        begin
            // 경로를 실제 파일 위치로 수정해주세요.
            // 데이터 포맷: 1028비트 (Hex 문자열 257자리)
            $readmemh("C:\\Users\\PSH\\DigitalCircuit\\Softmax_Design\\00_Softmax_Approx_with_Tree\\07_top_module\\input_1028b.hex",  local_input_data);
            $readmemh("C:\\Users\\PSH\\DigitalCircuit\\Softmax_Design\\00_Softmax_Approx_with_Tree\\07_top_module\\golden_1028b.hex", golden_output_data);
        end
    endtask

    task reset_pulse;
        begin
            @(posedge i_clk);
            #10;
            o_rst = 1'b1;
            #20;
            o_rst = 1'b0; // Reset release
            #10;
        end
    endtask

    task store_hex_files;
        begin
            $writememh("C:\\Users\\PSH\\DigitalCircuit\\Softmax_Design\\00_Softmax_Approx_with_Tree\\07_top_module\\out_1028b.hex", read_back_data);
        end
    endtask

    task start_pulse;
        begin
            @(posedge i_clk);
            #10;
            o_start = 1'b1;
            #20;          // Pulse width > 1 clock
            o_start = 1'b0;
        end
    endtask

    // Write Data to BRAM (Port A)
    // Address 0 ~ 11
    task write_input_data;
        begin
            $display("[Tester] Writing Input Data to BRAM...");
            @(posedge i_clk);
            
            for (i=0; i < DEPTH; i=i+1) begin
                o_ext_cena  = 1'b1; // Chip Enable
                o_ext_wea   = 1'b1; // Write Enable
                o_ext_addra = i;
                o_ext_dina  = local_input_data[i];
                @(posedge i_clk); // Write happens at posedge
                #5; // Setup/Hold margin simulation
            end

            // Disable Write
            o_ext_cena  = 1'b0;
            o_ext_wea   = 1'b0;
            o_ext_addra = 5'd0;
            o_ext_dina  = 1028'd0;
            $display("[Tester] Write Completed.");
        end
    endtask

    // Read Data from BRAM (Port B) and Verify
    // Address 12 ~ 23 (Result location)
    // **** IMPORTANT: Handles 2-Cycle Read Latency ****
    task verify_output_data;
        reg [1027:0] captured_data;
        begin
            $display("[Tester] Reading Output Data from BRAM (Addr 12~23)...");
            
            // BRAM_FSM wrote results to 12~23
            for (i=0; i < DEPTH; i=i+1) begin
                // 1. Issue Read Command (Cycle 0)
                @(posedge i_clk);
                o_ext_cenb  = 1'b1;
                o_ext_addrb = i; // Output starts at addr 12
                
                // 2. Wait for Latency (Cycle 1)
                @(posedge i_clk);
                // Address is registered inside BRAM here
                
                // 3. Data Available (Cycle 2)
                @(posedge i_clk); 
                // DO NOT change addr yet if pipelined, but for simple loop, sample now.
                #1; // Delay to sample stable data
                captured_data = i_ext_doutb;
                
                // 4. Compare
                if (captured_data !== golden_output_data[i]) begin
                    $display("[Error] Addr %d : Exp %h, Got %h", (i+12), golden_output_data[i], captured_data);
                end else begin
                    $display("[Pass]  Addr %d : Match", (i+12));
                end
                read_back_data[i] = captured_data; // Store read data
                // Disable Enable for next loop safety (optional)
                o_ext_cenb = 1'b0;
            end
            
            o_ext_cenb = 1'b0;
            $display("[Tester] Verification Completed.");
        end
    endtask
endmodule