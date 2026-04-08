// Peri top 
// not include output buffer


module peri_top_mpw (
    input logic             CLK,
    input logic             RSTN,

    // RISC-V
    input logic [31:0]      ADDRESS_I,
    input logic [31:0]      DATA_I,

    output logic [31:0]     DATA_O,

    // PIM
    input logic [255:0]     EFLASH_OUTPUT_1_I,


    // Row wise signal
    output logic [1:0]      MODE_O,
    output logic [127:0]    WL_SEL_O,
    output logic [127:0]    VPASS_EN_O,

    output logic [7:0]      DUML_O,
    output logic [7:0]      CSL_O,
    output logic [31:0]     BSEL_O,
    output logic [7:0]      CSEL_O,
    output logic            ADC_EN1_O,
    output logic            ADC_EN2_O,
    output logic            QDAC_O,
    output logic [1:0]      RSEL_O,

    // Col wise signal
    output logic [63:0]    DUMH_O,
    output logic [31:0]    PRECB_O,
    output logic [31:0]    DISC_O
);

    // Peri controller signal 
    logic pim_en;
    logic [2:0] pim_mode;
    logic [3:0] exec_cnt;
    logic [6:0] row_addr7;
    logic [8:0] col_addr9;

    logic [31:0] input_data_buf_in;
    logic [3:0] data_rx_cnt;
    logic in_buf_write, in_buf_read;

    // Row driver -> Output buffer
    logic buf_write_en_0, buf_write_en_1, buf_write_en_2;

    // Controller -> Output buffer
    logic load_en;
    logic [5:0] load_cnt;

    logic [31:0] out_buf_output;



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
        .col_addr9_o(col_addr9),

        // input buffer
        .in_buf_w_en_o(in_buf_write),
        .in_buf_r_en_o(in_buf_read),
        .input_data_o(input_data_buf_in),
        .data_rx_cnt_o(data_rx_cnt),

        // output buffer
        .out_buf_r_en_o(load_en),
        .out_buf_cnt_o(load_cnt),

        .out_buf_data_i(out_buf_output)
    );


    eFlash_row_driver r_d (
        .clk_i(CLK),
        .rst_ni(RSTN),

    // eFlash signal control
        .pim_en_i(pim_en),
        .pim_mode_i(pim_mode),
        .exec_cnt_i(exec_cnt),

    // address
        .row_addr7_i(row_addr7),
        .col_addr9_i(col_addr9),

        //eFlash signal 
        .MODE_o(MODE_O),
        .WL_SEL_o(WL_SEL_O),
        .VPASS_EN_o(VPASS_EN_O),

        .DUML_o(DUML_O),
        .CSL_o(CSL_O),
        .BSEL_o(BSEL_O),
        .CSEL_o(CSEL_O),
        .ADC_EN1_o(ADC_EN1_O),
        .ADC_EN2_o(ADC_EN2_O),
        .QDAC_o(QDAC_O),
        .RSEL_o(RSEL_O),

        //.buf_write_en_0_o(buf_write_en_0),
        .buf_write_en_1_o(buf_write_en_1),
        .buf_write_en_2_o(buf_write_en_2)
);

    eFlash_col_driver c_d (
        .clk_i(CLK),
        .rst_ni(RSTN),

        // eFlash signal control
        .pim_en_i(pim_en),
        .pim_mode_i(pim_mode),
        .exec_cnt_i(exec_cnt),

        .row_addr7_i(row_addr7),
        .col_addr9_i(col_addr9),

        .input_data_i(input_data_buf_in),
        .data_cnt_i(data_rx_cnt),

        .in_buf_write_i(in_buf_write),
        .in_buf_read_i(in_buf_read),

        .DUMH_o(DUMH_O),
        .PRECB_o(PRECB_O),
        .DISC_o(DISC_O)
    );

    
    output_buffer o_b(
        .clk_i(CLK),
        .rst_ni(RSTN),

        .pim_output_i(EFLASH_OUTPUT_1_I),

        // Control Signal
        .buf_w_en_1_i(buf_write_en_1),
        .buf_w_en_2_i(buf_write_en_2),

        .buf_r_en_i(load_en),
        .buf_cnt_i(load_cnt),

        .out_buf_data_o(out_buf_output)   
    );
    


endmodule