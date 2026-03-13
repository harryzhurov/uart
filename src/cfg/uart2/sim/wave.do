onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /UART_TESTBENCH/clk
add wave -noupdate /UART_TESTBENCH/txc
add wave -noupdate /UART_TESTBENCH/tx_data
add wave -noupdate /UART_TESTBENCH/tx_wren
add wave -noupdate /UART_TESTBENCH/tx_empty
add wave -noupdate /UART_TESTBENCH/tx_complete
add wave -noupdate /UART_TESTBENCH/rxc
add wave -noupdate /UART_TESTBENCH/rx_complete
add wave -noupdate /UART_TESTBENCH/rx_rden
add wave -noupdate /UART_TESTBENCH/rx_data
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {98045000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 3000
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {4085252096 ps}
