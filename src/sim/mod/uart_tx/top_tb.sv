`timescale 1ns / 1ps
//===================================================================================
import params_pkg::*;
import tb_components_pkg::*;
//===================================================================================
module uart_tb;
//===================================================================================
uart_if ifs();
//===================================================================================
//
//      Test body
//
//--------------------------------------------
// Virtual interface
virtual uart_if vif = ifs;
//--------------------------------------------
// Generator 100 MHz

initial begin
    vif.clk = 0;
    forever #(CLK_CYCLE/2) vif.clk = ~vif.clk;
end
//--------------------------------------------
// Baud pulse generator

initial begin
    vif.baud_pulse = 0;
    forever begin
        #(UART_CYCLE - CLK_CYCLE) vif.baud_pulse = 1;
        #(CLK_CYCLE)              vif.baud_pulse = 0;
    end
end
//--------------------------------------------
// Initialization

task automatic init();
    
    vif.tx_data = 8'h00;
    vif.tx_wren = 0;
    
    #UART_CYCLE;
    
endtask
//--------------------------------------------
// Test

Environment env;

initial begin

    env = new(vif);
    
    init();
    
    env.run();

end

//===================================================================================
//
//      Instances
//
//-----------------------------uart.sv instance--------------------------------------
top top_inst
(
    .clk            ( ifs.clk         ),
    .rxc            ( ifs.rxc         ),
    .rx_rden        ( ifs.rx_rden     ),
    .rst_err        ( ifs.rst_err     ),
    .rx_data        ( ifs.rx_data     ),
    .rx_complete    ( ifs.rx_complete ),
    .frame_error    ( ifs.frame_error ),
    .overrun        ( ifs.overrun     ),
    .tx_wren        ( ifs.tx_wren     ),
    .tx_data        ( ifs.tx_data     ),
    .txc            ( ifs.txc         ),
    .tx_empty       ( ifs.tx_empty    ),
    .tx_complete    ( ifs.tx_complete )

);
//===================================================================================
endmodule : uart_tb
//===================================================================================
