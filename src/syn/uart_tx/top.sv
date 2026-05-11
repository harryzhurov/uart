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
    data_t  tx_data;
    logic   tx_wren;
}
inps_t;

typedef struct packed
{
    logic   txc;
    logic   tx_empty;
    logic   tx_complete;
}
outs_t;

//------------------------------------------------------------------------------
//
//    Objects
//
logic   txc;
data_t  tx_data;
logic   tx_wren;
logic   tx_empty;
logic   tx_complete;

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
    tx_data               <= inps.tx_data;
    tx_wren               <= inps.tx_wren;

    inps[0]               <= inp;
    inps[$bits(inps)-1:1] <= inps[$bits(inps)-2:0];
end

always_ff @(posedge clk) begin
    if(tx_empty) begin
        outs.txc          <= txc;
        outs.tx_empty     <= tx_empty;
        outs.tx_complete  <= tx_complete;
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
uart dut
(
    .clk         ( clk         ),
    .txc         ( txc         ),
    .tx_data     ( tx_data     ),
    .tx_wren     ( tx_wren     ),
    .tx_empty    ( tx_empty    ),
    .tx_complete ( tx_complete )
);

//-------------------------------------------------------------------------------
endmodule : top
//-------------------------------------------------------------------------------
