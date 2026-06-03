//-------------------------------------------------------------------------------
//
//     Project: Any
//
//     Purpose: UDP Rx Testbench
//
//     Author : Matthew S. Grebnev, 2026
//
//-------------------------------------------------------------------------------

`include "uvm_macros.svh"
`include "test.svh"

//-------------------------------------------------------------------------------

interface inp_if;

logic rxc;
logic frame_error;
logic overrun;
logic rx_complete;

endinterface

interface out_if;

logic  clk;
data_t rx_data;
logic  rst_err;
logic  rx_rden;

endinterface

//-------------------------------------------------------------------------------

module automatic top_tb;

import uvm_pkg   ::*;

//-------------------------------------------------------------------------------

logic  clk = 0;
inp_if inp();
out_if out();

//-------------------------------------------------------------------------------

initial begin
    forever #CLK_CYCLE clk = ~clk;
end

assign inp.clk = clk;
assign out.clk = clk;

initial begin
    uvm_config_db #(virtual inp_if )::set(null, "*", "inp", inp);
    uvm_config_db #(virtual out_if )::set(null, "*", "out", out);

    run_test("UartRxTest");
end

//-------------------------------------------------------------------------------
top top_inst
(
.clk            ( out_if.clk         ),
.rxc            ( out_if.rxc         ),
.rx_rden        ( inp_if.rx_rden     ),
.rst_err        ( out_if.rst_err     ),
.rx_data        ( out_if.rx_data     ),
.rx_complete    ( inp_if.rx_complete ),
.frame_error    ( inp_if.frame_error ),
.overrun        ( inp_if.overrun     ),
);
//==================================================
endmodule : top_tb
//==================================================
