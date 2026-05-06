//===================================================================================
package trn_cfg_pkg;
//===================================================================================
//
//      Number of transactions
//
localparam num_trn_tx          = 200;
localparam num_trn_rx          = 200;
//===================================================================================
//
//      Tx setting
//
localparam zero_data_tx        = 1;       // probability of data = 2'h00--------------------------\ (%)
localparam send_del_exist_tx   = 4;       // probobility of delay existance before data sending --/
localparam send_del_dist_tx    = 10000;   // in range [0:10000] clk 

//===================================================================================
//
//      Rx setting
//
localparam wrong_stop_exist_rx = 2;       // probability of stop bit = 0-------------------------------\                               
localparam send_del_exist_rx   = 10;      // probability of delay existance before data sending         \ (%)
localparam rden_del_exist_rx   = 8;       // probability of delay existance before rx_rden flag sending /
localparam zero_data_rx        = 6;       // probability of data = 2'h00-------------------------------/ 
localparam rden_del_dist_rx    = 15000;   // in range [0:15000] clk cycles
localparam send_del_dist_rx    = 20000;   // in range [0:20000] clk cycles
//===================================================================================
endpackage
