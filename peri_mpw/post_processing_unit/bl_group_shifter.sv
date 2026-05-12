// Bit-line group shifting logic

module bl_group_shifter (
    input logic [6:0]      data_i[0:3],    

    output logic [13:0]    data_o 
);

    logic [13:0] shift_data [0:3];

    assign shift_data[0] = {1'b0, data_i[0], 6'b0};
    assign shift_data[1] = {3'b0, data_i[1], 4'b0};
    assign shift_data[2] = {5'b0, data_i[2], 2'b0};
    assign shift_data[3] = {7'b0, data_i[3]};

    assign data_o = shift_data[0] + shift_data[1] + shift_data[2] + shift_data[3];
    

endmodule