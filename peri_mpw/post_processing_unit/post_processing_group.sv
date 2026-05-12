module post_processing_group (
    input logic             clk_i,
    input logic             rst_ni,

    input logic [7:0]       MOUT_i[0:3],
    input logic [7:0]       FOUT_i[0:3],

    input logic             cycle_cnt_en_i,
    input logic [2:0]       pim_mode_i,

    output logic [19:0]     data_o
);
    logic [6:0] enc_out[0:3];
    logic [13:0] bl_shift;

    logic [1:0] cycle_cnt;

    // Encoder
    encoder e_0(
        .pim_mode_i(pim_mode_i),
        .MOUT_i(MOUT_i[0]),
        .FOUT_i(FOUT_i[0]),
        .enc_o(enc_out[0])
    );
    encoder e_1(
        .pim_mode_i(pim_mode_i),
        .MOUT_i(MOUT_i[1]),
        .FOUT_i(FOUT_i[1]),
        .enc_o(enc_out[1])
    );
    encoder e_2(
        .pim_mode_i(pim_mode_i),
        .MOUT_i(MOUT_i[2]),
        .FOUT_i(FOUT_i[2]),
        .enc_o(enc_out[2])
    );
    encoder e_3(
        .pim_mode_i(pim_mode_i),
        .MOUT_i(MOUT_i[3]),
        .FOUT_i(FOUT_i[3]),
        .enc_o(enc_out[3])
    );

    // Bit-line group shifting
    bl_group_shifter bl_s(
        .data_i(enc_out),
        .data_o(bl_shift)
    );

    // Cycle shifting 
    cycle_shift_counter c_s_cnt(
        .clk_i(clk_i),
        .rst_ni(rst_ni),

        .cnt_en_i(cycle_cnt_en_i),
        .pim_mode_i(pim_mode_i),

        .cycle_count_o(cycle_cnt)
    );

    cycle_shifter c_s(
        .cycle_count_i(cycle_cnt),
        .data_i(bl_shift),

        .data_o(data_o)
    );



endmodule