
module eFlash_driver_T (
    input logic                 clk_i,
    input logic                 rst_ni,

    // eFlash signal control
    input logic                 pim_en_i,
    input logic [2:0]           pim_mode_i,
    input logic [3:0]           exec_cnt_i,

    input logic [6:0]           row_addr7_i,
    input logic [4:0]           col_addr5_i,

    // Output Signal to PIM
    output logic [511:0]        MODE_o,  
    output logic [255:0]        WL_SEL_o,
    output logic [255:0]        VPASS_EN_o,
    output logic [31:0]         BL_OPT_o,
    output logic [1:0]          CSL_o,
    output logic [1:0]          QDAC_o,
    output logic [1:0]          DISC_o,
    output logic [1:0]          PRECB_o
);

    // eFlash mode
    localparam PIM_ERASE = 3'b001;      // PIM_ERASE
    localparam PIM_PROGRAM = 3'b010;    // PIM_PROGRAM
    localparam PIM_READ = 3'b011;       // PIM_READ
    localparam PIM_DEBUG = 3'b100;      // PIM_DEBUG
    localparam PIM_PARALLEL = 3'b101;   // PIM_PARALLEL
    localparam PIM_RBR = 3'b110;        // PIM_RBR
    localparam PIM_LOAD = 3'b111;       // PIM_LOAD

    logic pim_en;
    logic [2:0] pim_mode;
    logic [3:0] exec_cnt;

    assign pim_en = pim_en_i;
    assign pim_mode = pim_mode_i;
    assign exec_cnt = exec_cnt_i;

    logic [511:0] mode;
    logic [255:0] wl_sel;
    logic [255:0] vpass_en;
    logic [31:0] bl_opt;
    logic [1:0] csl;
    logic [1:0] qdac;
    logic [1:0] disc;
    logic [1:0] precb;


    logic [3:0] row_a;
    logic [2:0] col_b;
    logic [2:0] row_c;

    assign row_a = row_addr7_i[3:0];
    assign col_b = col_addr5_i[2:0];
    assign row_c = row_addr7_i[6:4];


    // --------------------------- eFlash signal ---------------------------
    always_comb begin
        mode = '0;
        wl_sel = '0;
        vpass_en = 256'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
        bl_opt = '0;
        csl = '0;
        qdac = 2'b11;
        disc = 2'b11;
        precb = 2'b11;

        if (pim_en) begin
            case (pim_mode)
                PIM_ERASE: begin    
                    mode = '0;
                    for (int unsigned i = 0; i < 128; i++) begin
                        if (i == row_addr7_i) begin
                            wl_sel[i] = 1'b1;
                            wl_sel[i + 128] = 1'b1;
                        end else begin
                            wl_sel[i] = '0;
                            wl_sel[i + 128] = '0;
                        end
                    end
                    vpass_en = 256'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
                    bl_opt = '0;
                    csl = '0;
                    qdac = 2'b11;
                    disc = 2'b11;
                    precb = 2'b11;
                end
                PIM_PROGRAM: begin    
                    mode = {256{2'b01}};
                    for (int unsigned i = 0; i < 128; i++) begin
                        if (i == row_addr7_i) begin
                            wl_sel[i] = 1'b1;
                            wl_sel[i + 128] = 1'b1;
                            vpass_en[i] = 1'b1;
                            vpass_en[i + 128] = 1'b1;
                        end else begin
                            wl_sel[i] = '0;
                            wl_sel[i + 128] = '0;
                            vpass_en[i] = '0;
                            vpass_en[i + 128] = '0;
                        end
                    end
                    for (int unsigned i = 0; i < 32; i++) begin
                        if (i == col_addr5_i) begin
                            bl_opt[i] = '0;
                        end else begin
                            bl_opt[i] = 1'b1;
                        end
                    end
                    csl = 2'b11;
                    qdac = 2'b11;
                    disc = 2'b11;
                    precb = 2'b11;
                end
                PIM_READ: begin   
                    mode = {256{2'b10}};
                    bl_opt = '0;
                    csl = '0;
                    qdac = 2'b11;
                    disc = '0;
                    for (int unsigned i = 0; i < 128; i++) begin
                        if (i == row_addr7_i) begin
                            wl_sel[i] = 1'b1;
                            wl_sel[i + 128] = 1'b1;
                            vpass_en[i] = 1'b1;
                            vpass_en[i + 128] = 1'b1;
                        end else begin
                            wl_sel[i] = '0;
                            wl_sel[i + 128] = '0;
                            vpass_en[i] = '0;
                            vpass_en[i + 128] = '0;
                        end
                    end
                    if (exec_cnt == 4'd9 || exec_cnt == 4'd8 || exec_cnt == 4'd7) begin
                        precb = '0;
                    end else begin
                        precb = 2'b11;
                    end
                end
                PIM_PARALLEL: begin    
                    mode = {256{2'b10}};
                    bl_opt = '0;
                    csl = '0;
                    disc = '0;
                    for (int unsigned i = 0; i < 16; i++) begin
                        if (i == row_a) begin
                            for (int unsigned j = 0; j < 8; j++) begin
                                wl_sel[16 * j + i] = 1'b1;
                                wl_sel[16 * j + i + 128] = 1'b1;
                                vpass_en[16 * j + i] = 1'b1;
                                vpass_en[16 * j + i + 128] = 1'b1;
                            end
                        end else begin
                            for (int unsigned j = 0; j < 8; j++) begin
                                wl_sel[16 * j + i] = '0;
                                wl_sel[16 * j + i + 128] = '0;
                                vpass_en[16 * j + i] = '0;
                                vpass_en[16 * j + i + 128] = '0;
                            end
                        end
                    end
                    if (exec_cnt == 4'd12 || exec_cnt == 4'd11 || exec_cnt == 4'd10) begin
                        qdac = 2'b11;
                        precb = '0;
                    end else if (exec_cnt == 4'd9 || exec_cnt == 4'd8 || exec_cnt == 4'd7 || exec_cnt == 4'd6 || exec_cnt == 4'd5) begin
                        qdac = 2'b11;
                        precb = 2'b11;
                    end else if (exec_cnt == 4'd4 || exec_cnt == 4'd3 || exec_cnt == 4'd2 || exec_cnt == 4'd1) begin
                        qdac = '0;
                        precb = 2'b11;
                    end else begin
                        qdac = 2'b11;
                        precb = 2'b11;
                    end
                end

                PIM_RBR: begin  
                    mode = {256{2'b10}};
                    bl_opt = '0;
                    csl = '0;
                    qdac = 2'b11;
                    disc = '0;
                    for (int unsigned i = 0; i < 16; i++) begin
                        if (i == row_a) begin
                            for (int unsigned j = 0; j < 8; j++) begin
                                wl_sel[16 * j + i] = 1'b1;
                                wl_sel[16 * j + i + 128] = 1'b1;
                                vpass_en[16 * j + i] = 1'b1;
                                vpass_en[16 * j + i + 128] = 1'b1;
                            end
                        end else begin
                            for (int unsigned j = 0; j < 8; j++) begin
                                wl_sel[16 * j + i] = '0;
                                wl_sel[16 * j + i + 128] = '0;
                                vpass_en[16 * j + i] = '0;
                                vpass_en[16 * j + i + 128] = '0;
                            end
                        end
                    end
                    if (exec_cnt == 4'd9 || exec_cnt == 4'd8 || exec_cnt == 4'd7) begin
                        precb = '0;
                    end else begin
                        precb = 2'b11;
                    end
                end
                PIM_LOAD: begin    // Load mode
                end
                PIM_DEBUG: begin
                end
                default: begin
                    mode = '0;
                    wl_sel = '0;
                    vpass_en = 256'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
                    bl_opt = '0;
                    csl = '0;
                    qdac = 2'b11;
                    disc = 2'b11;
                    precb = 2'b11;
                end
            endcase
        end else begin
            mode = '0;
            wl_sel = '0;
            vpass_en = 256'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
            bl_opt = '0;
            csl = '0;
            qdac = 2'b11;
            disc = 2'b11;
            precb = 2'b11;
        end
    end

    always_ff @ (posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            MODE_o <= '0;
            WL_SEL_o <= '0;
            VPASS_EN_o <= '0;
            BL_OPT_o <= '0;
            CSL_o <= '0;
            QDAC_o <= 2'b11;
            DISC_o <= 2'b11;
            PRECB_o <= 2'b11;
        end else begin
            MODE_o <= mode;
            WL_SEL_o <= wl_sel;
            VPASS_EN_o <= vpass_en;
            BL_OPT_o <= bl_opt;
            CSL_o <= csl;
            QDAC_o <= qdac;
            DISC_o <= disc;
            PRECB_o <= precb;
        end
    end

endmodule 
