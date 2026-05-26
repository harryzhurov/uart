//=======================================================
//
//      Uart
//
//=======================================================
import params_pkg::*;
//=======================================================
module uart
(
    uart_if ifs
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
always_ff @(posedge ifs.clk) begin
    init[0]     <= 1'b1;
    init[1]     <= init[0];
    init_en <= init[0] && (!init[1]);
end
//-------------------------------------------------------
//
//  Generator of reference frequancy UART
//
always_ff @(posedge ifs.clk) begin
    baud_cnt      <= baud_cnt + 1;
    baud_tick <= 0;
    if (baud_cnt == BIT_PERIOD - 1) begin
        baud_cnt      <= 0;
        baud_tick <= 1;
    end
end
//-------------------------------------------------------
//
//  Control logic block
//
always_ff @(posedge ifs.clk) begin
//-----------------------------------
//  RX Control part
//-----------------------------------
    
    if(init_en) begin
        ifs.rx_complete <= 1'b0;
        ifs.frame_error <= 1'b0;
        ifs.overrun     <= 1'b0;
    end

    if(ifs.rst_err) begin
        ifs.overrun     <= 1'b0;
        ifs.frame_error <= 1'b0;
    end

    if(rx_done)
        ifs.rx_complete <= 1'b1;

    if(ifs.rx_rden)
        ifs.rx_complete <= 1'b0;

    if(rx_done & !ifs.rxc)
        ifs.frame_error <= 1'b1;

    if(rx_done & ifs.rx_complete)
        ifs.overrun <= 1'b1;

//-----------------------------------
//  TX Control part
//-----------------------------------

    ifs.tx_complete <= 1'b0;

    if(init_en)
        ifs.tx_complete <= 1'b0;

    if(tx_done)
        ifs.tx_complete <= 1'b1;
    
end
//=======================================================
//
//          Instances
//
uart_tx u_tx
(
    .clk          ( ifs.clk          ),
    .baud_tick    ( baud_tick        ),
    .txc          ( ifs.txc          ),
    .tx_data      ( ifs.tx_data      ),
    .tx_wren      ( ifs.tx_wren      ),
    .tx_empty     ( ifs.tx_empty     ),
    .tx_done      ( tx_done          ),
    .init_en      ( init_en          )
);

uart_rx u_rx
(
    .clk          ( ifs.clk          ),
    .rxc          ( ifs.rxc          ),
    .rx_data      ( ifs.rx_data      ),
    .rx_done      ( rx_done          ),
    .init_en      ( init_en          )
);
//=======================================================
endmodule : uart
//=======================================================
