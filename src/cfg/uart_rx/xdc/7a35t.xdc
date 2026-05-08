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

#create_clock -period $REF_CLK_PERIOD [get_ports ref_clk]
create_clock -period $REF_CLK_PERIOD -name ref_clk -waveform "0.000 $REF_CLK_HALF_PERIOD" [get_ports clk]

set_switching_activity -deassert_resets

#-------------------------------------------------------------------------------
#    Timing
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#    Pin locations
#-------------------------------------------------------------------------------

set_property PACKAGE_PIN E3  [get_ports clk]
set_property PACKAGE_PIN K17 [get_ports inp]
set_property PACKAGE_PIN K18 [get_ports out]

#-------------------------------------------------------------------------------

set_property IOSTANDARD LVCMOS33 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports inp]
set_property IOSTANDARD LVCMOS33 [get_ports out]

#-------------------------------------------------------------------------------

