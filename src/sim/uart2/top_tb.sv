`timescale 1ns / 1ps
//===================================================================================
import params_pkg::*;
import tb_components_pkg::*;
//===================================================================================
module uart_tb;
//---------------------------interface instance-------------------------------------
//===================================================================================
//
// Inteface signals
//
logic clk          = 0;
logic baud_pulse   = 0;
//===================================================================================
uart_if uart_interface
(
    .clk        ( clk        ),
    .baud_pulse ( baud_pulse )
);
//
//      Test body
//
//--------------------------------------------
// Generator 100 MHz

initial begin
    clk = 0;
    forever #(CLK_CYCLE/2) clk = ~clk;
end
//--------------------------------------------
// Baud pulse generator

initial begin
    baud_pulse = 0;
    forever begin
        #(UART_CYCLE - CLK_CYCLE) baud_pulse = 1;
        #(CLK_CYCLE)              baud_pulse = 0;
    end
end
//--------------------------------------------
// Initialization

task automatic init();
    
    uart_interface.tx_data = 8'h00;
    uart_interface.rxc     = 1;
    uart_interface.tx_wren = 0;
    uart_interface.rx_rden = 0;
    uart_interface.rst_err = 0;
    
    #UART_CYCLE;
    
endtask
//--------------------------------------------
// Test

Environment env;

initial begin

    env = new(uart_interface);
    
    init();
    
    env.run();

end

//===================================================================================
//
//      Instances
//
//-----------------------------uart.sv instance--------------------------------------
uart dut0
(
    .clk         ( clk                        ),
    .txc         ( uart_interface.txc         ),
    .rxc         ( uart_interface.rxc         ),
    .tx_data     ( uart_interface.tx_data     ),
    .tx_wren     ( uart_interface.tx_wren     ),
    .rx_data     ( uart_interface.rx_data     ),
    .rx_rden     ( uart_interface.rx_rden     ),
    .tx_empty    ( uart_interface.tx_empty    ),
    .tx_complete ( uart_interface.tx_complete ),
    .rx_complete ( uart_interface.rx_complete ),
    .frame_error ( uart_interface.frame_error ),
    .overrun     ( uart_interface.overrun     ),
    .rst_err     ( uart_interface.rst_err     )
);
//===================================================================================
endmodule : uart_tb
//===================================================================================
