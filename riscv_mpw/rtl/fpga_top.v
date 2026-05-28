`timescale 1ns / 1ps
// VC707 FPGA Board
module fpga_top(
    input  wire sysclk_p,
    input  wire sysclk_n,

    input  wire rst_ni,
    input  wire spi_rst_ni,

    // SPI
    input  wire i_sclk,
    input  wire i_cs,
    input  wire i_mosi,
    output wire o_miso,

    // LEDs
    output reg  rst_led,
    output reg  spi_rst_led,
    output reg  sclk_led,
    output reg  cs_led,
    output reg  mosi_led,
    output reg  miso_led,
    output reg  tx_led,
    output reg  rx_led,

    // UART TX/RX
    input  wire i_serial_rx,
    output wire o_serial_tx
);

    // -------------------------------------------------------------------------
    // Clocking
    // -------------------------------------------------------------------------
    wire sysclk;
    wire clk_locked;

    clk_wiz_0 u_clk_wiz (
        .clk_out1 (sysclk),
        .reset    (1'b0),
        .locked   (clk_locked),
        .clk_in1_p(sysclk_p),
        .clk_in1_n(sysclk_n)
    );

    wire rv_rst_n_int  = rst_ni     & clk_locked;
    wire spi_rst_n_int = spi_rst_ni & clk_locked;

    // -------------------------------------------------------------------------
    // Internal SPI/UART wires
    // -------------------------------------------------------------------------
    wire cpu_tx;
    wire cpu_rx;
    wire sclk;
    wire cs;
    wire mosi;
    wire miso;

    // -------------------------------------------------------------------------
    // SPI IOB registers
    // -------------------------------------------------------------------------
    (* IOB = "true" *) reg fpga_sclk_iob;
    (* IOB = "true" *) reg fpga_cs_iob;
    (* IOB = "true" *) reg fpga_mosi_iob;
    (* IOB = "true" *) reg fpga_miso_iob;

    // -------------------------------------------------------------------------
    // UART IOB registers
    // -------------------------------------------------------------------------
    (* IOB = "true" *) reg fpga_serial_tx_iob;
    (* IOB = "true" *) reg fpga_serial_rx_iob;

    // -------------------------------------------------------------------------
    // LED control
    // -------------------------------------------------------------------------
    always @(posedge sysclk or negedge spi_rst_n_int) begin
        if (~spi_rst_n_int) begin
            spi_rst_led <= 1'b0;
            sclk_led    <= 1'b0;
            cs_led      <= 1'b0;
            mosi_led    <= 1'b0;
            miso_led    <= 1'b0;
        end else begin
            spi_rst_led <= 1'b1;
            sclk_led    <= fpga_sclk_iob;
            cs_led      <= fpga_cs_iob;
            mosi_led    <= fpga_mosi_iob;
            miso_led    <= fpga_miso_iob;
        end
    end

    always @(posedge sysclk or negedge rv_rst_n_int) begin
        if (~rv_rst_n_int) begin
            rst_led <= 1'b0;
            tx_led  <= 1'b0;
            rx_led  <= 1'b0;
        end else begin
            rst_led <= 1'b1;
            tx_led  <= ~fpga_serial_tx_iob;
            rx_led  <= ~fpga_serial_rx_iob;
        end
    end

    // -------------------------------------------------------------------------
    // Core logic
    // -------------------------------------------------------------------------
    mpw_top #(
        .FPGA(1)
    ) u_core_top_2 (
        .CLK      (sysclk),
        .RVRSTN   (rv_rst_n_int),
        .SPIRSTN  (spi_rst_n_int),

        // SPI
        .SCLK     (sclk),
        .CS       (cs),
        .MOSI     (mosi),
        .MISO     (miso),

        // UART
        .SERIALRX (cpu_rx),
        .SERIALTX (cpu_tx),

        .PIMADDR  (),
        .PIMWD    (),
        .PIMRD    (32'b0)
    );

    // -------------------------------------------------------------------------
    // SPI IOB logic
    // -------------------------------------------------------------------------
    assign o_miso = fpga_miso_iob;
    assign sclk   = fpga_sclk_iob;
    assign cs     = fpga_cs_iob;
    assign mosi   = fpga_mosi_iob;

    always @(posedge sysclk or negedge spi_rst_n_int) begin
        if (~spi_rst_n_int) begin
            fpga_miso_iob <= 1'b0;
            fpga_sclk_iob <= 1'b0;
            fpga_cs_iob   <= 1'b1;
            fpga_mosi_iob <= 1'b0;
        end else begin
            fpga_miso_iob <= miso;
            fpga_sclk_iob <= i_sclk;
            fpga_cs_iob   <= i_cs;
            fpga_mosi_iob <= i_mosi;
        end
    end

    // -------------------------------------------------------------------------
    // UART IOB logic
    // -------------------------------------------------------------------------
    assign o_serial_tx = fpga_serial_tx_iob;
    assign cpu_rx      = fpga_serial_rx_iob;

    always @(posedge sysclk or negedge rv_rst_n_int) begin
        if (~rv_rst_n_int) begin
            fpga_serial_tx_iob <= 1'b1;  
            fpga_serial_rx_iob <= 1'b1;
        end else begin
            fpga_serial_tx_iob <= cpu_tx;
            fpga_serial_rx_iob <= i_serial_rx;
        end
    end

endmodule