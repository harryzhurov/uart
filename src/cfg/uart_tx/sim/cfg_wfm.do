onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /uart_tb/dut0/clk
add wave -noupdate /uart_tb/dut0/baud_tick
add wave -noupdate -expand -group tx /uart_tb/dut0/txc
add wave -noupdate -expand -group tx /uart_tb/dut0/tx_data
add wave -noupdate -expand -group tx /uart_tb/dut0/tx_wren
add wave -noupdate -expand -group tx /uart_tb/dut0/tx_empty
add wave -noupdate -expand -group tx /uart_tb/dut0/tx_complete
add wave -noupdate -expand -group tx /uart_tb/dut0/tx_state
add wave -noupdate -expand -group rx /uart_tb/dut0/rxc
add wave -noupdate -expand -group rx /uart_tb/dut0/rx_data
add wave -noupdate -expand -group rx /uart_tb/dut0/rx_rden
add wave -noupdate -expand -group rx /uart_tb/dut0/rx_complete
add wave -noupdate -expand -group rx /uart_tb/dut0/frame_error
add wave -noupdate -expand -group rx /uart_tb/dut0/overrun
add wave -noupdate -expand -group rx /uart_tb/dut0/rst_err
add wave -noupdate -expand -group rx /uart_tb/dut0/rx_state
add wave -noupdate /uart_tb/overrun_flag
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
WaveRestoreZoom {86975700379 ps} {86979104802 ps}
