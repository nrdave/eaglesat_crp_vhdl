set_property IOSTANDARD LVCMOS33 [get_ports sysclk]
set_property PACKAGE_PIN L17 [get_ports sysclk]

set_property IOSTANDARD LVCMOS33 [get_ports CAM0_TX]

set_property IOSTANDARD LVCMOS33 [get_ports OBC_RX]
set_property IOSTANDARD LVCMOS33 [get_ports OBC_TX]
set_property PACKAGE_PIN R3 [get_ports OBC_RX]
set_property PACKAGE_PIN T3 [get_ports OBC_TX]

set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]

set_property PACKAGE_PIN M1 [get_ports CAM1_TX]

set_property IOSTANDARD LVCMOS33 [get_ports CAM1_TX]

set_property PACKAGE_PIN V2 [get_ports CAM0_reset]
set_property PACKAGE_PIN W3 [get_ports CAM1_reset]

set_property IOSTANDARD LVCMOS33 [get_ports CAM0_reset]
set_property IOSTANDARD LVCMOS33 [get_ports CAM1_reset]

set_property IOSTANDARD LVCMOS33 [get_ports CAM2_reset]
set_property IOSTANDARD LVCMOS33 [get_ports CAM2_tx]
set_property IOSTANDARD LVCMOS33 [get_ports CAM3_reset]
set_property IOSTANDARD LVCMOS33 [get_ports CAM3_TX]
set_property IOSTANDARD LVCMOS33 [get_ports CAM4_reset]
set_property IOSTANDARD LVCMOS33 [get_ports CAM4_TX]
set_property IOSTANDARD LVCMOS33 [get_ports CAM5_reset]
set_property IOSTANDARD LVCMOS33 [get_ports CAM5_tx]
set_property IOSTANDARD LVCMOS33 [get_ports CAM6_reset]
set_property IOSTANDARD LVCMOS33 [get_ports CAM6_tx]
set_property IOSTANDARD LVCMOS33 [get_ports CAM7_reset]
set_property IOSTANDARD LVCMOS33 [get_ports CAM7_tx]
set_property PACKAGE_PIN V3 [get_ports CAM2_reset]
set_property PACKAGE_PIN W5 [get_ports CAM3_reset]
set_property PACKAGE_PIN V4 [get_ports CAM4_reset]
set_property PACKAGE_PIN U4 [get_ports CAM5_reset]
set_property PACKAGE_PIN V5 [get_ports CAM6_reset]
set_property PACKAGE_PIN W4 [get_ports CAM7_reset]


create_clock -period 41.667 -name sysclk -waveform {0.000 20.834} [get_ports sysclk]




set_property IOSTANDARD LVCMOS33 [get_ports CAM0_RX]
set_property PACKAGE_PIN B15 [get_ports CAM0_RX]
set_property IOSTANDARD LVCMOS33 [get_ports CAM1_RX]
set_property IOSTANDARD LVCMOS33 [get_ports CAM2_RX]
set_property PACKAGE_PIN H1 [get_ports CAM2_RX]
set_property PACKAGE_PIN K3 [get_ports CAM4_RX]
set_property IOSTANDARD LVCMOS33 [get_ports CAM4_RX]
set_property IOSTANDARD LVCMOS33 [get_ports CAM5_RX]
set_property IOSTANDARD LVCMOS33 [get_ports CAM3_RX]
set_property IOSTANDARD LVCMOS33 [get_ports CAM7_RX]
set_property IOSTANDARD LVCMOS33 [get_ports MANUAL_RESET_0]
set_property IOSTANDARD LVCMOS33 [get_ports MANUAL_RESET_1]
set_property IOSTANDARD LVCMOS33 [get_ports MANUAL_RESET_2]
set_property IOSTANDARD LVCMOS33 [get_ports MANUAL_RESET_3]
set_property IOSTANDARD LVCMOS33 [get_ports MANUAL_RESET_4]
set_property IOSTANDARD LVCMOS33 [get_ports MANUAL_RESET_6]
set_property IOSTANDARD LVCMOS33 [get_ports MANUAL_RESET_7]
set_property IOSTANDARD LVCMOS33 [get_ports MANUAL_RESET_5]
set_property IOSTANDARD LVCMOS33 [get_ports CAM6_RX]
set_property PACKAGE_PIN U5 [get_ports MANUAL_RESET_0]
set_property PACKAGE_PIN U2 [get_ports MANUAL_RESET_1]
set_property PACKAGE_PIN W6 [get_ports MANUAL_RESET_2]
set_property PACKAGE_PIN U3 [get_ports MANUAL_RESET_3]
set_property PACKAGE_PIN U7 [get_ports MANUAL_RESET_4]
set_property PACKAGE_PIN U8 [get_ports MANUAL_RESET_6]
set_property PACKAGE_PIN V8 [get_ports MANUAL_RESET_7]

set_property PACKAGE_PIN W7 [get_ports MANUAL_RESET_5]

set_property IOSTANDARD LVCMOS33 [get_ports LED0B]
set_property IOSTANDARD LVCMOS33 [get_ports LED0G]
set_property IOSTANDARD LVCMOS33 [get_ports LED0R]
set_property IOSTANDARD LVCMOS33 [get_ports LED1]
set_property IOSTANDARD LVCMOS33 [get_ports LED2]
set_property PACKAGE_PIN B17 [get_ports LED0B]
set_property PACKAGE_PIN B16 [get_ports LED0G]
set_property PACKAGE_PIN C17 [get_ports LED0R]
set_property PACKAGE_PIN A17 [get_ports LED1]
set_property PACKAGE_PIN C16 [get_ports LED2]

set_property PACKAGE_PIN N3 [get_ports CAM0_TX]
set_property PACKAGE_PIN A15 [get_ports CAM1_RX]
set_property PACKAGE_PIN L2 [get_ports CAM2_tx]
set_property PACKAGE_PIN C15 [get_ports CAM3_RX]
set_property PACKAGE_PIN L1 [get_ports CAM3_TX]
set_property PACKAGE_PIN K2 [get_ports CAM4_TX]
set_property PACKAGE_PIN A16 [get_ports CAM5_RX]
set_property PACKAGE_PIN J1 [get_ports CAM5_tx]
set_property PACKAGE_PIN L3 [get_ports CAM6_RX]
set_property PACKAGE_PIN J3 [get_ports CAM6_tx]
set_property PACKAGE_PIN M3 [get_ports CAM7_RX]
set_property PACKAGE_PIN A14 [get_ports CAM7_tx]