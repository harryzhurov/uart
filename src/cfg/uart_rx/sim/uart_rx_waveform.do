onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider -height 25 {***UART RX***}
add wave -noupdate -divider CLOCKS
add wave -noupdate /top_tb/top_inst/clk
add wave -noupdate /top_tb/baud_pulse
add wave -noupdate -divider INPUTS
add wave -noupdate /top_tb/top_inst/rxc
add wave -noupdate /top_tb/top_inst/rx_rden
add wave -noupdate /top_tb/top_inst/rst_err
add wave -noupdate -divider OUTPUTS
add wave -noupdate /top_tb/top_inst/rx_data
add wave -noupdate /top_tb/top_inst/rx_complete
add wave -noupdate /top_tb/top_inst/frame_error
add wave -noupdate /top_tb/top_inst/overrun
add wave -noupdate -divider -height 25 {***UART RX***}
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {5691193869 ps} 0} {{Cursor 2} {5049622000 ps} 0}
quietly wave cursor active 2
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {3925057534 ps} {6878610991 ps}
