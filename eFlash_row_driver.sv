
// eFlash row wise driver

module eFlash_row_driver (
    input logic                 clk_i,
    input logic                 rst_ni,

    // eFlash signal control
    input logic                 pim_en_i,
    input logic [2:0]           pim_mode_i,
    input logic [3:0]           exec_cnt_i,

    // address
    input logic [6:0]           row_addr7_i,
    input logic [8:0]           col_addr9_i,

    // HVS signal
    output logic [1:0]          MODE_o,
    output logic [127:0]        WL_SEL_o,
    output logic [127:0]        VPASS_EN_o,

    // eFLASH signal
    output logic [7:0]          DUML_o,
    output logic [7:0]          CSL_o,
    output logic [31:0]         BSEL_o,
    output logic [7:0]          CSEL_o,
    output logic                ADC_EN1_o,
    output logic                ADC_EN2_o,
    output logic                QDAC_o,
    output logic [1:0]          RSEL_o,

    // Output buffer 
    //output logic                buf_write_en_0_o,
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
    logic [1:0]         mode;
    logic [127:0]       wl_sel;
    logic [127:0]       vpass_en;

    logic [7:0] duml;
    logic [7:0] csl, csel;
    logic [31:0] bsel;
    logic adc_en1, adc_en2;
    logic qdac;
    logic [1:0] rsel;

    logic [3:0] row_a;
    logic [1:0] col_b;
    logic [2:0] row_c;

    assign row_a = row_addr7_i[3:0];
    assign col_b = col_addr9_i[1:0];
    assign row_c = row_addr7_i[6:4];

    logic pim_en;
    logic [2:0] pim_mode;
    logic [3:0] exec_cnt;

    assign pim_en = pim_en_i;
    assign pim_mode = pim_mode_i;
    assign exec_cnt = exec_cnt_i;

    logic buf_write_en_1, buf_write_en_2;

 
// --------------------------- eFlash signal ---------------------------
    always_comb begin
        mode = '0;
        wl_sel = '0;
        vpass_en = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
        duml = '0;
        csl = '0;
        bsel = '0;
        csel = '0;
        adc_en1 = '0;
        adc_en2 = '0;
        qdac = 1'b1;
        rsel = '0;

        //buf_write_en_0 = '0;
        buf_write_en_1 = '0;
        buf_write_en_2 = '0;

        if (pim_en) begin
            case (pim_mode)
                PIM_ERASE: begin        // Erase mode
                    mode = 2'b00;

                    //buf_write_en_0 = '0;
                    buf_write_en_1 = '0;
                    buf_write_en_2 = '0;

                    for (int unsigned i = 0; i < 128; i++) begin
                        vpass_en[i] = 1'b1;
                        if (i == row_addr7_i) begin
                            wl_sel[i] = 1'b1;
                        end else begin
                            wl_sel[i] = 1'b0;
                        end
                    end
                    duml = '0;
                    csl = '0;
                    bsel = 32'hFFFF_FFFF;
                    adc_en1 = '0;
                    adc_en2 = '0;
                    qdac = 1'b1;
                    rsel = 2'b00;
                    for (int unsigned i = 0; i < 8; i++) begin
                        if (i == (row_addr7_i/16)) begin
                            csel[i] = 1'b1;
                        end else begin
                            csel[i] = 1'b0;
                        end
                    end
                end
                PIM_PROGRAM: begin      // Program mode
                    mode = 2'b01;

                    //buf_write_en_0 = '0;
                    buf_write_en_1 = '0;
                    buf_write_en_2 = '0;

                    for (int unsigned i = 0; i < 128; i++) begin
                        if (i == row_addr7_i) begin
                            wl_sel[i] = 1'b1;
                            vpass_en[i] = 1'b1;
                        end else begin
                            wl_sel[i] = 1'b0;
                            vpass_en[i] = 1'b0;
                        end
                    end
                    duml = '0;
                    adc_en1 = 1'b0;
                    adc_en2 = 1'b0;
                    qdac = 1'b1;
                    rsel = 2'b00;
                    for (int unsigned j = 0; j < 4; j++) begin
                        if (j == (col_addr9_i%4)) begin
                            for (int unsigned k = 0; k < 8; k++) begin
                                bsel[4*k+j] = 1'b1;
                            end
                        end else begin
                            for (int unsigned k = 0; k < 8; k++) begin
                                bsel[4*k+j] = 1'b0;
                            end
                        end
                    end
                    for (int unsigned k = 0; k < 8; k++) begin
                        if (k == (row_addr7_i/16)) begin
                            csl[k] = 1'b1;
                            csel[k] = 1'b1;
                        end else begin
                            csl[k] = 1'b0;
                            csel[k] = 1'b0;
                        end
                    end
                end
                PIM_READ: begin
                    mode = 2'b10;

                    //buf_write_en_1 = '0;
                    buf_write_en_2 = '0;

                    for (int unsigned i = 0; i < 128; i++) begin
                        if (i == row_addr7_i) begin
                            wl_sel[i] = 1'b1;
                            vpass_en[i] = 1'b1;
                        end else begin
                            wl_sel[i] = 1'b0;
                            vpass_en[i] = 1'b0;
                        end
                    end
                    rsel = 2'b01;

                    if (exec_cnt == 4'd2 || exec_cnt == 4'd1) begin
                        buf_write_en_1 = 1'b1;
                    end else begin
                        buf_write_en_1 = '0;
                    end

                    if (exec_cnt == 4'd9 || exec_cnt == 4'd8 || exec_cnt == 4'd7) begin
                        csl = '0;
                        csel = '0;
                        adc_en1 = '0;
                        adc_en2 = '0;
                        qdac = 1'b1;
                        for (int unsigned i = 0; i < 8; i++) begin
                            if (i == row_c) begin
                                duml[i] = 1'b1;
                            end else begin
                                duml[i] = 1'b0;
                            end
                        end
                        for (int unsigned j = 0; j < 4; j++) begin
                            if (j == col_b) begin
                                for (int unsigned k = 0; k < 8; k++) begin
                                    bsel[4 * k + j] = 1'b1;
                                end
                            end else begin
                                for (int unsigned k = 0; k < 8; k++) begin
                                    bsel[4 * k + j] = 1'b0;
                                end
                            end
                        end
                    end else if (exec_cnt == 4'd6) begin
                        csl = '0;
                        csel = '0;
                        adc_en1 = '0;
                        adc_en2 = '0;
                        qdac = 1'b1;
                        for (int unsigned i = 0; i < 8; i++) begin
                            if (i == row_c) begin
                                duml[i] = 1'b1;
                            end else begin
                                duml[i] = 1'b0;
                            end
                        end
                        for (int unsigned j = 0; j < 4; j++) begin
                            if (j == col_b) begin
                                for (int unsigned k = 0; k < 8; k++) begin
                                    bsel[4 * k + j] = 1'b1;
                                end
                            end else begin
                                for (int unsigned k = 0; k < 8; k++) begin
                                    bsel[4 * k + j] = 1'b0;
                                end
                            end
                        end
                    end else if (exec_cnt == 4'd5 || exec_cnt == 4'd4) begin
                        duml = '0;
                        csl = '0;
                        csel = '0;
                        adc_en1 = '0;
                        adc_en2 = '0;
                        qdac = 1'b1;
                        for (int unsigned i = 0; i < 4; i++) begin
                            if (i == col_b) begin
                                for (int unsigned j = 0; j < 8; j++) begin
                                    bsel[4 * j + i] = 1'b1;
                                end
                            end else begin
                                for (int unsigned j = 0; j < 8; j++) begin
                                    bsel[4 * j + i] = 1'b0;
                                end
                            end
                        end
                    end else if (exec_cnt == 4'd3) begin
                        duml = '0;
                        csl = '0;
                        bsel = '0;
                        adc_en1 = '0;
                        adc_en2 = '0;
                        qdac = 1'b1;
                        for (int unsigned i = 0; i < 8; i++) begin
                            if (i == row_c) begin
                                csel[i] = 1'b1;
                            end else begin
                                csel[i] = 1'b0;
                            end 
                        end
                    end else if (exec_cnt == 4'd2 || exec_cnt == 4'd1) begin
                        duml = '0;
                        csl = '0;
                        bsel = '0;
                        adc_en1 = 1'b1;
                        adc_en2 = '0;
                        qdac = 1'b1;
                        for (int unsigned i = 0; i < 8; i++) begin
                            if (i == row_c) begin
                                csel[i] = 1'b1;
                            end else begin
                                csel[i] = 1'b0;
                            end 
                        end
                    end else begin
                        duml = '0;
                        csl = '0;
                        bsel = '0;
                        csel = '0;
                        adc_en1 = '0;
                        adc_en2 = '0;
                        qdac = 1'b1;
                    end
                end
                PIM_PARALLEL: begin     // Parallel mode
                    mode = 2'b10;
                    for (int unsigned i = 0; i < 128; i++) begin
                        if ((i - row_a) % 16 == 0) begin
                            wl_sel[i] = 1'b1;
                            vpass_en[i] = 1'b1;
                        end else begin
                            wl_sel[i] = 1'b0;
                            vpass_en[i] = 1'b0;
                        end
                    end
                    rsel = 2'b10;
                    //buf_write_en_0 = '0;

                    if (exec_cnt == 4'd5 || exec_cnt == 4'd4) begin
                        buf_write_en_1 = 1'b1;
                    end else begin
                        buf_write_en_1 = '0;
                    end

                    if (exec_cnt == 4'd2 || exec_cnt == 4'd1) begin
                        buf_write_en_2 = 1'b1;
                    end else begin
                        buf_write_en_2 = '0;
                    end 

                    if (exec_cnt == 4'd12 || exec_cnt == 4'd11 || exec_cnt == 4'd10) begin
                        duml = 8'hFF;
                        csl = '0;
                        csel = '0;
                        adc_en1 = '0;
                        adc_en2 = '0;
                        qdac = 1'b1;
                        for (int unsigned i = 0; i < 4; i++) begin
                            if (i == col_b) begin
                                for (int unsigned j = 0; j < 8; j++) begin
                                    bsel[4 * j + i] = 1'b1;
                                end
                            end else begin
                                for (int unsigned j = 0; j < 8; j++) begin
                                    bsel[4 * j + i] = 1'b0;
                                end
                            end
                        end
                    end else if (exec_cnt == 4'd9 || exec_cnt == 4'd8 || exec_cnt == 4'd7) begin
                        duml = 8'hFF;
                        csl = '0;
                        csel = '0;
                        adc_en1 = '0;
                        adc_en2 = '0;
                        qdac = 1'b1;                
                        for (int unsigned i = 0; i < 4; i++) begin
                            if (i == col_b) begin
                                for (int unsigned j = 0; j < 8; j++) begin
                                    bsel[4 * j + i] = 1'b1;
                                end
                            end else begin
                                for (int unsigned j = 0; j < 8; j++) begin
                                    bsel[4 * j + i] = 1'b0;
                                end
                            end
                        end
                    end else if (exec_cnt == 4'd6) begin
                        duml = '0;
                        csl = '0;
                        bsel = '0;
                        csel = 8'hFF;
                        adc_en1 = '0;
                        adc_en2 = '0;
                        qdac = 1'b1;
                    end else if (exec_cnt == 4'd5) begin
                        duml = '0;
                        csl = '0;
                        bsel = '0;
                        csel = 8'hFF;
                        adc_en1 = 1'b1;
                        adc_en2 = 1'b0;
                        qdac = 1'b1;
                    end else if (exec_cnt == 4'd4) begin
                        duml = '0;
                        csl = '0;
                        bsel = '0;
                        csel = 8'hFF;
                        adc_en1 = 1'b1;
                        adc_en2 = '0;
                        qdac = '0;
                    end else if (exec_cnt == 4'd3) begin
                        duml = '0;
                        csl = '0;
                        bsel = '0;
                        csel = 8'hFF;
                        adc_en1 = '0;
                        adc_en2 = '0;
                        qdac = '0;
                    end else if (exec_cnt == 4'd2 || exec_cnt == 4'd1) begin
                        duml = '0;
                        csl = '0;
                        bsel = '0;
                        csel = 8'hFF;
                        adc_en1 = '0;
                        adc_en2 = 1'b1;
                        qdac = '0;
                    end else begin
                        duml = '0;
                        csl = '0;
                        bsel = '0;
                        csel = '0;
                        adc_en1 = '0;
                        adc_en2 = '0;
                        qdac = 1'b1;
                    end
                end
                PIM_RBR: begin      // Row by row mode
                    mode = 2'b10;
                    for (int unsigned i = 0; i < 128; i++) begin
                        if (i == row_addr7_i) begin
                            wl_sel[i] = 1'b1;
                            vpass_en[i] = 1'b1;
                        end else begin
                            wl_sel[i] = 1'b0;
                            vpass_en[i] = 1'b0;
                        end
                    end
                    rsel = 2'b01;
                    //buf_write_en_0 = '0;
                    buf_write_en_2 = '0;
                    if (exec_cnt == 4'd2 || exec_cnt == 4'd1) begin
                        buf_write_en_1 = 1'b1;
                    end else begin
                        buf_write_en_1 = '0;
                    end

                    if (exec_cnt == 4'd9 || exec_cnt == 4'd8 || exec_cnt == 4'd7) begin
                        csl = '0;
                        csel = '0;
                        adc_en1 = '0;
                        adc_en2 = '0;
                        qdac = 1'b1;               
                        for (int unsigned i = 0; i < 8; i++) begin
                            if (i == row_c) begin
                                duml[i] = 1'b1;
                            end else begin
                                duml[i] = 1'b0;
                            end
                        end
                        for (int unsigned j = 0; j < 4; j++) begin
                            if (j == col_b) begin
                                for (int unsigned k = 0; k < 8; k++) begin
                                    bsel[4 * k + j] = 1'b1;
                                end
                            end else begin
                                for (int unsigned k = 0; k < 8; k++) begin
                                    bsel[4 * k + j] = 1'b0;
                                end
                            end
                        end
                    end else if (exec_cnt == 4'd6 || exec_cnt == 4'd5 || exec_cnt == 4'd4) begin
                        csl = '0;
                        csel = '0;
                        adc_en1 = '0;
                        adc_en2 = '0;
                        qdac = 1'b1;
                        for (int unsigned i = 0; i < 8; i++) begin
                            if (i == row_c) begin
                                duml[i] = 1'b1;
                            end else begin
                                duml[i] = 1'b0;
                            end
                        end
                        for (int unsigned j = 0; j < 4; j++) begin
                            if (j == col_b) begin
                                for (int unsigned k = 0; k < 8; k++) begin
                                    bsel[4 * k + j] = 1'b1;
                                end
                            end else begin
                                for (int unsigned k = 0; k < 8; k++) begin
                                    bsel[4 * k + j] = 1'b0;
                                end
                            end
                        end               
                    end else if (exec_cnt == 4'd3) begin
                        duml = '0;
                        csl = '0;
                        bsel = '0;
                        adc_en1 = '0;
                        adc_en2 = '0;
                        qdac = 1'b1;
                        for (int unsigned i = 0; i < 8; i++) begin
                            if (i == row_c) begin
                                csel[i] = 1'b1;
                            end else begin
                                csel[i] = 1'b0;
                            end
                        end
                    end else if (exec_cnt == 4'd2 || exec_cnt == 4'd1) begin
                        duml = '0;
                        csl = '0;
                        bsel = '0;               
                        adc_en1 = 1'b1;
                        adc_en2 = '0;
                        qdac = 1'b1;
                        for (int unsigned i = 0; i < 8; i++) begin
                            if (i == row_c) begin
                                csel[i] = 1'b1;
                            end else begin
                                csel[i] = 1'b0;
                            end
                        end
                    end else begin
                        duml = '0;
                        csl = '0;
                        bsel = '0;
                        csel = '0;
                        adc_en1 = '0;
                        adc_en2 = '0;
                        qdac = 1'b1;
                        //buf_write_en_0 = '0;
                        buf_write_en_1 = '0;
                        buf_write_en_2 = '0;
                    end
                end
                PIM_LOAD: begin
                end
                default: begin
                    mode = '0;
                    wl_sel = '0;
                    vpass_en = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;

                    duml = '0;
                    csl = '0;
                    bsel = '0;
                    csel = '0;
                    adc_en1 = '0;
                    adc_en2 = '0;
                    qdac = 1'b1;
                    rsel = '0;

                    //buf_write_en_0 = '0;
                    buf_write_en_1 = '0;
                    buf_write_en_2 = '0;
                end
            endcase
        end else begin
            mode = '0;
            wl_sel = '0;
            vpass_en = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
            duml = '0;
            csl = '0;
            bsel = '0;
            csel = '0;
            adc_en1 = '0;
            adc_en2 = '0;
            qdac = 1'b1;
            rsel = '0;

            buf_write_en_1 = '0;
            buf_write_en_2 = '0;
        end
    end
        

    always_ff @ (posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            MODE_o <= '0;
            WL_SEL_o <= '0;
            VPASS_EN_o <= 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
            DUML_o <= '0;
            CSL_o <= '0;
            BSEL_o <= '0;
            CSEL_o <= '0;
            ADC_EN1_o <= '0;
            ADC_EN2_o <= '0;
            QDAC_o <= 1'b1;
            RSEL_o <= '0;

            //buf_write_en_0_o <= '0;
            buf_write_en_1_o <= '0;
            buf_write_en_2_o <= '0;
        end else begin
            MODE_o <= mode;
            WL_SEL_o <= wl_sel;
            VPASS_EN_o <= vpass_en;
            DUML_o <= duml;
            CSL_o <= csl;
            BSEL_o <= bsel;
            CSEL_o <= csel;
            ADC_EN1_o <= adc_en1;
            ADC_EN2_o <= adc_en2;
            QDAC_o <= qdac;
            RSEL_o <= rsel;

            //buf_write_en_0_o <= buf_write_en_0;
            buf_write_en_1_o <= buf_write_en_1;
            buf_write_en_2_o <= buf_write_en_2;
        end
    end


endmodule