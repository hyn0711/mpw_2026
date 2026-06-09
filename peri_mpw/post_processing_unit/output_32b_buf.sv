module output_32b_buf (
    input logic             clk_i,
    input logic             rst_ni,

    input logic             w_en_i,
    input logic             r_en_i,

    input logic [3:0]       buf32_cnt_i,

    input logic [19:0]      cycle_shift_data_i[0:7],

    output logic [31:0]     data_o[0:7]

    // input logic [3:0]       r_cnt_i,

    // output logic [31:0]     data_o
);

    logic [31:0]    data_buf [0:7];

    // Write buffer
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            for (int i = 0; i < 8; i++) begin
                data_buf[i] <= '0;
            end
        end else begin
            if (w_en_i) begin
                for (int i = 0; i < 8; i++) begin
                    data_buf[i] <= data_buf[i] + {{12{1'b0}}, cycle_shift_data_i[i]};
                end
            end else if (r_en_i && buf32_cnt_i == 4'd7) begin
                for (int i = 0; i < 8; i++) begin
                    data_buf[i] <= '0;
                end
            end else begin
                for (int i = 0; i < 8; i++) begin
                    data_buf[i] <= data_buf[i];
                end
            end
        end
    end

    // Read buffer
    always_comb begin
        if (r_en_i) begin
            for (int i = 0; i < 8; i++) begin
                data_o[i] = data_buf[i];
            end
        end else begin
            for (int i = 0; i < 8; i++) begin
                data_o[i] = '0;
            end
        end
    end

    // // Read buffer
    // always_comb begin
    //     if (r_en_i) begin
    //         if (r_cnt_i == 3'd0) begin
    //             data_o = data_buf[0];
    //         end else if (r_cnt_i == 3'd1) begin
    //             data_o = data_buf[1];
    //         end else if (r_cnt_i == 3'd2) begin
    //             data_o = data_buf[2];
    //         end else if (r_cnt_i == 3'd3) begin
    //             data_o = data_buf[3];
    //         end else if (r_cnt_i == 3'd4) begin
    //             data_o = data_buf[4];
    //         end else if (r_cnt_i == 3'd5) begin
    //             data_o = data_buf[5];
    //         end else if (r_cnt_i == 3'd6) begin
    //             data_o = data_buf[6];
    //         end else if (r_cnt_i == 3'd7) begin
    //             data_o = data_buf[7];
    //         end else begin
    //             data_o = '0;
    //         end
    //     end else begin
    //         data_o = '0;
    //     end
    // end

endmodule