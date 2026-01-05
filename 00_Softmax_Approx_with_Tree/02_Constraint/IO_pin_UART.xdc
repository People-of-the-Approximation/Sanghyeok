set_property -dict { PACKAGE_PIN E3 IOSTANDARD LVCMOS33 } [get_ports { i_clk }];
create_clock -add -name sys_clk_pin -period 10.000 [get_ports { i_clk }];
# clk pin : E3
# 100 MHz

set_property -dict { PACKAGE_PIN C12 IOSTANDARD LVCMOS33 } [get_ports { i_rstn }];
# rst : C12

set_property -dict { PACKAGE_PIN C4 IOSTANDARD LVCMOS33 } [get_ports { i_rxd }];
set_property -dict { PACKAGE_PIN D4 IOSTANDARD LVCMOS33 } [get_ports { o_txd }];
# rx pin : C4
# tx pin : D4

## LEDs
set_property -dict { PACKAGE_PIN H17   IOSTANDARD LVCMOS33 } [get_ports { o_led[0] }]; # LED 0
set_property -dict { PACKAGE_PIN K15   IOSTANDARD LVCMOS33 } [get_ports { o_led[1] }]; # LED 1
set_property -dict { PACKAGE_PIN J13   IOSTANDARD LVCMOS33 } [get_ports { o_led[2] }]; # LED 2
set_property -dict { PACKAGE_PIN N14   IOSTANDARD LVCMOS33 } [get_ports { o_led[3] }]; # LED 3

set_property -dict { PACKAGE_PIN R18   IOSTANDARD LVCMOS33 } [get_ports { o_led_busy }]; # LED busy