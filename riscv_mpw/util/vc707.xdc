###############################################################################
# VC707 XDC for top-level: fpga_top.v
# Board: Xilinx VC707 / Virtex-7 XC7VX485T-2FFG1761C
#
# This version uses the onboard 200 MHz LVDS SYSCLK oscillator:
#   sysclk_p -> E19 / SYSCLK_P
#   sysclk_n -> E18 / SYSCLK_N
#
# The RTL converts SYSCLK_P/N with IBUFDS and feeds clk_wiz_0.clk_in1.
# Therefore clk_wiz_0 must be configured as:
#   input clock  = 200 MHz
#   output clock = 100 MHz recommended for UART divisor 868 -> 115200 baud
###############################################################################

###############################################################################
# Configuration voltage
###############################################################################
set_property CONFIG_VOLTAGE 1.8 [current_design]
set_property CFGBVS GND [current_design]

###############################################################################
# Clock: VC707 onboard U51 200 MHz LVDS system clock
###############################################################################
set_property PACKAGE_PIN E19 [get_ports sysclk_p]
set_property PACKAGE_PIN E18 [get_ports sysclk_n]
set_property IOSTANDARD LVDS [get_ports {sysclk_p sysclk_n}]
create_clock -name sysclk_p -period 5.000 [get_ports sysclk_p]

###############################################################################
# Resets: VC707 SW2 DIP switches
# rst_ni      -> SW2[0]
# spi_rst_ni  -> SW2[1]
###############################################################################
set_property PACKAGE_PIN AV30 [get_ports rst_ni]
set_property IOSTANDARD LVCMOS18 [get_ports rst_ni]

set_property PACKAGE_PIN AY33 [get_ports spi_rst_ni]
set_property IOSTANDARD LVCMOS18 [get_ports spi_rst_ni]

###############################################################################
# SPI slave pins
# Mapped to LCD header GPIO pins.
# Use only if LCD is not installed / not used.
# VC707 GPIO/LCD pins are LVCMOS18. Do not directly connect 3.3 V Raspberry Pi SPI.
###############################################################################
set_property PACKAGE_PIN AT42 [get_ports i_sclk]
set_property IOSTANDARD LVCMOS18 [get_ports i_sclk]

set_property PACKAGE_PIN AR38 [get_ports i_cs]
set_property IOSTANDARD LVCMOS18 [get_ports i_cs]

set_property PACKAGE_PIN AR39 [get_ports i_mosi]
set_property IOSTANDARD LVCMOS18 [get_ports i_mosi]

set_property PACKAGE_PIN AN40 [get_ports o_miso]
set_property IOSTANDARD LVCMOS18 [get_ports o_miso]
set_property DRIVE 12 [get_ports o_miso]
set_property SLEW SLOW [get_ports o_miso]

###############################################################################
# UART: onboard USB-to-UART bridge CP2103GM
# FPGA RX input  <- CP2103 USB_TX
# FPGA TX output -> CP2103 USB_RX
###############################################################################
set_property PACKAGE_PIN AU33 [get_ports i_serial_rx]
set_property IOSTANDARD LVCMOS18 [get_ports i_serial_rx]

set_property PACKAGE_PIN AU36 [get_ports o_serial_tx]
set_property IOSTANDARD LVCMOS18 [get_ports o_serial_tx]
set_property DRIVE 12 [get_ports o_serial_tx]
set_property SLEW SLOW [get_ports o_serial_tx]

###############################################################################
# User LEDs: DS2-DS9, active-high
###############################################################################
set_property PACKAGE_PIN AM39 [get_ports rst_led]
set_property IOSTANDARD LVCMOS18 [get_ports rst_led]
set_property DRIVE 12 [get_ports rst_led]
set_property SLEW SLOW [get_ports rst_led]

set_property PACKAGE_PIN AN39 [get_ports spi_rst_led]
set_property IOSTANDARD LVCMOS18 [get_ports spi_rst_led]
set_property DRIVE 12 [get_ports spi_rst_led]
set_property SLEW SLOW [get_ports spi_rst_led]

set_property PACKAGE_PIN AR37 [get_ports sclk_led]
set_property IOSTANDARD LVCMOS18 [get_ports sclk_led]
set_property DRIVE 12 [get_ports sclk_led]
set_property SLEW SLOW [get_ports sclk_led]

set_property PACKAGE_PIN AT37 [get_ports cs_led]
set_property IOSTANDARD LVCMOS18 [get_ports cs_led]
set_property DRIVE 12 [get_ports cs_led]
set_property SLEW SLOW [get_ports cs_led]

set_property PACKAGE_PIN AR35 [get_ports mosi_led]
set_property IOSTANDARD LVCMOS18 [get_ports mosi_led]
set_property DRIVE 12 [get_ports mosi_led]
set_property SLEW SLOW [get_ports mosi_led]

set_property PACKAGE_PIN AP41 [get_ports miso_led]
set_property IOSTANDARD LVCMOS18 [get_ports miso_led]
set_property DRIVE 12 [get_ports miso_led]
set_property SLEW SLOW [get_ports miso_led]

set_property PACKAGE_PIN AP42 [get_ports tx_led]
set_property IOSTANDARD LVCMOS18 [get_ports tx_led]
set_property DRIVE 12 [get_ports tx_led]
set_property SLEW SLOW [get_ports tx_led]

set_property PACKAGE_PIN AU39 [get_ports rx_led]
set_property IOSTANDARD LVCMOS18 [get_ports rx_led]
set_property DRIVE 12 [get_ports rx_led]
set_property SLEW SLOW [get_ports rx_led]
