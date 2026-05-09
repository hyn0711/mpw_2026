module cycle_shifter (
    input logic [1:0]       cycle_count_i,
    input logic [13:0]      data_i,

    output logic [19:0]     data_o
);
    logic [19:0] cycle_shift_output;

    always_comb begin
        cycle_shift_output = '0;
        case (cycle_count_i)
            2'b00: cycle_shift_output = {6'b0, data_i};
            2'b01: cycle_shift_output = {4'b0, data_i, 2'b0};
            2'b10: cycle_shift_output = {2'b0, data_i, 4'b0};
            2'b11: cycle_shift_output = {data_i, 6'b0};
            default: cycle_shift_output = '0; 
        endcase        
    end

    assign data_o = cycle_shift_output;

endmodule