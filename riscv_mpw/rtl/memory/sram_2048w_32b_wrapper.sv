

module sram_2048w_32b_wrapper (
    input logic clk_i,
    input logic gwen_i,
    input logic [3:0] wen_i,
    input logic [10:0] addr_i,
    input logic [31:0] din_i,
    output logic [31:0] dout_o
);

    sram_2048w_32b SRAM_2048W_32B (
        .CLK            (clk_i),
        .CEN            (1'b0),
        .GWEN           (gwen_i),
        .WEN            (wen_i),
        .A              (addr_i),       // 11-bit address
        .D              (din_i),
        .EMA            (3'b000),
        .RETN           (1'b1),
        // outputs
        .Q              (dout_o)
    );

endmodule