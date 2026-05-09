module rbr_encoder (
    input logic [7:0]     data_i,
    output logic [3:0]    data_o
);

    logic [7:0] inv_data;
    logic [1:0] sum_z1_0, sum_z1_1, sum_z1_2, sum_z1_3;
    logic [2:0] sum_z2_0, sum_z2_1;
    logic [3:0] total_zeros;

    assign inv_data = ~data_i;
    assign sum_z1_0 = inv_data[0] + inv_data[1];
    assign sum_z1_1 = inv_data[2] + inv_data[3];
    assign sum_z1_2 = inv_data[4] + inv_data[5];
    assign sum_z1_3 = inv_data[6] + inv_data[7];

    assign sum_z2_0 = sum_z1_0 + sum_z1_1;
    assign sum_z2_1 = sum_z1_2 + sum_z1_3;

    assign total_zeros = sum_z2_0 + sum_z2_1;

    always_comb begin
        case (total_zeros)
            4'd0:       data_o = 4'b0000;
            4'd1:       data_o = 4'b0001;
            4'd2:       data_o = 4'b0010;
            4'd3:       data_o = 4'b0011;
            4'd4:       data_o = 4'b0100;
            4'd5:       data_o = 4'b0110;
            4'd6:       data_o = 4'b0110;
            4'd7:       data_o = 4'b1001;
            4'd8:       data_o = 4'b1001;
            default:    data_o = 4'b0000;
        endcase
    end

endmodule