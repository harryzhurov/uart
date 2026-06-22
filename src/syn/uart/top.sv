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
//------------------------------------------------------------------------------
//
//    Types
//
typedef struct packed
{
    logic       rxc    ;
    logic       rx_rden;
    logic       rst_err;
    logic       tx_wren;
    logic [7:0] tx_data;
}
inps_t;

typedef struct packed
{
    logic [7:0] rx_data    ;
    logic       rx_complete;
    logic       frame_error;
    logic       overrun    ;
    logic       txc        ;
    logic       tx_empty   ;
    logic       tx_complete;
}
outs_t;
//------------------------------------------------------------------------------
//
//    Objects
//
inps_t inps;
outs_t outs;

uart_if dut();

//------------------------------------------------------------------------------
//
//    Functions and tasks
//

//------------------------------------------------------------------------------
//
//    Logic
//
always_ff @(posedge clk) begin
    dut.rxc     <= inps.rxc    ;
    dut.rx_rden <= inps.rx_rden;
    dut.rst_err <= inps.rst_err;
    dut.tx_wren <= inps.tx_wren;
    dut.tx_data <= inps.tx_data;

    inps[$bits(inps)-1:1]  <= inps[$bits(inps)-2:0];
    inps[0]   <= inp;
end

always_ff @(posedge clk) begin

    if(inp) begin
    outs.rx_data     <= dut.rx_data    ;
    outs.rx_complete <= dut.rx_complete;
    outs.frame_error <= dut.frame_error;
    outs.overrun     <= dut.overrun    ;
    outs.txc         <= dut.txc        ;
    outs.tx_empty    <= dut.tx_empty   ;
    outs.tx_complete <= dut.tx_complete;

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
    .clk ( clk ),
    .pld ( dut )
);
//-------------------------------------------------------------------------------
endmodule : top
//-------------------------------------------------------------------------------
