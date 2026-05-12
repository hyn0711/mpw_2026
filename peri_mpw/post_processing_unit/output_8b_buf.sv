// Raw output buffer 

module output_8b_buf (
    input logic             clk_i,
    input logic             rst_ni,

    input logic [255:0]     MOUT_i,
    input logic [255:0]     FOUT_i,

    // Control signal
    input logic             w_en_m_i,
    input logic             w_en_f_i,

    input logic             r_en_m_i,
    input logic             r_en_f_i,

    output logic [7:0]      MOUT_o [0:31],
    output logic [7:0]      FOUT_o [0:31]
);

    logic [7:0] buf_m [0:31];
    logic [7:0] buf_f [0:31];

    logic [7:0] mout [0:31];
    logic [7:0] fout [0:31];

    always_comb begin
        for (int i = 0; i < 32; i++) begin
            mout[i] = MOUT_i[8*i +: 8];
            fout[i] = FOUT_i[8*i +: 8];
        end
    end

    // Buffer write
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            for (int i = 0; i < 32; i++) begin
                buf_m[i] <= '0;
                buf_f[i] <= '0;
            end
        end else begin
            if (w_en_m_i) begin
                for (int i = 0; i < 32; i++) begin
                    buf_m[i] <= mout[i];
                    buf_f[i] <= buf_f[i];
                end
            end else if (w_en_f_i) begin
                for (int i = 0; i < 32; i++) begin
                    buf_m[i] <= buf_m[i];
                    buf_f[i] <= fout[i];
                end
            end else begin
                for (int i = 0; i < 32; i++) begin
                    buf_m[i] <= buf_m[i];
                    buf_f[i] <= buf_f[i];
                end
            end
        end
    end

    // Buffer read
    always_comb begin
        if (r_en_m_i) begin
            for (int i = 0; i < 32; i++) begin
                MOUT_o[i] = buf_m[i];
            end
        end else begin
            for (int i = 0; i < 32; i++) begin
                MOUT_o[i] = '0;
            end
        end
    end

    always_comb begin
        if (r_en_f_i) begin
            for (int i = 0; i < 32; i++) begin
                FOUT_o[i] = buf_f[i];
            end
        end else begin
            for (int i = 0; i < 32; i++) begin
                FOUT_o[i] = '0;
            end
        end
    end

endmodule