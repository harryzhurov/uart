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
//-------------------------------------------------------------------------------

interface out_if;

logic   clk;
logic   frame_error;
logic   overrun;
uint8_t rx_data;
logic   rx_complete;

endinterface

interface inp_if;

logic clk;
logic rxc;
logic rst_err;
logic rx_rden;
logic baud_pulse;

endinterface

//-------------------------------------------------------------------------------

module automatic top_tb;

import uvm_pkg::*;

//-------------------------------------------------------------------------------

logic  clk = 0;
logic  baud_pulse = 0;
inp_if inp();
out_if out();

//-------------------------------------------------------------------------------

initial begin
    fork
        begin
            forever #(CLK_CYCLE/2) clk = ~clk;
        end
        begin
            #($urandom_range(0,UART_CYCLE));
            forever begin
                #(UART_CYCLE - CLK_CYCLE) baud_pulse = 1;
                #(CLK_CYCLE)              baud_pulse = 0;
            end
        end
    join
end

assign inp.clk        = clk;
assign out.clk        = clk;
assign inp.baud_pulse = baud_pulse;

initial begin
    uvm_config_db #(virtual inp_if )::set(null, "*", "inp", inp);
    uvm_config_db #(virtual out_if )::set(null, "*", "out", out);

    run_test("UartRxTest");
end

//-------------------------------------------------------------------------------
top top_inst
(
.clk            ( inp.clk         ),
.rxc            ( inp.rxc         ),
.rx_rden        ( inp.rx_rden     ),
.rst_err        ( inp.rst_err     ),
.rx_data        ( out.rx_data     ),
.rx_complete    ( out.rx_complete ),
.frame_error    ( out.frame_error ),
.overrun        ( out.overrun     ),
.baud_pulse     ( inp.baud_pulse  ),
.txc            (                 ),
.tx_empty       (                 ),
.tx_data        (                 ),
.tx_complete    (                 ),
.tx_wren        (                 )
);
//==================================================
endmodule : top_tb
//==================================================
