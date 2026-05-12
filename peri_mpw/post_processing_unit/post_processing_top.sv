module post_processing_top (
    input logic             clk_i,
    input logic             rst_ni,

    input logic [7:0]       MOUT_i[0:31],
    input logic [7:0]       FOUT_i[0:31],

    input logic             cycle_cnt_en_i,
    input logic [2:0]       pim_mode_i,

    output logic [19:0]     data_o[0:7]
);

    logic [19:0]    ppg_out [0:7];

    post_processing_group ppg_0(
        .clk_i(clk_i),
        .rst_ni(rst_ni),

        .MOUT_i(MOUT_i[0:3]),
        .FOUT_i(FOUT_i[0:3]),

        .cycle_cnt_en_i(cycle_cnt_en_i),
        .pim_mode_i(pim_mode_i),

        .data_o(ppg_out[0])
    );
    post_processing_group ppg_1(
        .clk_i(clk_i),
        .rst_ni(rst_ni),

        .MOUT_i(MOUT_i[4:7]),
        .FOUT_i(FOUT_i[4:7]),

        .cycle_cnt_en_i(cycle_cnt_en_i),
        .pim_mode_i(pim_mode_i),

        .data_o(ppg_out[1])
    );
    post_processing_group ppg_2(
        .clk_i(clk_i),
        .rst_ni(rst_ni),

        .MOUT_i(MOUT_i[8:11]),
        .FOUT_i(FOUT_i[8:11]),

        .cycle_cnt_en_i(cycle_cnt_en_i),
        .pim_mode_i(pim_mode_i),

        .data_o(ppg_out[2])
    );
    post_processing_group ppg_3(
        .clk_i(clk_i),
        .rst_ni(rst_ni),

        .MOUT_i(MOUT_i[12:15]),
        .FOUT_i(FOUT_i[12:15]),

        .cycle_cnt_en_i(cycle_cnt_en_i),
        .pim_mode_i(pim_mode_i),

        .data_o(ppg_out[3])
    );
    post_processing_group ppg_4(
        .clk_i(clk_i),
        .rst_ni(rst_ni),

        .MOUT_i(MOUT_i[16:19]),
        .FOUT_i(FOUT_i[16:19]),

        .cycle_cnt_en_i(cycle_cnt_en_i),
        .pim_mode_i(pim_mode_i),

        .data_o(ppg_out[4])
    );
    post_processing_group ppg_5(
        .clk_i(clk_i),
        .rst_ni(rst_ni),

        .MOUT_i(MOUT_i[20:23]),
        .FOUT_i(FOUT_i[20:23]),

        .cycle_cnt_en_i(cycle_cnt_en_i),
        .pim_mode_i(pim_mode_i),

        .data_o(ppg_out[5])
    );
    post_processing_group ppg_6(
        .clk_i(clk_i),
        .rst_ni(rst_ni),

        .MOUT_i(MOUT_i[24:27]),
        .FOUT_i(FOUT_i[24:27]),

        .cycle_cnt_en_i(cycle_cnt_en_i),
        .pim_mode_i(pim_mode_i),

        .data_o(ppg_out[6])
    );
    post_processing_group ppg_7(
        .clk_i(clk_i),
        .rst_ni(rst_ni),

        .MOUT_i(MOUT_i[28:31]),
        .FOUT_i(FOUT_i[28:31]),

        .cycle_cnt_en_i(cycle_cnt_en_i),
        .pim_mode_i(pim_mode_i),

        .data_o(ppg_out[7])
    );

    always_comb begin
        for (int i = 0; i < 8; i++) begin
            data_o[i] = ppg_out[i];
        end
    end

endmodule