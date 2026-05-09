module peri_controller_v2 #(
    parameter PIM_MODE          = 32'h4100_0000,
    parameter PIM_STATUS        = 32'h4300_0000
) (
    input logic                 clk_i,
    input logic                 rst_ni,

    // RISC-V <-> PERI
    input logic [31:0]          address_i,
    input logic [31:0]          data_i,

    output logic [31:0]         data_o,

    // -> Row, Col driver
    output logic                pim_en_o,
    output logic [2:0]          pim_mode_o,
    output logic [3:0]          exec_cnt_o,

    output logic [6:0]          row_addr7_o,
    output logic [4:0]          col_addr5_o,
        
    // -> Input buffer
    output logic                in_buf_w_en_o,
    output logic                in_buf_r_en_o,
    output logic [31:0]         input_data_o,
    output logic [3:0]          data_rx_cnt_o,

    // Output buffer
    output logic                out_buf8_r_en_o,
    output logic                cycle_shift_en_o,
    output logic                out_buf32_w_en_o,
    output logic                out_buf32_r_en_o,
    output logic [4:0]          out_buf8_cnt_o,
    output logic [3:0]          out_buf32_cnt_o,

    input logic [31:0]          out_buf_data_i
);


    // == PIM MODE ==
    localparam PIM_ERASE = 3'b001;      // PIM_ERASE
    localparam PIM_PROGRAM = 3'b010;    // PIM_PROGRAM
    localparam PIM_READ = 3'b011;       // PIM_READ
    localparam PIM_DEBUG = 3'b100;      // PIM_DEBUG
    localparam PIM_PARALLEL = 3'b101;   // PIM_PARALLEL
    localparam PIM_RBR = 3'b110;        // PIM_RBR
    localparam PIM_LOAD = 3'b111;       // PIM_LOAD

    logic [2:0] pim_mode;
    logic [6:0] row_addr;
    logic [4:0] col_addr;
    logic [16:0] pulse_width;
    logic [4:0] pulse_count;
    logic debug_mode;    // 0: parallel, 1: rbr
    logic [3:0] load_count, debug_count;

    logic [3:0] counter;
    logic [16:0] p_width_counter;
    logic [4:0] p_count_counter;
    logic [3:0] load_counter;
    logic [4:0] debug_counter;
    logic [1:0] processing_counter;

    // ==|FSM|======================================
    // == State ==
    typedef enum logic [1:0] {
        IDLE = 2'b00,
        PIM_SETUP = 2'b01,
        PIM_EXEC = 2'b10,
        PIM_PROCESSING = 2'b11
    } state_t;

    state_t curr_state, next_state;

    logic mode_received, setup_finish;

    assign mode_received = (address_i == PIM_MODE);
    assign setup_finish = (curr_state == PIM_SETUP) && (
        (pim_mode == PIM_ERASE && address_i[31:16] == 16'h4000)      ||
        (pim_mode == PIM_PROGRAM && address_i[31:16] == 16'h4000)    ||
        (pim_mode == PIM_READ && address_i[31:16] == 16'h4000)       || 
        (pim_mode == PIM_PARALLEL && address_i[31:16] == 16'h4003)   ||     // Input data 64 * 2bit (4 cycles)
        (pim_mode == PIM_RBR && address_i[31:16] == 16'h4000)             // Input data 8 * 2bit (1 cycles)
        //(pim_mode == PIM_LOAD && address_i[31:16] == 16'h4000)
    );

    // state transition
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            curr_state <= IDLE;
        end else begin
            curr_state <= next_state;
        end
    end

    always_comb begin
        next_state = IDLE;
        case (curr_state)
            IDLE: begin
                if (mode_received) begin
                    if (data_i[2:0] == PIM_DEBUG || data_i[2:0] == PIM_LOAD) begin
                        next_state = PIM_EXEC;
                    end else begin
                        next_state = PIM_SETUP;
                    end
                end else begin
                    next_state = IDLE;
                end
            end
            PIM_SETUP: begin
                if (setup_finish) begin
                    next_state = PIM_EXEC;
                end else begin
                    next_state = PIM_SETUP;
                end
            end
            PIM_EXEC: begin
                if (pim_mode == PIM_ERASE || pim_mode == PIM_PROGRAM) begin
                    if (p_count_counter == 5'd1 && p_width_counter == '0) begin
                        next_state = IDLE;
                    end else begin
                        next_state = PIM_EXEC;
                    end
                end else if (pim_mode == PIM_READ) begin
                    if (counter == '0) begin
                        next_state = IDLE;
                    end else begin
                        next_state = PIM_EXEC;
                    end
                end else if (pim_mode == PIM_PARALLEL || pim_mode == PIM_RBR) begin
                    if (counter == 4'd1) begin
                        next_state = PIM_PROCESSING;
                    end else begin
                        next_state = PIM_EXEC;
                    end
                end else if (pim_mode == PIM_LOAD) begin
                    if (load_counter == 4'd1) begin
                        next_state = IDLE;
                    end else begin
                        next_state = PIM_EXEC;
                    end
                end else if (pim_mode == PIM_DEBUG) begin
                    if (debug_mode) begin
                        if (debug_counter == 5'd1) begin
                            next_state = IDLE;
                        end else begin
                            next_state = PIM_EXEC;
                        end
                    end else begin
                        if (debug_counter == 5'd1) begin
                            next_state = IDLE;
                        end else begin
                            next_state = PIM_EXEC;
                        end
                    end
                end
            end
            PIM_PROCESSING: begin
                if (pim_mode == PIM_PARALLEL || pim_mode == PIM_RBR) begin
                    if (processing_counter == '0) begin
                        next_state = IDLE;
                    end else begin
                        next_state = PIM_PROCESSING;
                    end
                end 
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end


    // ==|REGISTER|=================================
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            pim_mode <= '0;
            row_addr <= '0;
            col_addr <= '0;
            pulse_width <= '0;
            pulse_count <= '0;
            debug_mode <= '0;
            debug_count <= '0;
            load_count <= '0;
        end else begin
            if (mode_received) begin
                pim_mode <= data_i[2:0];
                row_addr <= '0;
                col_addr <= '0;
                pulse_width <= '0;
                pulse_count <= '0;
                debug_mode <= data_i[3];
            end else if (address_i[31:20] == 12'h400) begin
                pim_mode <= pim_mode;
                debug_mode <= debug_mode;
                if (pim_mode == PIM_ERASE || pim_mode == PIM_PROGRAM) begin
                    row_addr <= address_i[15:9];
                    col_addr <= address_i[4:0];
                    pulse_width <= data_i[21:5];
                    pulse_count <= data_i[4:0];
                    debug_count <= '0;
                    load_count <= '0;
                end else if (pim_mode == PIM_READ) begin
                    row_addr <= address_i[15:9];
                    col_addr <= address_i[4:0];
                    pulse_width <= '0;
                    pulse_count <= '0;
                    debug_count <= '0;
                    load_count <= '0;
                end else if (pim_mode == PIM_PARALLEL || pim_mode == PIM_RBR) begin
                    row_addr <= address_i[15:9];
                    col_addr <= address_i[4:0];
                    pulse_width <= '0;
                    pulse_count <= '0;
                    debug_count <= '0;
                    load_count <= '0;
                end else if (pim_mode == PIM_DEBUG) begin
                    debug_count <= address_i[19:16];
                    load_count <= '0;
                end else if (pim_mode == PIM_LOAD) begin
                    load_count <= address_i[19:16];
                    debug_count <= '0;
                end else begin
                    row_addr <= row_addr;
                    col_addr <= col_addr;
                    pulse_width <= pulse_width;
                    pulse_count <= pulse_count;
                    debug_count <= '0;
                    load_count <= '0;
                end
            end else begin
                pim_mode <= pim_mode;
                row_addr <= row_addr;
                col_addr <= col_addr;
                pulse_width <= pulse_width;
                pulse_count <= pulse_count;
                debug_mode <= debug_mode;
                debug_count <= '0;
                load_count <= '0;
            end
        end
    end

    // ==|COUNTER|=============================
    // Debug, Load Counter
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            load_counter <= '0;
            debug_counter <= '0;
        end else begin
            if (mode_received && data_i[2:0] == PIM_LOAD) begin
                load_counter <= 4'd8;
            end else if (pim_mode == PIM_LOAD && load_counter != '0) begin
                load_counter <= load_counter - 1;
            end

            if (mode_received && data_i[2:0] == PIM_DEBUG) begin
                debug_counter <= data_i[3] ? 5'd8 : 5'd16;
            end else if (pim_mode == PIM_DEBUG && debug_counter != '0) begin
                debug_counter <= debug_counter - 1;
            end
        end
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            counter <= '0;
            p_width_counter <= '0;
            p_count_counter <= '0;
        end else begin
            if (pim_mode == PIM_READ || pim_mode == PIM_RBR) begin
                if (setup_finish) begin    
                    counter <= 4'd9;
                end else if (counter != '0) begin
                    counter <= counter - 1;
                end else begin
                    counter <= '0;
                end
            end else if (pim_mode == PIM_PARALLEL) begin
                if (setup_finish) begin    
                    counter <= 4'd12;
                end else if (counter != '0) begin
                    counter <= counter - 1;
                end else begin
                    counter <= '0;
                end
            end else if (pim_mode == PIM_ERASE || pim_mode == PIM_PROGRAM) begin
                if (setup_finish) begin
                    p_width_counter <= data_i[21:5];
                    p_count_counter <= data_i[4:0];
                end else if (p_count_counter != '0) begin
                    if (p_width_counter != '0) begin
                        p_width_counter <= p_width_counter -1;
                    end else begin
                        p_count_counter <= p_count_counter -1;
                        p_width_counter <= pulse_width;
                    end
                end else begin
                    p_width_counter <= '0;
                    p_count_counter <= '0;
                end
            end else begin
                counter <= '0;
                p_width_counter <= '0;
                p_count_counter <= '0;
            end
        end
    end

    // Processing counter
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            processing_counter <= '0;
        end else begin
            if (curr_state == PIM_EXEC && counter == 4'd1) begin
                processing_counter <= 2'd1;
            end else if (processing_counter != '0) begin
                processing_counter <= processing_counter - 1;
            end else begin
                processing_counter <= '0;
            end
        end
    end

    // ==|OUTPUT SIGNAL|=======================
    always_comb begin
        pim_en_o = '0;
        pim_mode_o = '0;
        row_addr7_o = '0;
        col_addr5_o = '0;
        exec_cnt_o = '0;
        in_buf_w_en_o = '0;
        in_buf_r_en_o = '0;
        input_data_o = '0;
        data_rx_cnt_o = '0;
        out_buf8_r_en_o = '0;
        cycle_shift_en_o = '0;
        out_buf32_w_en_o = '0;
        out_buf32_r_en_o = '0;
        out_buf8_cnt_o = '0;
        out_buf32_cnt_o = '0;
        case (curr_state)
            PIM_SETUP: begin
                if (pim_mode == PIM_PARALLEL || pim_mode == PIM_RBR) begin
                    if (address_i[31:20] == 12'h400) begin
                        in_buf_w_en_o = 1'b1;
                        input_data_o = data_i;
                        data_rx_cnt_o = address_i[19:16];
                    end else begin
                        in_buf_w_en_o = '0;
                        input_data_o = '0;
                        data_rx_cnt_o = '0;
                    end
                end else begin
                    in_buf_w_en_o = '0;
                    input_data_o = '0;
                    data_rx_cnt_o = '0;
                end
            end
            PIM_EXEC: begin
                if (pim_mode == PIM_ERASE || pim_mode == PIM_PROGRAM) begin
                    if (p_width_counter != '0) begin
                        pim_en_o = 1'b1;
                        pim_mode_o = pim_mode;
                        row_addr7_o = row_addr;
                        col_addr5_o = col_addr;
                    end else begin
                        pim_en_o = '0;
                        pim_mode_o = pim_mode;
                        row_addr7_o = row_addr;
                        col_addr5_o = col_addr;
                    end
                end else if (pim_mode == PIM_READ) begin
                    if (counter != '0) begin
                        pim_en_o = 1'b1;
                        pim_mode_o = pim_mode;
                        row_addr7_o = row_addr;
                        col_addr5_o = col_addr;
                        exec_cnt_o = counter;
                        in_buf_r_en_o = '0;
                    end else begin
                        pim_en_o = '0;
                        pim_mode_o = '0;
                        row_addr7_o = '0;
                        col_addr5_o = '0;
                        exec_cnt_o = '0;
                        in_buf_r_en_o = '0;
                    end
                end else if (pim_mode == PIM_PARALLEL || pim_mode == PIM_RBR) begin
                    if (counter != '0) begin
                        pim_en_o = 1'b1;
                        pim_mode_o = pim_mode;
                        row_addr7_o = row_addr;
                        col_addr5_o = col_addr;
                        exec_cnt_o = counter;
                        in_buf_r_en_o = 1'b1;
                    end else begin
                        pim_en_o = '0;
                        pim_mode_o = pim_mode;
                        row_addr7_o = '0;
                        col_addr5_o = '0;
                        exec_cnt_o = '0;
                        in_buf_r_en_o = '0;
                    end
                end else if (pim_mode == PIM_LOAD) begin
                    pim_mode_o = pim_mode;
                    out_buf32_r_en_o = 1'b1;
                    out_buf32_cnt_o = 4'd8 - load_counter;
                end else if (pim_mode == PIM_DEBUG) begin
                    pim_mode_o = pim_mode;
                    out_buf8_r_en_o = 1'b1;
                    if (debug_mode) begin
                        out_buf8_cnt_o = 5'd8 - debug_counter;
                    end else begin
                        out_buf8_cnt_o = 5'd16 - debug_counter;
                    end
                end else begin
                    pim_en_o = '0;
                    pim_mode_o = pim_mode;
                    row_addr7_o = '0;
                    col_addr5_o = '0;
                    exec_cnt_o = '0;
                    in_buf_w_en_o = '0;
                    in_buf_r_en_o = '0;
                    input_data_o = '0;
                    data_rx_cnt_o = '0;
                    out_buf8_r_en_o = '0;
                    cycle_shift_en_o = '0;
                    out_buf32_w_en_o = '0;
                    out_buf32_r_en_o = '0;
                    out_buf8_cnt_o = '0;
                    out_buf32_cnt_o = '0;
                end
            end
            PIM_PROCESSING: begin
                pim_mode_o = pim_mode;
                out_buf8_r_en_o = '0;
                cycle_shift_en_o = '0;
                out_buf32_w_en_o = '0;
                if (processing_counter == 2'd1) begin
                    out_buf8_r_en_o = 1'b1;
                end else if (processing_counter == 2'd0) begin
                    out_buf8_r_en_o = 1'b1;
                    cycle_shift_en_o = 1'b1;
                    out_buf32_w_en_o = 1'b1;
                end 
            end
            default: begin
                pim_en_o = '0;
                pim_mode_o = pim_mode;    
                row_addr7_o = '0;
                col_addr5_o = '0;
                exec_cnt_o = '0;
                in_buf_w_en_o = '0;
                in_buf_r_en_o = '0;
                input_data_o = '0;
                data_rx_cnt_o = '0;
                out_buf8_r_en_o = '0;
                cycle_shift_en_o = '0;
                out_buf32_w_en_o = '0;
                out_buf32_r_en_o = '0;
                out_buf8_cnt_o = '0;
                out_buf32_cnt_o = '0;
            end
        endcase
    end

    // ==|PIM VALID|========================
    logic pim_valid;
    logic pim_data_valid;

    assign pim_valid = (curr_state == IDLE);
    always_ff @ (posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            pim_data_valid <= '0;
        end else begin
            if ((pim_mode == PIM_READ || pim_mode == PIM_PARALLEL || pim_mode == PIM_RBR) && (counter == 4'd1)) begin
                pim_data_valid <= 1'b1;
            end else if (pim_mode == PIM_LOAD) begin
                pim_data_valid <= '0;
            end else begin
                pim_data_valid <= pim_data_valid;
            end
        end
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            data_o <= '0;
        end else begin
            if (address_i == PIM_STATUS) begin
                data_o <= {30'b0, pim_data_valid, pim_valid};
            end else if (out_buf8_r_en_o) begin
                data_o <= out_buf_data_i;
            end else if (out_buf32_r_en_o) begin
                data_o <= out_buf_data_i;
            end else begin
                data_o <= '0;
            end
        end
    end
        

endmodule