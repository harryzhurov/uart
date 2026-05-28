onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider {UART RX INTERFACE}
add wave -noupdate /uart_tb/top_inst/clk
add wave -noupdate /uart_tb/top_inst/rst_err
add wave -noupdate -divider DATA
add wave -noupdate /uart_tb/top_inst/rxc
add wave -noupdate /uart_tb/top_inst/rx_data
add wave -noupdate -divider FLAGS
add wave -noupdate /uart_tb/top_inst/rx_complete
add wave -noupdate /uart_tb/top_inst/frame_error
add wave -noupdate /uart_tb/top_inst/rx_rden
add wave -noupdate /uart_tb/top_inst/overrun
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 259
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
WaveRestoreZoom {0 ps} {149545636800 ps}
