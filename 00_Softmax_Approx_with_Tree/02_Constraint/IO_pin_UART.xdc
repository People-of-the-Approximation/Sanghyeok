set_property -dict { PACKAGE_PIN E3 IOSTANDARD LVCMOS33 } [get_ports { i_clk }];
create_clock -add -name sys_clk_pin -period 10.000 [get_ports { i_clk }];
# clk pin : E3
# 100 MHz

set_property -dict { PACKAGE_PIN C12 IOSTANDARD LVCMOS33 } [get_ports { i_rst }];
# rst : C12