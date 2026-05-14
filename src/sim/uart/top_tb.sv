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
    vif.tb_mp.baud_pulse = 0;
    forever begin
        #(UART_CYCLE - CLK_CYCLE) vif.baud_pulse = 1;
        #(CLK_CYCLE)              vif.baud_pulse = 0;
    end
end
//--------------------------------------------
// Initialization

task automatic init();

    vif.rxc         = 1;
    vif.rx_rden     = 0;
    vif.rst_err     = 0;
    vif.tx_data     = 8'h00;
    vif.tx_wren     = 0;

    #CLK_CYCLE;

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
uart dut0
(
    .ifs ( ifs )
);
//===================================================================================
endmodule : uart_tb
//===================================================================================
