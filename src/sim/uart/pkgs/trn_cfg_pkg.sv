//===================================================================================
package trn_cfg_pkg;
//===================================================================================
//
//      Number of transactions
//
parameter int  num_trn_tx          = 500;
parameter int  num_trn_rx          = 500;
//===================================================================================
//
//      Tx setting
//
parameter int  zero_data_tx        = 10;      // probability of data = 2'h00--------------------------\ (%)
parameter int  send_del_exist_tx   = 60;      // probobility of delay existance before data sending --/
parameter int  send_del_dist_tx    = 40000;   // in range [0:10000] clk

//===================================================================================
//
//      Rx setting
//
parameter int wrong_stop_exist_rx =  5;       // probability of stop bit = 0-------------------------------\
parameter int send_del_exist_rx   =  0;       // probability of delay existance before data sending         \ (%)
parameter int rden_del_exist_rx   =  0;       // probability of delay existance before rx_rden flag sending /
parameter int zero_data_rx        =  0;       // probability of data = 2'h00-------------------------------/
parameter int rden_del_dist_rx    = 30000;    // in range [0:15000] clk cycles
parameter int send_del_dist_rx    = 30000;    // in range [0:20000] clk cycles
//===================================================================================
endpackage : trn_cfg_pkg
