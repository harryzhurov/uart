//-------------------------------------------------------------------------------
//
//     Project: Any
//
//     Purpose: Default top-level file
//
//-------------------------------------------------------------------------------
import params_pkg::*;

module automatic top
(
    input  logic clk,

    input  logic inp,
    output logic out
);
//------------------------------------------------------------------------------
//
//    Settings
//
//------------------------------------------------------------------------------
//
//    Types
//
typedef struct packed
{
    logic            rxc;
    logic            rx_rden;
    logic            rst_err;
    logic            tx_wren;
    logic [WORD-1:0] tx_data;
}
inps_t;

typedef struct packed
{
    logic            txc;
    logic            tx_complete;
    logic            tx_empty;
    logic            rx_complete;
    logic            frame_error;
    logic            overrun;
    logic [WORD-1:0] rx_data;
}
outs_t;
//------------------------------------------------------------------------------
//
//    Objects
//
uart_if uif();
inps_t  inps;
outs_t  outs;
//------------------------------------------------------------------------------
//
//    Functions and tasks
//

//------------------------------------------------------------------------------
//
//    Logic
//

assign uif.clk = clk;

always_ff @(posedge clk) begin

    uif.rxc     <= inps.rxc;
    uif.rx_rden <= inps.rx_rden;
    uif.rst_err <= inps.rst_err;
    uif.tx_wren <= inps.tx_wren;
    uif.tx_data <= inps.tx_data;

    inps[$bits(inps)-1:1] <= inps[$bits(inps)-2:0];
    inps[0] <= inp;
end

always_ff @(posedge clk) begin

    if(inp) begin
        outs.txc         <= uif.txc;
        outs.tx_complete <= uif.tx_complete;
        outs.tx_empty    <= uif.tx_empty;
        outs.rx_complete <= uif.rx_complete;
        outs.frame_error <= uif.frame_error;
        outs.overrun     <= uif.overrun;
        outs.rx_data     <= uif.rx_data;
    end
    else begin
        out  <= outs[0];
        outs <= outs >> 1;
    end
end
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
