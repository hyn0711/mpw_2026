
// eFlash row wise driver

module eFlash_driver_U (
    input logic                 clk_i,
    input logic                 rst_ni,

    // eFlash signal control
    input logic                 pim_en_i,
    input logic [2:0]           pim_mode_i,
    input logic [3:0]           exec_cnt_i,

    // address
    input logic [6:0]           row_addr7_i,    // 0 ~ 127
    input logic [4:0]           col_addr5_i,    // 0 ~ 31

    // input buffer
    input logic [31:0]          input_data_i,
    input logic [3:0]           data_cnt_i,

    input logic                 in_buf_write_i,
    input logic                 in_buf_read_i,

    // Output Signal to PIM
    output logic [31:0]         BL_OPT_o,
    output logic [15:0]         DUMH_OPT_o,
    output logic [255:0]        DUMH_o,
    output logic [15:0]         DUML_o,
    output logic [1:0]          CSL_o,
    output logic [127:0]        ADC_EN1_o,
    output logic [127:0]        ADC_EN2_o,
    output logic [1:0]          QDAC_o,
    output logic [1:0]          DISC_o,
    output logic [1:0]          PRECB_o,
    output logic [3:0]          RSEL_o,

    // Output buffer 
    output logic                buf_write_en_1_o,
    output logic                buf_write_en_2_o
);

    // eFlash mode
    localparam PIM_ERASE = 3'b001;
    localparam PIM_PROGRAM = 3'b010;
    localparam PIM_READ = 3'b011;
    localparam PIM_ZP = 3'b100;
    localparam PIM_PARALLEL = 3'b101;
    localparam PIM_RBR = 3'b110;
    localparam PIM_LOAD = 3'b111;

    // Signal
    logic [31:0] bl_opt;
    logic [15:0] dumh_opt;
    logic [255:0] dumh;
    logic [15:0] duml;
    logic [1:0] csl;
    logic [127:0] adc_en1, adc_en2;
    logic [1:0] qdac;
    logic [1:0] disc;
    logic [1:0] precb;
    logic [3:0] rsel;

    logic [3:0] row_a;
    logic [1:0] col_b;
    logic [2:0] row_c;

    assign row_a = row_addr7_i[3:0];
    assign col_b = col_addr5_i[2:0];
    assign row_c = row_addr7_i[6:4];

    logic pim_en;
    logic [2:0] pim_mode;
    logic [3:0] exec_cnt;

    assign pim_en = pim_en_i;
    assign pim_mode = pim_mode_i;
    assign exec_cnt = exec_cnt_i;

    logic buf_write_en_1, buf_write_en_2;

// --------------------------- input buffer ---------------------------
    logic [1:0]     input_mem [0:127];
    logic [1:0]     input_data [0:127];

    // Write input data in the buffer
    always_ff @ (posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            for (int i = 0; i < 127; i++) begin
                input_mem[i] <= '0;
            end
        end else begin
            if (in_buf_write_i) begin
                if (data_cnt_i == 4'd0) begin
                    for (int i = 0; i < 16; i++) begin
                        input_mem[i] <= input_data_i[31 - 2*i -: 2];
                    end
                end else if (data_cnt_i == 4'd1) begin
                    for (int i = 16; i < 32; i++) begin
                        input_mem[i] <= input_data_i[31 - 2*(i%16) -: 2];
                    end
                end else if (data_cnt_i == 4'd2) begin
                    for (int i = 32; i < 48; i++) begin
                        input_mem[i] <= input_data_i[31 - 2*(i%16) -: 2];
                    end
                end else if (data_cnt_i == 4'd3) begin
                    for (int i = 48; i < 64; i++) begin
                        input_mem[i] <= input_data_i[31 - 2*(i%16) -: 2];
                    end
                end else if (data_cnt_i == 4'd4) begin
                    for (int i = 64; i < 80; i++) begin
                        input_mem[i] <= input_data_i[31 - 2*(i%16) -: 2];
                    end
                end else if (data_cnt_i == 4'd5) begin
                    for (int i = 80; i < 96; i++) begin
                        input_mem[i] <= input_data_i[31 - 2*(i%16) -: 2];
                    end
                end else if (data_cnt_i == 4'd6) begin
                    for (int i = 96; i < 112; i++) begin
                        input_mem[i] <= input_data_i[31 - 2*(i%16) -: 2];
                    end
                end else if (data_cnt_i == 4'd7) begin
                    for (int i = 112; i < 128; i++) begin
                        input_mem[i] <= input_data_i[31 - 2*(i%16) -: 2];
                    end
                end else begin
                    for (int i = 0; i < 128; i++) begin
                        input_mem[i] <= input_mem[i];
                    end
                end
            end else begin
                for (int i = 0; i < 128; i++) begin
                    input_mem[i] <= input_mem[i];
                end
            end
        end
    end

    // Read the input data
    always_comb begin
        if (in_buf_read_i) begin
            for (int i = 0; i < 128; i++) begin
                input_data[i] = '0;
            end
            if (pim_mode == PIM_PARALLEL) begin
                for (int i = 0; i < 128; i++) begin
                    input_data[i] = input_mem[i];
                end
            end else if (pim_mode == PIM_RBR) begin
                for (int i = 0; i < 16; i++) begin
                    input_data[i] = input_mem[i];
                end
            end else begin
                for (int i = 0; i < 128; i++) begin
                    input_data[i] = '0;
                end
            end
        end else begin
            for (int i = 0; i < 128; i++) begin
                input_data[i] = '0;
            end
        end
    end

 
// --------------------------- eFlash signal ---------------------------
    always_comb begin
        bl_opt = '0;
        dumh_opt = '0;
        dumh = '0;
        duml = '0;
        csl = '0;
        adc_en1 = '0;
        adc_en2 = '0;
        qdac = 2'b11;
        disc = 2'b11;
        precb = 2'b11;
        rsel = '0;

        buf_write_en_1 = '0;
        buf_write_en_2 = '0;

        if (pim_en) begin
            case (pim_mode)
                PIM_ERASE: begin        // Erase mode
                    buf_write_en_1 = '0;
                    buf_write_en_2 = '0;

                    bl_opt = '0;
                    dumh_opt = '0;
                    dumh = '0;
                    duml = '0;
                    csl = '0;
                    adc_en1 = '0;
                    adc_en2 = '0;
                    qdac = 2'b11;
                    disc = 2'b11;
                    precb = 2'b11;
                    rsel = '0;
                end

                PIM_PROGRAM: begin      // Program mode
                    buf_write_en_1 = '0;
                    buf_write_en_2 = '0;

                    for (int unsigned i = 0; i < 32; i++) begin
                        if (i == col_addr5_i) begin
                            bl_opt[i] = '0;
                        end else begin
                            bl_opt[i] = 1'b1;
                        end
                    end
                    for (int unsigned i = 0; i < 8; i++) begin
                        if (i == row_c) begin
                            dumh_opt[i] = 1'b1;
                            dumh_opt[i + 8] = 1'b1;
                        end else begin
                            dumh_opt[i] = '0;
                            dumh_opt[i + 8] = '0;
                        end
                    end
                    dumh = '0;
                    duml = '0;
                    csl = 2'b11;
                    adc_en1 = 1'b0;
                    adc_en2 = 1'b0;
                    qdac = 2'b11;
                    disc = 2'b11;
                    precb = 2'b11;
                    rsel = '0;
                end

                PIM_READ: begin
                    bl_opt = '0;
                    dumh_opt = '0;
                    csl = '0;
                    adc_en2 = '0;
                    qdac = 2'b11;
                    disc = '0;
                    rsel = 4'b0101;

                    buf_write_en_2 = '0;

                    if (exec_cnt == 4'd9 || exec_cnt == 4'd8 || exec_cnt == 4'd7) begin
                        for (int unsigned j = 0; j < 8; j++) begin
                            if (j == col_b) begin
                                for (int unsigned k = 0; k < 16; k++) begin
                                    dumh[8 * k + j] = 1'b1;
                                    dumh[8 * k + j + 128] = 1'b1;
                                end
                            end else begin
                                for (int unsigned k = 0; k < 16; k++) begin
                                    dumh[8 * k + j] = 1'b0;
                                    dumh[8 * k + j + 128] = 1'b0;
                                end
                            end
                        end
                        duml = 16'hFFFF;
                        precb = '0;
                        adc_en1 = '0;
                        buf_write_en_1 = '0;
                    end else if (exec_cnt == 4'd6) begin
                        for (int unsigned j = 0; j < 8; j++) begin
                            if (j == col_b) begin
                                for (int unsigned k = 0; k < 16; k++) begin
                                    dumh[8 * k + j] = 1'b1;
                                    dumh[8 * k + j + 128] = 1'b1;
                                end
                            end else begin
                                for (int unsigned k = 0; k < 16; k++) begin
                                    dumh[8 * k + j] = 1'b0;
                                    dumh[8 * k + j + 128] = 1'b0;
                                end
                            end
                        end
                        duml = 16'hFFFF;
                        precb = 2'b11;
                        adc_en1 = '0;
                        buf_write_en_1 = '0;
                    end else if (exec_cnt == 4'd5 || exec_cnt == 4'd4 || exec_cnt == 4'd3) begin
                        dumh = '0;
                        duml = '0;
                        precb = 2'b11;
                        adc_en1 = '0;
                        buf_write_en_1 = '0;
                    end else if (exec_cnt == 4'd2 || exec_cnt == 4'd1) begin
                        dumh = '0;
                        duml = '0;
                        precb = 2'b11;
                        adc_en1 = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
                        buf_write_en_1 = 1'b1;
                    end else begin
                        dumh = '0;
                        duml = '0;
                        precb = 2'b11;
                        adc_en1 = '0;
                        buf_write_en_1 = '0;
                    end
                end

                PIM_PARALLEL: begin     
                    bl_opt = '0;
                    dumh_opt = '0;
                    csl = '0;
                    disc = '0;
                    rsel = 4'b1010;

                    if (exec_cnt == 4'd12 || exec_cnt == 4'd11 || exec_cnt == 4'd10) begin
                        dumh = 256'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
                        duml = 16'hFFFF;
                        precb = '0;
                        adc_en1 = '0;
                        adc_en2 = '0;
                        qdac = 2'b11;
                        buf_write_en_1 = '0;
                        buf_write_en_2 = '0;
                    end else if (exec_cnt == 4'd9 || exec_cnt == 4'd8 || exec_cnt == 4'd7) begin
                        for (int unsigned i = 0; i < 128; i++) begin
                            case (input_data[i])
                                2'b00: begin
                                    dumh[i] = '0;
                                    dumh[i + 128] = '0;
                                end
                                2'b01: begin
                                    dumh[i] = (exec_cnt == 4'd9);
                                    dumh[i + 128] = (exec_cnt == 4'd9);
                                end
                                2'b10: begin
                                    dumh[i] = (exec_cnt == 4'd9 || exec_cnt == 4'd8);
                                    dumh[i + 128] = (exec_cnt == 4'd9 || exec_cnt == 4'd8);
                                end
                                2'b11: begin
                                    dumh[i] = 1'b1;
                                    dumh[i + 128] = 1'b1;
                                end
                                default: begin
                                    dumh[i] = '0;
                                    dumh[i + 128] = '0;
                                end
                            endcase
                        end
                        duml = 16'hFFFF;
                        precb = 2'b11;
                        adc_en1 = '0;
                        adc_en2 = '0;
                        qdac = 2'b11;
                        buf_write_en_1 = '0;
                        buf_write_en_2 = '0;
                    end else if (exec_cnt == 4'd6) begin
                        dumh = '0;
                        duml = '0;
                        precb = 2'b11;
                        adc_en1 = '0;
                        adc_en2 = '0;
                        qdac = 2'b11;
                        buf_write_en_1 = '0;
                        buf_write_en_2 = '0;
                    end else if (exec_cnt == 4'd5) begin
                        dumh = '0;
                        duml = '0;
                        precb = 2'b11;
                        adc_en1 = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
                        adc_en2 = '0;
                        qdac = 2'b11;
                        buf_write_en_1 = 1'b1;
                        buf_write_en_2 = '0;
                    end else if (exec_cnt == 4'd4) begin
                        dumh = '0;
                        duml = '0;
                        precb = 2'b11;
                        adc_en1 = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
                        adc_en2 = '0;
                        qdac = '0;
                        buf_write_en_1 = 1'b1;
                        buf_write_en_2 = '0;
                    end else if (exec_cnt == 4'd3) begin
                        dumh = '0;
                        duml = '0;
                        precb = 2'b11;
                        adc_en1 = '0;
                        adc_en2 = '0;
                        qdac = '0;
                        buf_write_en_1 = '0;
                        buf_write_en_2 = '0;
                    end else if (exec_cnt == 4'd2 || exec_cnt == 4'd1) begin
                        dumh = '0;
                        duml = '0;
                        precb = 2'b11;
                        adc_en1 = '0;
                        adc_en2 = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
                        qdac = '0;
                        buf_write_en_1 = '0;
                        buf_write_en_2 = 1'b1;
                    end else begin
                        dumh = '0;
                        duml = '0;
                        precb = 2'b11;
                        adc_en1 = '0;
                        adc_en2 = '01;
                        qdac = 2'b11;
                        buf_write_en_1 = '0;
                        buf_write_en_2 = '0;
                    end
                end

                PIM_RBR: begin      
                    bl_opt = '0;
                    dumh_opt = '0;
                    csl = '0;
                    adc_en2 = '0;
                    buf_write_en_2 = '0;
                    qdac = 2'b11;
                    disc = '0;
                    rsel = 4'b0101;

                    if (exec_cnt == 4'd9 || exec_cnt == 4'd8 || exec_cnt == 4'd7) begin             
                        for (int unsigned i = 0; i < 8; i++) begin
                            if (i == col_b) begin
                                for (int unsigned j = 0; j < 16; j++) begin
                                    dumh[8 * j + i] = 1'b1;
                                    dumh[8 * j + i + 128] = 1'b1;
                                end
                            end else begin
                                for (int unsigned j = 0; j < 16; j++) begin
                                    dumh[8 * j + i] = '0;
                                    dumh[8 * j + i + 128] = '0;
                                end
                            end
                        end
                        duml = 16'hFFFF;
                        precb = '0;
                        adc_en1 = '0;
                        buf_write_en_1 = '0;
                    end else if (exec_cnt == 4'd6 || exec_cnt == 4'd5 || exec_cnt == 4'd4) begin
                        dumh = '0;
                        for (int unsigned i = 0; i < 16; i++) begin
                            case (input_data[i]) 
                                2'b00: begin
                                    dumh[8 * i + col_b] = '0;
                                    dumh[8 * i + col_b + 128] = '0;
                                end
                                2'b01: begin
                                    dumh[8 * i + col_b] = (exec_cnt == 4'd6);
                                    dumh[8 * i + col_b + 128] = (exec_cnt == 4'd6);
                                end
                                2'b10: begin
                                    dumh[8 * i + col_b] = (exec_cnt == 4'd6 || exec_cnt == 4'd5);
                                    dumh[8 * i + col_b + 128] = (exec_cnt == 4'd6 || exec_cnt == 4'd5);
                                end
                                2'b11: begin
                                    dumh[8 * i + col_b] = 1'b1;
                                    dumh[8 * i + col_b + 128] = 1'b1;
                                end
                                default: begin
                                    dumh[8 * i + col_b] = '0;
                                    dumh[8 * i + col_b + 128] = '0;
                                end
                            endcase
                        end
                        duml = 16'hFFFF;
                        precb = 2'b11;
                        adc_en1 = '0;
                        buf_write_en_1 = '0;
                    end else if (exec_cnt = 4'd3) begin
                        dumh = '0;
                        duml = '0;
                        precb = 2'b11;
                        adc_en1 = '0;
                        buf_write_en_1 = '0;
                    end else if (exec_cnt = 4'd2 || exec_cnt = 4'd1) begin
                        dumh = '0;
                        duml = '0;
                        precb = 2'b11;
                        adc_en1 = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
                        buf_write_en_1 = 1'b1;
                    end else begin
                        dumh = '0;
                        duml = '0;
                        precb = 2'b11;
                        adc_en1 = '0;
                        buf_write_en_1 = '0;
                    end
                end

                PIM_LOAD: begin
                end

                default: begin
                    bl_opt = '0;
                    dumh_opt = '0;
                    dumh = '0;
                    duml = '0;
                    csl = '0;
                    adc_en1 = '0;
                    adc_en2 = '0;
                    qdac = 2'b11;
                    disc = 2'b11;
                    precb = 2'b11;
                    rsel = '0;

                    buf_write_en_1 = '0;
                    buf_write_en_2 = '0;
                end
            endcase
        end else begin
            bl_opt = '0;
            dumh_opt = '0;
            dumh = '0;
            duml = '0;
            csl = '0;
            adc_en1 = '0;
            adc_en2 = '0;
            qdac = 2'b11;
            disc = 2'b11;
            precb = 2'b11;
            rsel = '0;

            buf_write_en_1 = '0;
            buf_write_en_2 = '0;
        end
    end
        

    always_ff @ (posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            BL_OPT_o <= '0;
            DUMH_OPT_o <= '0;
            DUMH_o <= '0;
            DUML_o <= '0;
            CSL_o <= '0;
            ADC_EN1_o <= '0;
            ADC_EN2_o <= '0;
            QDAC_o <= 2'b11;
            DISC_o <= 2'b11;
            PRECB_o <= 2'b11;
            RSEL_o <= '0;
            buf_write_en_1_o <= '0;
            buf_write_en_2_o <= '0;
        end else begin
            BL_OPT_o <= bl_opt;
            DUMH_OPT_o <= dumh_opt;
            DUMH_o <= dumh;
            DUML_o <= duml;
            CSL_o <= csl;
            ADC_EN1_o <= adc_en1;
            ADC_EN2_o <= adc_en2;
            QDAC_o <= qdac;
            DISC_o <= disc;
            PRECB_o <= precb;
            RSEL_o <= rsel;
            buf_write_en_1_o <= buf_write_en_1;
            buf_write_en_2_o <= buf_write_en_2;
        end
    end

endmodule