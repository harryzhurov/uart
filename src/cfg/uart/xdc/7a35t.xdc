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

create_clock -period 10 -name clk

set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS33} [get_ports clk]

#-------------------------------------------------------------------------------
#    Timing
#-------------------------------------------------------------------------------
set_input_delay   -clock clk -max 0.0 [get_ports {rxc rx_rden tx_wren rst_err tx_data[*]}]
set_output_delay  -clock clk -max 0.0 [get_ports {txc overrun frame_error rx_complete tx_complete tx_empty rx_data[*]}]
#-------------------------------------------------------------------------------
#    Pin locations
#-------------------------------------------------------------------------------

set_property PACKAGE_PIN E3  [get_ports clk         ]
set_property PACKAGE_PIN K17 [get_ports rxc         ]
set_property PACKAGE_PIN K18 [get_ports txc         ]

set_property PACKAGE_PIN P14 [get_ports {tx_data[0]}]
set_property PACKAGE_PIN P15 [get_ports {tx_data[1]}]
set_property PACKAGE_PIN P17 [get_ports {tx_data[2]}]
set_property PACKAGE_PIN P18 [get_ports {tx_data[3]}]
set_property PACKAGE_PIN R12 [get_ports {tx_data[4]}]
set_property PACKAGE_PIN R13 [get_ports {tx_data[5]}]
set_property PACKAGE_PIN R15 [get_ports {tx_data[6]}]
set_property PACKAGE_PIN R16 [get_ports {tx_data[7]}]

set_property PACKAGE_PIN R17 [get_ports {rx_data[0]}]
set_property PACKAGE_PIN R18 [get_ports {rx_data[1]}]
set_property PACKAGE_PIN T9  [get_ports {rx_data[2]}]
set_property PACKAGE_PIN T10 [get_ports {rx_data[3]}]
set_property PACKAGE_PIN T11 [get_ports {rx_data[4]}]
set_property PACKAGE_PIN T13 [get_ports {rx_data[5]}]
set_property PACKAGE_PIN T14 [get_ports {rx_data[6]}]
set_property PACKAGE_PIN T15 [get_ports {rx_data[7]}]

set_property PACKAGE_PIN N14 [get_ports rx_rden     ]
set_property PACKAGE_PIN N16 [get_ports tx_wren     ]
set_property PACKAGE_PIN N17 [get_ports rst_err     ]

set_property PACKAGE_PIN L1  [get_ports tx_empty    ]
set_property PACKAGE_PIN L3  [get_ports frame_error ]
set_property PACKAGE_PIN L4  [get_ports overrun     ]
set_property PACKAGE_PIN L5  [get_ports tx_complete ]
set_property PACKAGE_PIN L6  [get_ports rx_complete ]

#-------------------------------------------------------------------------------

set_property IOSTANDARD LVCMOS33 [get_ports clk        ]
set_property IOSTANDARD LVCMOS33 [get_ports txc        ]
set_property IOSTANDARD LVCMOS33 [get_ports rxc        ]
set_property IOSTANDARD LVCMOS33 [get_ports tx_data[*] ]
set_property IOSTANDARD LVCMOS33 [get_ports rx_data[*] ]
set_property IOSTANDARD LVCMOS33 [get_ports tx_complete]
set_property IOSTANDARD LVCMOS33 [get_ports rx_complete]
set_property IOSTANDARD LVCMOS33 [get_ports tx_wren    ]
set_property IOSTANDARD LVCMOS33 [get_ports rx_rden    ]
set_property IOSTANDARD LVCMOS33 [get_ports tx_empty   ]
set_property IOSTANDARD LVCMOS33 [get_ports rst_err    ]
set_property IOSTANDARD LVCMOS33 [get_ports overrun    ]
set_property IOSTANDARD LVCMOS33 [get_ports frame_error]

#-------------------------------------------------------------------------------
