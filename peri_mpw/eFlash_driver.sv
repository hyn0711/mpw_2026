module eFlash_driver (
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

    output logic [7:0]          A_DUMH_OPT_o,
    output logic [63:0]         A_DUMH_o,
    output logic [63:0]         A_ADC_EN1_o,
    output logic [63:0]         A_ADC_EN2_o,
    output logic [7:0]          A_DUML_o,
    output logic [255:0]        A_MODE_o,
    output logic [127:0]        A_WL_SEL_o,
    output logic [127:0]        A_VPASS_EN_o,
    output logic [1:0]          A_PRECB_o,
    output logic [1:0]          A_DISC_o,
    output logic [1:0]          A_QDAC_o,
    output logic [1:0]          A_CSL_o,
    output logic [31:0]         A_BL_OPT_o,
    output logic [15:0]         A_RSEL_o,

    // PIM B
    output logic [7:0]          B_DUMH_OPT_o,
    output logic [63:0]         B_DUMH_o,
    output logic [63:0]         B_ADC_EN1_o,
    output logic [63:0]         B_ADC_EN2_o,
    output logic [7:0]          B_DUML_o,
    output logic [255:0]        B_MODE_o,
    output logic [127:0]        B_WL_SEL_o,
    output logic [127:0]        B_VPASS_EN_o,
    output logic [1:0]          B_PRECB_o,
    output logic [1:0]          B_DISC_o,
    output logic [1:0]          B_QDAC_o,
    output logic [1:0]          B_CSL_o,
    output logic [31:0]         B_BL_OPT_o,
    output logic [15:0]         B_RSEL_o,

    // Output buffer (8b buffer)
    output logic                buf_write_en_1_o,
    output logic                buf_write_en_2_o
);

    // eFlash mode
    localparam PIM_ERASE = 3'b001;      // PIM_ERASE
    localparam PIM_PROGRAM = 3'b010;    // PIM_PROGRAM
    localparam PIM_READ = 3'b011;       // PIM_READ
    localparam PIM_DEBUG = 3'b100;      // PIM_DEBUG
    localparam PIM_PARALLEL = 3'b101;   // PIM_PARALLEL
    localparam PIM_RBR = 3'b110;        // PIM_RBR
    localparam PIM_LOAD = 3'b111;       // PIM_LOAD

    logic [3:0] row_a;
    logic [2:0] col_b;
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

    
endmodule