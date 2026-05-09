module encoder (
    input logic [2:0]   pim_mode_i,

    input logic [7:0]   MOUT_i,
    input logic [7:0]   FOUT_i,

    output logic [6:0]  enc_o
);

    localparam PIM_PARALLEL = 3'b101;
    localparam PIM_RBR = 3'b110;

    // RBR mode
    logic [3:0] rbr_enc_out;

    rbr_encoder r_e(
        .data_i(MOUT_i),
        .data_o(rbr_enc_out)
    );

    // Parallel mode
    logic [3:0] parallel_enc_out_1;
    logic [3:0] parallel_enc_out_2;

    parallel_encoder p_e1(
        .data_i(MOUT_i),
        .data_o(parallel_enc_out_1)
    );
    parallel_encoder p_e2(
        .data_i(FOUT_i),
        .data_o(parallel_enc_out_2)
    );

    
    // Encoder output
    always_comb begin
        if (pim_mode_i == PIM_PARALLEL) begin
            enc_o = 8 * parallel_enc_out_1 + parallel_enc_out_2;
        end else if (pim_mode_i == PIM_RBR) begin
            enc_o = rbr_enc_out;
        end else begin
            enc_o = '0;
        end
    end

endmodule