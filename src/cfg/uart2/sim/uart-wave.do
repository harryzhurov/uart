onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_uart/clk
add wave -noupdate /tb_uart/txc
add wave -noupdate /tb_uart/rxc
add wave -noupdate /tb_uart/tx_data
add wave -noupdate /tb_uart/tx_wren
add wave -noupdate /tb_uart/rx_data
add wave -noupdate /tb_uart/rx_rden
add wave -noupdate /tb_uart/rst_err
add wave -noupdate /tb_uart/tx_empty
add wave -noupdate /tb_uart/tx_complete
add wave -noupdate /tb_uart/rx_complete
add wave -noupdate /tb_uart/frame_error
add wave -noupdate /tb_uart/overrun
add wave -noupdate -expand -group tx /tb_uart/dut/tx_state
add wave -noupdate -expand -group tx /tb_uart/dut/tx_buffer
add wave -noupdate -expand -group tx /tb_uart/dut/tx_shift
add wave -noupdate -expand -group tx /tb_uart/dut/tx_bit_cnt
add wave -noupdate /tb_uart/dut/baud_cnt
add wave -noupdate /tb_uart/dut/baud_tick
add wave -noupdate -expand -group rx /tb_uart/dut/rx_state
add wave -noupdate -expand -group rx /tb_uart/dut/rx_timer
add wave -noupdate -expand -group rx /tb_uart/dut/rx_bit_cnt
add wave -noupdate -expand -group rx /tb_uart/dut/rx_shift
add wave -noupdate -expand -group rx /tb_uart/dut/rx_data_reg
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {347240543 ps} 0}
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
WaveRestoreZoom {0 ps} {1021313024 ps}
