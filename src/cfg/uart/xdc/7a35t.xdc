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

create_clock -period 10 -name clk [get_ports clk]

set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS33} [get_ports clk]

#-------------------------------------------------------------------------------
#    Timing
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#    Pin locations
#-------------------------------------------------------------------------------

set_property PACKAGE_PIN E3  [get_ports clk         ]
set_property PACKAGE_PIN K17 [get_ports inp         ]
set_property PACKAGE_PIN K18 [get_ports out         ]

#-------------------------------------------------------------------------------

set_property IOSTANDARD LVCMOS33 [get_ports clk     ]
set_property IOSTANDARD LVCMOS33 [get_ports inp     ]
set_property IOSTANDARD LVCMOS33 [get_ports out     ]

#-------------------------------------------------------------------------------

#set_false_path -from [get_clocks clk] -to [get_ports txc]
#set_false_path -from [get_ports rxc] -to [get_clocks clk]

