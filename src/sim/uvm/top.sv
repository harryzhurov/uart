//==================================================
module top_tb;
//==================================================
import uvm_pkg   ::*;
import params_pkg::*;

virtual dut_if vif;

top top_inst
(
.clk            ( vif.clk         ),
.rxc            ( vif.rxc         ),
.rx_rden        ( vif.rx_rden     ),
.rst_err        ( vif.rst_err     ),
.rx_data        ( vif.rx_data     ),
.rx_complete    ( vif.rx_complete ),
.frame_error    ( vif.frame_error ),
.overrun        ( vif.overrun     ),
.tx_wren        ( vif.tx_wren     ),
.tx_data        ( vif.tx_data     ),
.txc            ( vif.txc         ),
.tx_empty       ( vif.tx_empty    ),
.tx_complete    ( vif.tx_complete )
);
//==================================================
endmodule
//==================================================
