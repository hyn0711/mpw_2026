// Peri top 

module peri_top_mpw (
    input logic             CLK,
    input logic             RSTN,

    // RISC-V
    input logic [31:0]      ADDRESS_I,
    input logic [31:0]      DATA_I,

    output logic [31:0]     DATA_O,

    // PIM
    input logic [255:0]     MOUT_I,
    input logic [255:0]     FOUT_I,

    // PIM A
    output logic [7:0]      A_DUMH_OPT_O,
    output logic [63:0]     A_DUMH_O,
    output logic [63:0]     A_ADC_EN1_O,
    output logic [63:0]     A_ADC_EN2_O,
    output logic [7:0]      A_DUML_O,
    output logic [255:0]    A_MODE_O,
    output logic [127:0]    A_WL_SEL_O,
    output logic [127:0]    A_VPASS_EN_O,
    output logic [1:0]      A_PRECB_O,
    output logic [1:0]      A_DISC_O,
    output logic [1:0]      A_QDAC_O,
    output logic [1:0]      A_CSL_O,
    output logic [31:0]     A_BL_OPT_O,
    output logic [15:0]     A_RSEL_O,
    output logic [63:0]     A_CSEL_O,

    // PIM B
    output logic [7:0]      B_DUMH_OPT_O,
    output logic [63:0]     B_DUMH_O,
    output logic [63:0]     B_ADC_EN1_O,
    output logic [63:0]     B_ADC_EN2_O,
    output logic [7:0]      B_DUML_O,
    output logic [255:0]    B_MODE_O,
    output logic [127:0]    B_WL_SEL_O,
    output logic [127:0]    B_VPASS_EN_O,
    output logic [1:0]      B_PRECB_O,
    output logic [1:0]      B_DISC_O,
    output logic [1:0]      B_QDAC_O,
    output logic [1:0]      B_CSL_O,
    output logic [31:0]     B_BL_OPT_O,
    output logic [15:0]     B_RSEL_O,
    output logic [63:0]     B_CSEL_O
);

    // Peri controller signal 
    logic pim_en;
    logic [2:0] pim_mode;
    logic [3:0] exec_cnt;
    logic [6:0] row_addr7;
    logic [4:0] col_addr5;

    logic [31:0] input_data_buf_in;
    logic [3:0] data_rx_cnt;
    logic in_buf_write, in_buf_read;

    // Row driver -> Output buffer
    logic buf_write_en_1, buf_write_en_2;

    // Controller -> Output buffer

    logic buf8_r_en;
    logic cycle_shift_en;
    logic buf32_w_en, buf32_r_en;
    logic [4:0] buf8_cnt;
    logic [3:0] buf32_cnt;

    logic [7:0] mout_8b [0:31];
    logic [7:0] fout_8b [0:31];

    logic [31:0] output_32b [0:7];

    logic [19:0] post_processing_out [0:7];

    logic [31:0] buf_mux_out;



    peri_controller_v2 p_c (
        .clk_i(CLK),
        .rst_ni(RSTN),

        // RISC-V
        .address_i(ADDRESS_I),
        .data_i(DATA_I),

        .data_o(DATA_O),

        // eFlash row driver
        .pim_en_o(pim_en),
        .pim_mode_o(pim_mode),
        .exec_cnt_o(exec_cnt),

        .row_addr7_o(row_addr7),
        .col_addr5_o(col_addr5),

        // input buffer
        .in_buf_w_en_o(in_buf_write),
        .in_buf_r_en_o(in_buf_read),
        .input_data_o(input_data_buf_in),
        .data_rx_cnt_o(data_rx_cnt),

        // output buffer
        .out_buf8_r_en_o(buf8_r_en),
        .cycle_shift_en_o(cycle_shift_en),
        .out_buf32_w_en_o(buf32_w_en),
        .out_buf32_r_en_o(buf32_r_en),
        .out_buf8_cnt_o(buf8_cnt),
        .out_buf32_cnt_o(buf32_cnt),

        .out_buf_data_i(buf_mux_out)
    );

    eFlash_driver_T ed_t(
        .clk_i(CLK),
        .rst_ni(RSTN),

        .pim_en_i(pim_en),
        .pim_mode_i(pim_mode),
        .exec_cnt_i(exec_cnt),

        .row_addr7_i(row_addr7),
        .col_addr5_i(col_addr5),

        .MODE_o({B_MODE_O, A_MODE_O}),  
        .WL_SEL_o({B_WL_SEL_O, A_WL_SEL_O}),
        .VPASS_EN_o({B_VPASS_EN_O, A_VPASS_EN_O}),
        .BL_OPT_o({B_BL_OPT_O[15:0], A_BL_OPT_O[15:0]}),
        .CSL_o({B_CSL_O[0], A_CSL_O[0]}),
        .QDAC_o({B_QDAC_O[0], A_QDAC_O[0]}),
        .DISC_o({B_DISC_O[0], A_DISC_O[0]}),
        .PRECB_o({B_PRECB_O[0], A_PRECB_O[0]})
    );   

    eFlash_driver_U ed_u(
        .clk_i(CLK),
        .rst_ni(RSTN),

        .pim_en_i(pim_en),
        .pim_mode_i(pim_mode),
        .exec_cnt_i(exec_cnt),

        .row_addr7_i(row_addr7),    // 0 ~ 127
        .col_addr5_i(col_addr5),    // 0 ~ 31

        .input_data_i(input_data_buf_in),
        .data_cnt_i(data_rx_cnt),

        .in_buf_write_i(in_buf_write),
        .in_buf_read_i(in_buf_read),

        .BL_OPT_o({B_BL_OPT_O[31:16], A_BL_OPT_O[31:16]}),
        .DUMH_OPT_o({B_DUMH_OPT_O, A_DUMH_OPT_O}),
        .DUMH_o({B_DUMH_O, A_DUMH_O}),
        .DUML_o({B_DUML_O, A_DUML_O}),
        .CSL_o({B_CSL_O[1], A_CSL_O[1]}),
        .ADC_EN1_o({B_ADC_EN1_O, A_ADC_EN1_O}),
        .ADC_EN2_o({B_ADC_EN2_O, A_ADC_EN2_O}),
        .QDAC_o({B_QDAC_O[1], A_QDAC_O[1]}),
        .DISC_o({B_DISC_O[1], A_DISC_O[1]}),
        .PRECB_o({B_PRECB_O[1], A_PRECB_O[1]}),
        .RSEL_o({B_RSEL_O, A_RSEL_O}),
        .CSEL_o({B_CSEL_O, A_CSEL_O}),

        .buf_write_en_1_o(buf_write_en_1),
        .buf_write_en_2_o(buf_write_en_2)
    );
    

    output_8b_buf buf_8(
        .clk_i(CLK),
        .rst_ni(RSTN),

        .MOUT_i(MOUT_I),
        .FOUT_i(FOUT_I),

        .w_en_m_i(buf_write_en_1),
        .w_en_f_i(buf_write_en_2),

        .r_en_m_i(buf8_r_en),
        .r_en_f_i(buf8_r_en),

        .MOUT_o(mout_8b),
        .FOUT_o(fout_8b)
    );

    post_processing_top ppt(
        .clk_i(CLK),
        .rst_ni(RSTN),

        .MOUT_i(mout_8b),
        .FOUT_i(fout_8b),

        .cycle_cnt_en_i(cycle_shift_en),
        .pim_mode_i(pim_mode),

        .data_o(post_processing_out)
    );

    output_32b_buf buf_32(
        .clk_i(CLK),
        .rst_ni(RSTN),

        .w_en_i(buf32_w_en),
        .r_en_i(buf32_r_en),

        .buf32_cnt_i(buf32_cnt),

        .cycle_shift_data_i(post_processing_out),

        .data_o(output_32b)
    );
    
    output_buf_mux b_m(
        .pim_mode_i(pim_mode),
        .buf8_cnt_i(buf8_cnt),
        .buf32_cnt_i(buf32_cnt),

        .buf8_MOUT_i(mout_8b),
        .buf8_FOUT_i(fout_8b),

        .buf32_data_i(output_32b),

        .mux_data_o(buf_mux_out)
    );
    


endmodule