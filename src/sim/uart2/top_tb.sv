`timescale 1ns / 1ps
//===================================================================================
import tb_components_pkg::*;
//===================================================================================
module uart_tb;
//===================================================================================

//
//      Signals
//
//---------------------------------------------
// UART interface

logic            clk;
logic [WORD-1:0] tx_data;
logic [WORD-1:0] rx_data;
logic            txc;
logic            rxc;
logic            tx_wren;
logic            rx_rden;
logic            rst_err;
logic            tx_empty;
logic            tx_complete;
logic            rx_complete;
logic            frame_error;
logic            overrun;
//---------------------------------------------
// Internal signals

logic            overrun_flag       = 0;
logic            baud_pulse         = 0;
int              err                = 0;
//===================================================================================
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
    
    tx_data = 8'h00;
    rxc     = 1;
    tx_wren = 0;
    rx_rden = 0;
    rst_err = 0;
    
    #UART_CYCLE;
    
endtask
//--------------------------------------------
// Test

initial begin

    env = new();
    
    init();
    
    env.run();

end

//===================================================================================
//
//      Instances
//
uart dut0
(
    .clk         ( clk         ),
    .txc         ( txc         ),
    .rxc         ( rxc         ),
    .tx_data     ( tx_data     ),
    .tx_wren     ( tx_wren     ),
    .rx_data     ( rx_data     ),
    .rx_rden     ( rx_rden     ),
    .tx_empty    ( tx_empty    ),
    .tx_complete ( tx_complete ),
    .rx_complete ( rx_complete ),
    .frame_error ( frame_error ),
    .overrun     ( overrun     ),
    .rst_err     ( rst_err     )
);
//===================================================================================
endmodule : uart_tb
//===================================================================================
