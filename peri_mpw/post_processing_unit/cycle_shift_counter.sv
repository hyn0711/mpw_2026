module cycle_shift_counter (
    input logic         clk_i,
    input logic         rst_ni,

    input logic         cnt_en_i,
    input logic [2:0]   pim_mode_i,

    output logic [1:0]  cycle_count_o
);

    localparam PIM_ERASE = 3'b001;      // PIM_ERASE
    localparam PIM_PROGRAM = 3'b010;    // PIM_PROGRAM
    localparam PIM_READ = 3'b011;       // PIM_READ
    localparam PIM_DEBUG = 3'b100;      // PIM_DEBUG
    localparam PIM_PARALLEL = 3'b101;   // PIM_PARALLEL
    localparam PIM_RBR = 3'b110;        // PIM_RBR
    localparam PIM_LOAD = 3'b111;       // PIM_LOAD

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            cycle_count_o <= '0;
        end else begin
            if (pim_mode_i == PIM_PARALLEL || pim_mode_i == PIM_RBR) begin
                if (cnt_en_i) begin
                    cycle_count_o <= cycle_count_o + 2'd1;
                end else begin
                    cycle_count_o <= cycle_count_o;
                end
            end else if (pim_mode_i == PIM_ERASE || pim_mode_i == PIM_PROGRAM || 
                         pim_mode_i == PIM_READ || pim_mode_i == PIM_DEBUG || pim_mode_i == PIM_LOAD) begin
                cycle_count_o <= '0;
            end else begin
                cycle_count_o <= cycle_count_o;
            end
        end
    end
    
endmodule