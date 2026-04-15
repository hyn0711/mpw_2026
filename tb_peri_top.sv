`timescale 1ns/10ps

module tb_post_sim();

    parameter PER = 10;          // 10ns

    reg CLK;
    reg RSTN;

    // RISC-V <-> PERI
    reg [31:0] ADDRESS_I;
    reg [31:0] DATA_I;
    wire [31:0] DATA_O;

    // eFLASH <-> PERI
    reg [255:0] MOUT_I;
    reg [255:0] FOUT_I;

    wire [511:0] MODE_O;
    wire [255:0] WL_SEL_O;
    wire [255:0] VPASS_EN_O;
    wire [31:0] BL_OPT_T_O;
    wire [1:0] CSL_T_O;
    wire [1:0] QDAC_T_O;
    wire [1:0] DISC_T_O;
    wire [1:0] PRECB_T_O;

    wire [31:0] BL_OPT_U_O;
    wire [15:0] DUMH_OPT_O;
    wire [255:0] DUMH_O;
    wire [15:0] DUML_O;
    wire [1:0] CSL_U_O;
    wire [127:0] ADC_EN1_O;
    wire [127:0] ADC_EN2_O;
    wire [1:0] QDAC_U_O;
    wire [1:0] DISC_U_O;
    wire [1:0] PRECB_U_O;
    wire [3:0] RSEL_O;
    

    always #(PER/2) CLK = ~CLK;

    initial begin
        $dumpfile("peri_top.vcd");
        $dumpvars(0,peri_top);
    end

    peri_top_mpw peri_top(
        .CLK(CLK),
        .RSTN(RSTN),

        // RISC-V
        .ADDRESS_I(ADDRESS_I),
        .DATA_I(DATA_I),

        .DATA_O(DATA_O),

    // PIM
        .MOUT_I(MOUT_I),
        .FOUT_I(FOUT_I),

    // Signal (driver T)
        .MODE_O(MODE_O),
        .WL_SEL_O(WL_SEL_O),
        .VPASS_EN_O(VPASS_EN_O),
        .BL_OPT_T_O(BL_OPT_T_O),
        .CSL_T_O(CSL_T_O),
        .QDAC_T_O(QDAC_T_O),
        .DISC_T_O(DISC_T_O),
        .PRECB_T_O(PRECB_T_O),

    // Signal (driver U)
        .BL_OPT_U_O(BL_OPT_U_O),
        .DUMH_OPT_O(DUMH_OPT_O),
        .DUMH_O(DUMH_O),
        .DUML_O(DUML_O),
        .CSL_U_O(CSL_U_O),
        .ADC_EN1_O(ADC_EN1_O),
        .ADC_EN2_O(ADC_EN2_O),
        .QDAC_U_O(QDAC_U_O),
        .DISC_U_O(DISC_U_O),
        .PRECB_U_O(PRECB_U_O),
        .RSEL_O(RSEL_O)
    );

    // Pim mode ------------------------------------------------
    typedef enum logic [2:0] {
        PIM_ERASE = 3'b001,
        PIM_PROGRAM = 3'b010,
        PIM_READ = 3'b011,
        PIM_ZP = 3'b100,
        PIM_PARALLEL = 3'b101,
        PIM_RBR = 3'b110,
        PIM_LOAD = 3'b111
    } pim_mode_t;

    // ---------------------------------------------------------
    // RISC-V -> Peri
    task automatic send_mode(input pim_mode_t pim_mode);
        @(negedge CLK);
        ADDRESS_I = 32'h4100_0000;
        DATA_I = {29'b0, pim_mode};
    endtask

    task automatic check_status();
        @(negedge CLK); 
        ADDRESS_I = 32'h4300_0000;
    endtask

    task automatic send_data(
        input pim_mode_t pim_mode,
        input int row, 
        input int col,
        input int p_width, 
        input int p_count,
        input int zp
    );
        case (pim_mode)
        PIM_ERASE: begin
            @(negedge CLK);
            ADDRESS_I = {16'h4000, row[6:0], col[8:0]};
            DATA_I = {10'b0, p_width[16:0], p_count[4:0]};
        end
        PIM_PROGRAM: begin
            @(negedge CLK);
            ADDRESS_I = {16'h4000, row[6:0], col[8:0]};
            DATA_I = {10'b0, p_width[16:0], p_count[4:0]};
        end
        PIM_READ: begin
            @(negedge CLK);
            ADDRESS_I = {16'h4000, row[6:0], col[8:0]};
            DATA_I = '0;
            repeat(9) @(negedge CLK); random_eFlash_output();
            @(negedge CLK);
        end
        PIM_ZP: begin
            @(negedge CLK);
            ADDRESS_I = 32'h4200_0000;
            DATA_I = zp[31:0];
        end
        PIM_PARALLEL: begin
            for (int i = 0; i < 8; i++) begin
                @(negedge CLK);
                ADDRESS_I = {12'h400, i[3:0], row[6:0], col[8:0]};
                for (int j = 0; j < 16; j++) begin
                    DATA_I[2 * j +: 2] = $urandom_range(0, 3);
                end
                $write("0x32h", DATA_I);
                $write("\n");
            end
            for (int i = 8; i < 16; i++) begin
                @(negedge CLK);
                ADDRESS_I = {12'h400, i[3:0], row[6:0], col[8:0]};
                DATA_I = '0;
            end
            repeat(9) @(negedge CLK); random_eFlash_output();
            repeat(3) @(negedge CLK); random_eFlash_output();
            @(negedge CLK);
        end
        PIM_RBR: begin
            for (int i = 0; i < 1; i++) begin
                @(negedge CLK);
                ADDRESS_I = {12'h400, i[3:0], row[6:0], col[8:0]};
                for (int j = 0; j < 16; j++) begin
                    DATA_I[2 * j +: 2] = $urandom_range(0, 3);
                end
                $write("0x32h", DATA_I);
                $write("\n");
            end
            for (int i = 1; i < 2; i++) begin
                @(negedge CLK);
                ADDRESS_I = {12'h400, i[3:0], row[6:0], col[8:0]};
                DATA_I = '0;
            end
            repeat(9) @(negedge CLK); random_eFlash_output();
            @(negedge CLK); 
        end
        endcase
    endtask

    // Reset all the input signal
    task automatic init_signals();
        @(negedge CLK);
        ADDRESS_I = '0;
        DATA_I = '0;
        //EFLASH_OUTPUT_1_I = '0;
    endtask

    // Make the random output from the eFlash PIM
    task automatic random_eFlash_output();
        // 8 bit * 128
        logic [7:0] choices8b[] = '{
            8'b00000000, 8'b10000000, 8'b11000000, 8'b11100000, 8'b11110000, 8'b11111000, 8'b11111100, 8'b11111110, 8'b11111111
            };
        for (int i = 0; i < 32; i++) begin
            MOUT_I[255 - 8*i -: 8] = choices8b[$urandom_range(0, choices8b.size()-1)];
        end
        for (int i = 0; i < 32; i++) begin
            FOUT_I[255 - 8*i -: 8] = choices8b[$urandom_range(0, choices8b.size()-1)];
        end
        $write("0x64h", MOUT_I);
        $write("0x64h", FOUT_I);
        $write("\n");
    endtask



    // Testbench
    initial begin
        // Initialize signals
        RSTN = '0;
        CLK = 1'b1;
        init_signals();

        // random_eFlash_output();

        repeat(2) @(posedge CLK); RSTN = 1'b1;

        // Test erase mode
        repeat(3) check_status();
        send_mode(PIM_ERASE);
        send_data(PIM_ERASE, 1, 1, 2, 2, 0);
        repeat (10000) init_signals();

        // Test program mode
        repeat(3) check_status();
        send_mode(PIM_PROGRAM);
        send_data(PIM_PROGRAM, 10, 12, 3, 4, 0);
        repeat (10000) init_signals();

        // // Test zp mode
        // repeat(3) check_status();
        // send_mode(PIM_ZP);
        // send_data(PIM_ZP, 0, 0, 0, 0, 1234);
        // repeat (10000) init_signals();

        // Test read mode
        repeat(3) check_status();
        send_mode(PIM_READ);
        send_data(PIM_READ, 5, 9, 0, 0, 0);
        repeat (10000) init_signals();

        // Test load mode
        repeat(3) check_status();
        send_mode(PIM_LOAD);
        @(negedge CLK); ADDRESS_I = 32'h4000_0000;
                        DATA_I = '0; 
        repeat(33) @(negedge CLK);
        repeat (10000) init_signals();

        // Test parallel mode
        repeat(3) check_status();
        send_mode(PIM_PARALLEL);
        init_signals();
        send_data(PIM_PARALLEL, 10, 12, 0, 0, 0);
        repeat (10000) init_signals();

        // Test load mode
        repeat(3) check_status();
        send_mode(PIM_LOAD);
        @(negedge CLK); ADDRESS_I = 32'h4000_0000;
                        DATA_I = '0; 
        repeat(34) @(negedge CLK);
        repeat (10000) init_signals();

        // Test rbr mode
        repeat(3) check_status();
        send_mode(PIM_RBR);
        init_signals();
        send_data(PIM_RBR, 1, 2, 0, 0, 0);
        repeat (10000) init_signals();

        // Test load mode
        repeat(3) check_status();
        send_mode(PIM_LOAD);
        @(negedge CLK); ADDRESS_I = 32'h4000_0000;
                        DATA_I = '0; 
        repeat(34) @(negedge CLK);
        repeat (10000) init_signals();


        @(posedge CLK); $finish;

    end



endmodule