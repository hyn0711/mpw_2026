

module sram_8192w_8b_wrapper (
    input logic clk_i,
    input logic wen_i,
    input logic [12:0] addr_i,
    input logic [7:0] din_i,
    output logic [7:0] dout_o
);
    sram_8192w_8b SRAM_8192W_8B (
		.CLK 			(clk_i),
		.CEN			(1'b0),
		.WEN			(wen_i),
		.A 				(addr_i), // 13-bit address
		.D 				(din_i),
		.EMA			(3'b000),
		.RETN			(1'b1),
		// outputs
		.Q 				(dout_o)
	);
endmodule