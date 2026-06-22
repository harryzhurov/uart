//-------------------------------------------------------------------------------
//
//     Project: Any
//
//     Purpose: UDP Rx Testbench
//
//     Author : Matthew S. Grebnev, 2026
//
//-------------------------------------------------------------------------------

`define SIMULATOR

`include "uvm_macros.svh"
`include "test.svh"

interface clk_if;
    logic clk;
    logic baud_pulse;
endinterface
//-------------------------------------------------------------------------------
module automatic top_tb;

import uvm_pkg::*;
//-------------------------------------------------------------------------------
clk_if  cv();
uart_if pld();
//-------------------------------------------------------------------------------

initial begin
    cv.clk        = 0;
    cv.baud_pulse = 0;
    fork
        begin
            forever #(CLK_CYCLE/2) cv.clk = ~cv.clk;
        end
        begin
            #($urandom_range(0,UART_CYCLE));
            forever begin
                #(UART_CYCLE - CLK_CYCLE) cv.baud_pulse = 1;
                #(CLK_CYCLE)              cv.baud_pulse = 0;
            end
        end
    join
end

initial begin
    uvm_config_db #(virtual uart_if )::set(null, "*", "pld", pld);
    uvm_config_db #(virtual clk_if )::set(null, "*", "cv", cv);
    run_test("UartTest");
end

//-------------------------------------------------------------------------------
uart dut
(
.clk   ( cv.clk ),
.pld   ( pld    )
);
//==================================================
endmodule : top_tb
//==================================================
