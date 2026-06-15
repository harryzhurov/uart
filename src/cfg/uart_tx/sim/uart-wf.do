onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider {UART INTERFACE TX}
add wave -noupdate /top_tb/top_inst/clk
add wave -noupdate -divider DATA
add wave -noupdate /top_tb/top_inst/tx_data
add wave -noupdate /top_tb/top_inst/txc
add wave -noupdate -divider FLAGS
add wave -noupdate /top_tb/top_inst/tx_wren
add wave -noupdate /top_tb/top_inst/tx_empty
add wave -noupdate /top_tb/top_inst/tx_complete
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
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
WaveRestoreZoom {7821677507 ps} {35423574823 ps}
