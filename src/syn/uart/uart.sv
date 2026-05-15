//=======================================================
//
//      Uart
//
//=======================================================
import params_pkg::*;
//=======================================================
module uart
(
    uart_if.uart_mp ifs
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
logic [9:0] baud_cnt        = 0;
logic [1:0] init            = 0;
//=======================================================
//
//          Process
//
//-------------------------------------------------------
//
//  Initialization
//
always_ff @(posedge ifs.clk) begin
    init[0] <= 1'b1;
    init[1] <= init[0];
    ifs.init_en <= init[0] && (!init[1]);
end
//-------------------------------------------------------
//
//  Generator of reference frequancy UART
//
always_ff @(posedge ifs.clk) begin
    baud_cnt  <= baud_cnt + 1;
    ifs.baud_tick <= 0;
    if (baud_cnt == BIT_PERIOD - 1) begin
        baud_cnt  <= 0;
        ifs.baud_tick <= 1;
    end
end
//=======================================================
//
//          Instances
//
uart_tx u_tx
(
    .clk         ( ifs.clk         ),
    .baud_tick   ( ifs.baud_tick   ),
    .init_en     ( ifs.init_en     ),
    .txc         ( ifs.txc         ),
    .tx_data     ( ifs.tx_data     ),
    .tx_wren     ( ifs.tx_wren     ),
    .tx_empty    ( ifs.tx_empty    ),
    .tx_complete ( ifs.tx_complete )
);

uart_rx u_rx
(
    .clk         ( ifs.clk         ),
    .baud_tick   ( ifs.baud_tick   ),
    .init_en     ( ifs.init_en     ),
    .rxc         ( ifs.rxc         ),
    .rx_data     ( ifs.rx_data     ),
    .rx_rden     ( ifs.rx_rden     ),
    .rx_complete ( ifs.rx_complete ),
    .frame_error ( ifs.frame_error ),
    .overrun     ( ifs.overrun     ),
    .rst_err     ( ifs.rst_err     )
);
//=======================================================
endmodule : uart
//=======================================================
