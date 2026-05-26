//-------------------------------------------------------------------------------
//
//     Project: Any
//
//     Purpose: Default top-level file
//
//-------------------------------------------------------------------------------

module automatic top
(
    input        clk,

    input        rxc,
    input        rx_rden,
    input        rst_err,
    output [7:0] rx_data,
    output       rx_complete,
    output       frame_error,
    output       overrun,

    input        tx_wren,
    input  [7:0] tx_data,
    output       txc,
    output       tx_empty,
    output       tx_complete
);
//------------------------------------------------------------------------------
//
//    Settings
//
uart_if uif ();
//------------------------------------------------------------------------------
//
//    Types
//

//------------------------------------------------------------------------------
//
//    Objects
//

//------------------------------------------------------------------------------
//
//    Functions and tasks
//

//------------------------------------------------------------------------------
//
//    Logic
//
assign uif.clk          = clk;
assign uif.rxc          = rxc;
assign uif.rst_err      = rst_err;
assign uif.tx_wren      = tx_wren;
assign uif.rx_rden      = rx_rden;
assign uif.tx_data      = tx_data;
assign txc              = uif.txc;
assign rx_data          = uif.rx_data;
assign tx_empty         = uif.tx_empty;
assign overrun          = uif.overrun;
assign frame_error      = uif.frame_error;
assign tx_complete      = uif.tx_complete;
assign rx_complete      = uif.rx_complete;

//------------------------------------------------------------------------------
//
//    Instances
//
uart uart_inst
(
    .ifs ( uif.uart_mp )
);
//-------------------------------------------------------------------------------
endmodule : top
//-------------------------------------------------------------------------------
