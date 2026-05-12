//===================================================================================
package trn_cfg_pkg;
//===================================================================================
//
//      Number of transactions
//
parameter int  num_trn_tx          = 1500;
//parameter int  num_trn_rx          = 200;
//===================================================================================
//
//      Tx setting
//
parameter int  zero_data_tx        =     1; // probability of data = 2'h00--------------------------\ (%)
parameter int  send_del_exist_tx   =    40; // probobility of delay existance before data sending --/
parameter int  send_del_dist_tx    = 60000; // in range [0:10000] clk

//===================================================================================
//
//      Rx setting
//
/*parameter int wrong_stop_exist_rx = 2;       // probability of stop bit = 0-------------------------------\
parameter int send_del_exist_rx   = 10;      // probability of delay existance before data sending         \ (%)
parameter int rden_del_exist_rx   = 8;       // probability of delay existance before rx_rden flag sending /
parameter int zero_data_rx        = 6;       // probability of data = 2'h00-------------------------------/
parameter int rden_del_dist_rx    = 15000;   // in range [0:15000] clk cycles
parameter int send_del_dist_rx    = 20000;   // in range [0:20000] clk cycles*/
//===================================================================================
endpackage : trn_cfg_pkg
