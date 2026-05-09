module output_buf_mux (
    input logic [2:0]       pim_mode_i,
    input logic [4:0]       buf8_cnt_i,
    input logic [3:0]       buf32_cnt_i,

    input logic [7:0]       buf8_MOUT_i [0:31],
    input logic [7:0]       buf8_FOUT_i [0:31],

    input logic [31:0]      buf32_data_i [0:7],

    // input logic [31:0]      buf32_data_i,

    output logic [31:0]     mux_data_o
);

    localparam PIM_ERASE = 3'b001;      // PIM_ERASE
    localparam PIM_PROGRAM = 3'b010;    // PIM_PROGRAM
    localparam PIM_READ = 3'b011;       // PIM_READ
    localparam PIM_DEBUG = 3'b100;      // PIM_DEBUG
    localparam PIM_PARALLEL = 3'b101;   // PIM_PARALLEL
    localparam PIM_RBR = 3'b110;        // PIM_RBR
    localparam PIM_LOAD = 3'b111;       // PIM_LOAD

    always_comb begin
        if (pim_mode_i == PIM_DEBUG) begin
            if (buf8_cnt_i == 5'd0) begin
                mux_data_o = {buf8_MOUT_i[0], buf8_MOUT_i[1], buf8_MOUT_i[2], buf8_MOUT_i[3]};
            end else if (buf8_cnt_i == 5'd1) begin
                mux_data_o = {buf8_MOUT_i[4], buf8_MOUT_i[5], buf8_MOUT_i[6], buf8_MOUT_i[7]};
            end else if (buf8_cnt_i == 5'd2) begin
                mux_data_o = {buf8_MOUT_i[8], buf8_MOUT_i[9], buf8_MOUT_i[10], buf8_MOUT_i[11]};
            end else if (buf8_cnt_i == 5'd3) begin
                mux_data_o = {buf8_MOUT_i[12], buf8_MOUT_i[13], buf8_MOUT_i[14], buf8_MOUT_i[15]};
            end else if (buf8_cnt_i == 5'd4) begin
                mux_data_o = {buf8_MOUT_i[16], buf8_MOUT_i[17], buf8_MOUT_i[18], buf8_MOUT_i[19]};
            end else if (buf8_cnt_i == 5'd5) begin
                mux_data_o = {buf8_MOUT_i[20], buf8_MOUT_i[21], buf8_MOUT_i[22], buf8_MOUT_i[23]};
            end else if (buf8_cnt_i == 5'd6) begin
                mux_data_o = {buf8_MOUT_i[24], buf8_MOUT_i[25], buf8_MOUT_i[26], buf8_MOUT_i[27]};
            end else if (buf8_cnt_i == 5'd7) begin
                mux_data_o = {buf8_MOUT_i[28], buf8_MOUT_i[29], buf8_MOUT_i[30], buf8_MOUT_i[31]};
            end else if (buf8_cnt_i == 5'd8) begin
                mux_data_o = {buf8_FOUT_i[0], buf8_FOUT_i[1], buf8_FOUT_i[2], buf8_FOUT_i[3]};
            end else if (buf8_cnt_i == 5'd9) begin
                mux_data_o = {buf8_FOUT_i[4], buf8_FOUT_i[5], buf8_FOUT_i[6], buf8_FOUT_i[7]};
            end else if (buf8_cnt_i == 5'd10) begin
                mux_data_o = {buf8_FOUT_i[8], buf8_FOUT_i[9], buf8_FOUT_i[10], buf8_FOUT_i[11]};
            end else if (buf8_cnt_i == 5'd11) begin
                mux_data_o = {buf8_FOUT_i[12], buf8_FOUT_i[13], buf8_FOUT_i[14], buf8_FOUT_i[15]};
            end else if (buf8_cnt_i == 5'd12) begin
                mux_data_o = {buf8_FOUT_i[16], buf8_FOUT_i[17], buf8_FOUT_i[18], buf8_FOUT_i[19]};
            end else if (buf8_cnt_i == 5'd13) begin
                mux_data_o = {buf8_FOUT_i[20], buf8_FOUT_i[21], buf8_FOUT_i[22], buf8_FOUT_i[23]};
            end else if (buf8_cnt_i == 5'd14) begin
                mux_data_o = {buf8_FOUT_i[24], buf8_FOUT_i[25], buf8_FOUT_i[26], buf8_FOUT_i[27]};
            end else if (buf8_cnt_i == 5'd15) begin
                mux_data_o = {buf8_FOUT_i[28], buf8_FOUT_i[29], buf8_FOUT_i[30], buf8_FOUT_i[31]};
            end else begin
                mux_data_o = '0;
            end
        end else if (pim_mode_i == PIM_LOAD) begin
            if (buf32_cnt_i == 4'd0) begin
                mux_data_o = buf32_data_i[0];
            end else if (buf32_cnt_i == 4'd1) begin
                mux_data_o = buf32_data_i[1];
            end else if (buf32_cnt_i == 4'd2) begin
                mux_data_o = buf32_data_i[2];
            end else if (buf32_cnt_i == 4'd3) begin
                mux_data_o = buf32_data_i[3];
            end else if (buf32_cnt_i == 4'd4) begin
                mux_data_o = buf32_data_i[4];
            end else if (buf32_cnt_i == 4'd5) begin
                mux_data_o = buf32_data_i[5];
            end else if (buf32_cnt_i == 4'd6) begin
                mux_data_o = buf32_data_i[6];
            end else if (buf32_cnt_i == 4'd7) begin
                mux_data_o = buf32_data_i[7];
            end else begin
                mux_data_o = '0;
            end
        end else begin
            mux_data_o = '0;
        end
    end


endmodule