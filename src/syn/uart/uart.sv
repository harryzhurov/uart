//=======================================================
//
//      Uart
//
//=======================================================
import params_pkg::*;
//=======================================================
module automatic uart
(
    input logic clk,
    uart_if.s   pld
);
//=======================================================
//
//          Params
//
//=======================================================
//
//          Types
//
//=======================================================
//
//          Logic
//
logic [9:0] baud_cnt  = 0;
logic       baud_tick = 0;
logic [1:0] init      = 0;
logic       init_en   = 0;
logic       rx_done;
logic       tx_done;
//=======================================================
//
//          Process
//
//-------------------------------------------------------
//
//  Initialization
//
always_ff @(posedge clk) begin
    init[0] <= 1;
    init[1] <= init[0];
    init_en <= init[0] && (!init[1]);
end
//-------------------------------------------------------
//
//  Generator of reference frequancy UART
//
always_ff @(posedge clk) begin
    baud_cnt  <= baud_cnt + 1;
    baud_tick <= 0;
    if (baud_cnt == BIT_PERIOD - 1) begin
        baud_cnt  <= 0;
        baud_tick <= 1;
    end
end
//-------------------------------------------------------
//
//  Control logic block
//
always_ff @(posedge clk) begin
//-----------------------------------
//  RX Control part
//-----------------------------------

    if(init_en) begin
        pld.rx_complete <= 1'b0;
        pld.frame_error <= 1'b0;
        pld.overrun     <= 1'b0;
    end

    if(pld.rst_err) begin
        pld.overrun     <= 1'b0;
        pld.frame_error <= 1'b0;
    end

    if(rx_done)
        pld.rx_complete <= 1'b1;

    if(pld.rx_rden)
        pld.rx_complete <= 1'b0;

    if(rx_done & !pld.rxc)
        pld.frame_error <= 1'b1;

    if(rx_done & pld.rx_complete)
        pld.overrun <= 1'b1;

//-----------------------------------
//  TX Control part
//-----------------------------------

    pld.tx_complete <= 1'b0;

    if(init_en)
        pld.tx_complete <= 1'b0;

    if(tx_done)
        pld.tx_complete <= 1'b1;

end
//=======================================================
//
//          Instances
//
uart_tx u_tx
(
    .clk          ( clk          ),
    .baud_tick    ( baud_tick    ),
    .txc          ( pld.txc      ),
    .tx_data      ( pld.tx_data  ),
    .tx_wren      ( pld.tx_wren  ),
    .tx_empty     ( pld.tx_empty ),
    .tx_done      ( tx_done      ),
    .init_en      ( init_en      )
);

uart_rx u_rx
(
    .clk          ( clk          ),
    .rxc          ( pld.rxc      ),
    .rx_data      ( pld.rx_data  ),
    .rx_done      ( rx_done      ),
    .init_en      ( init_en      )
);
//=======================================================
endmodule : uart
//=======================================================
