
// Output buffer 

// 32 ADC * 8 bit output from eFlash PIM

// | ADC 0 | ADC 1 | ... | ADC 31 |
// 255        pim_output_i        0


module output_buffer (
    input logic                 clk_i,
    input logic                 rst_ni,

    input logic [255:0]         MOUT_i,
    input logic [255:0]         FOUT_i,

    // Control Signal
    input logic                 buf_w_en_1_i,
    input logic                 buf_w_en_2_i,

    input logic                 buf_r_en_i,
    input logic [5:0]           buf_cnt_i,

    output logic [31:0]         out_buf_data_o   
);

    logic [7:0]     buf_1 [0:31];
    logic [7:0]     buf_2 [0:31];

    logic [7:0]     pim_output [0:31];

    always_comb begin
        for (int i = 0; i < 32; i++) begin
            pim_output[i] = pim_output_i[255-8*i -: 8];
        end
    end


    // Buffer Write
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            for (int i = 0; i < 32; i++) begin
                buf_1[i] <= '0;
                buf_2[i] <= '0;
            end 
        end else begin
            if (buf_w_en_1_i) begin
                for (int i = 0; i < 32; i++) begin
                    buf_1[i] <= pim_output[i];
                    buf_2[i] <= buf_2[i];
                end
            end else if (buf_w_en_2_i) begin
                for (int i = 0; i < 32; i++) begin
                    buf_1[i] <= buf_1[i];
                    buf_2[i] <= pim_output[i];
                end
            end else begin
                for (int i = 0; i < 32; i++) begin
                    buf_1[i] <= buf_1[i];
                    buf_2[i] <= buf_2[i];
                end
            end
        end
    end

    // Buffer read
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            out_buf_data_o <= '0;
        end else begin
            if (buf_r_en_i) begin
                // Buffer 1
                if (buf_cnt_i == 6'd32) begin
                    out_buf_data_o <= {buf_1[0], buf_1[1], buf_1[2], buf_1[3]};
                end else if (buf_cnt_i == 6'd31) begin
                    out_buf_data_o <= {buf_1[4], buf_1[5], buf_1[6], buf_1[7]};
                end else if (buf_cnt_i == 6'd30) begin
                    out_buf_data_o <= {buf_1[8], buf_1[9], buf_1[10], buf_1[11]};
                end else if (buf_cnt_i == 6'd29) begin
                    out_buf_data_o <= {buf_1[12], buf_1[13], buf_1[14], buf_1[15]};
                end else if (buf_cnt_i == 6'd28) begin
                    out_buf_data_o <= {buf_1[16], buf_1[17], buf_1[18], buf_1[19]};
                end else if (buf_cnt_i == 6'd27) begin
                    out_buf_data_o <= {buf_1[20], buf_1[21], buf_1[22], buf_1[23]};
                end else if (buf_cnt_i == 6'd26) begin
                    out_buf_data_o <= {buf_1[24], buf_1[25], buf_1[26], buf_1[27]};
                end else if (buf_cnt_i == 6'd25) begin
                    out_buf_data_o <= {buf_1[28], buf_1[29], buf_1[30], buf_1[31]};
                // Buffer 2
                end else if (buf_cnt_i == 6'd24) begin
                    out_buf_data_o <= {buf_2[0], buf_2[1], buf_2[2], buf_2[3]};
                end else if (buf_cnt_i == 6'd23) begin
                    out_buf_data_o <= {buf_2[4], buf_2[5], buf_2[6], buf_2[7]};
                end else if (buf_cnt_i == 6'd22) begin
                    out_buf_data_o <= {buf_2[8], buf_2[9], buf_2[10], buf_2[11]};
                end else if (buf_cnt_i == 6'd21) begin
                    out_buf_data_o <= {buf_2[12], buf_2[13], buf_2[14], buf_2[15]};
                end else if (buf_cnt_i == 6'd20) begin
                    out_buf_data_o <= {buf_2[16], buf_2[17], buf_2[18], buf_2[19]};
                end else if (buf_cnt_i == 6'd19) begin
                    out_buf_data_o <= {buf_2[20], buf_2[21], buf_2[22], buf_2[23]};
                end else if (buf_cnt_i == 6'd18) begin
                    out_buf_data_o <= {buf_2[24], buf_2[25], buf_2[26], buf_2[27]};
                end else if (buf_cnt_i == 6'd17) begin
                    out_buf_data_o <= {buf_2[28], buf_2[29], buf_2[30], buf_2[31]};
                end else begin
                    out_buf_data_o <= '0;
                end
            end else begin 
                out_buf_data_o <= '0;
            end
        end   
    end


endmodule