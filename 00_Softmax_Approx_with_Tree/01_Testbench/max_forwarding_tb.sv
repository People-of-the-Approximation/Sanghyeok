
module max_forwarding_tb;

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

