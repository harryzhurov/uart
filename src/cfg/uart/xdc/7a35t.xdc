#-------------------------------------------------------------------------------
#   project:       vivado-boilerplate
#   variant:       7a35t
#
#   description:
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

#-------------------------------------------------------------------------------
#    ref_clk
#-------------------------------------------------------------------------------

create_clock -period $REF_CLK_PERIOD [get_ports {ref_clk}]

set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS33} [get_ports {clk}]

#-------------------------------------------------------------------------------
#    Timing
#-------------------------------------------------------------------------------
set_input_delay   -clock clk_ext -max 0.0 [get_ports {rxc}]
set_output_delay  -clock clk_ext -max 0.0 [get_ports {txc}]
#-------------------------------------------------------------------------------
#    Pin locations
#-------------------------------------------------------------------------------

set_property PACKAGE_PIN E3  [get_ports {clk}]
set_property PACKAGE_PIN K17 [get_ports {rxc}]
set_property PACKAGE_PIN K18 [get_ports {txc}]

#-------------------------------------------------------------------------------

set_property IOSTANDARD LVCMOS33 [get_ports {clk}]
set_property IOSTANDARD LVCMOS33 [get_ports {txc}]
set_property IOSTANDARD LVCMOS33 [get_ports {rxc}]

#-------------------------------------------------------------------------------
