module parallel_encoder (
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

    assign data_o = total_zeros;

endmodule