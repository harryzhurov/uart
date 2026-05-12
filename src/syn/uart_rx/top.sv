//-------------------------------------------------------------------------------
//
//     Project: Any
//
//     Purpose: Default top-level file
//
//-------------------------------------------------------------------------------

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
    logic   rx_rden;
    logic   rst_err;
}
inps_t;

typedef struct packed
{
    data_t  rx_data;
    logic   rx_complete;
    logic   frame_error;
    logic   overrun;
}
outs_t;

//------------------------------------------------------------------------------
//
//    Objects
//
logic   rxc;
data_t  rx_data;
logic   rx_rden;
logic   rst_err;
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
    rx_rden               <= inps.rx_rden;
    rst_err               <= inps.rst_err;

    inps[0]               <= inp;
    inps[$bits(inps)-1:1] <= inps[$bits(inps)-2:0];
end

always_ff @(posedge clk) begin
    outs.rx_data      <= rx_data;
    outs.rx_complete  <= rx_complete;
    outs.frame_error  <= frame_error;
    outs.overrun      <= overrun;
    out               <= outs[0];
    outs              <= outs >> 1;
end

//------------------------------------------------------------------------------
//
//    Instances
//
uart dut
(
    .clk         ( clk         ),
    .rxc         ( rxc         ),
    .rx_data     ( rx_data     ),
    .rx_rden     ( rx_rden     ),
    .rx_complete ( rx_complete ),
    .frame_error ( frame_error ),
    .overrun     ( overrun     ),
    .rst_err     ( rst_err     )
);

//-------------------------------------------------------------------------------
endmodule : top
//-------------------------------------------------------------------------------
