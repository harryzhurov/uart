//-------------------------------------------------------------------------------
//
//     Project: Any
//
//     Purpose: Default top-level file
//
//-------------------------------------------------------------------------------

`include "cfg_params.svh"

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
localparam DATA_W = 8;

//------------------------------------------------------------------------------
//
//    Types
//
typedef logic [DATA_W-1:0] data_t;

typedef struct packed
{
    logic   rxc;
    data_t  tx_data;
    logic   tx_wren;
    logic   rx_rden;
    logic   rst_err;
}
inps_t;

typedef struct packed
{
    logic   txc;
    data_t  rx_data;
    logic   tx_empty;
    logic   tx_complete;
    logic   rx_complete;
    logic   frame_error;
    logic   overrun;
}
outs_t;

//------------------------------------------------------------------------------
//
//    Objects
//
logic   txc;
logic   rxc;
data_t  tx_data;
logic   tx_wren;
data_t  rx_data;
logic   rx_rden;
logic   rst_err;
logic   tx_empty;
logic   tx_complete;
logic   rx_complete;
logic   frame_error;
logic   overrun;

inps_t inps;
outs_t outs;

//------------------------------------------------------------------------------
//
//    Functions and tasks
//

//------------------------------------------------------------------------------
//
//    Logic
//
always_ff @(posedge clk) begin
    rxc                   <= inps.rxc;
    tx_data               <= inps.tx_data;
    tx_wren               <= inps.tx_wren;
    rx_rden               <= inps.rx_rden;
    rst_err               <= inps.rst_err;

    inps[0]               <= inp;
    inps[$bits(inps)-1:1] <= inps[$bits(inps)-2:0];
end

always_ff @(posedge clk) begin
    if(tx_empty) begin
        outs.txc          <= txc;
        outs.rx_data      <= rx_data;
        outs.tx_empty     <= tx_empty;
        outs.tx_complete  <= tx_complete;
        outs.rx_complete  <= rx_complete;
        outs.frame_error  <= frame_error;
        outs.overrun      <= overrun;
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
UART_MAIN dut
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

//-------------------------------------------------------------------------------
endmodule : top
//-------------------------------------------------------------------------------
