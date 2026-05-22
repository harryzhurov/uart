//===================================================================================
package trn_cfg_pkg;
//===================================================================================
//
//      Number of transactions
//
parameter int  num_trn_rx          = 1000;
//===================================================================================
//
//      Rx setting
//
parameter int wrong_stop_exist_rx =  2;      // probability of stop bit = 0-------------------------------\
parameter int send_del_exist_rx   = 30;      // probability of delay existance before data sending         \
parameter int rden_del_exist_rx   = 10;      // probability of delay existance before rx_rden flag sending  > (%)
parameter int zero_data_rx        =  8;      // probability of data = 2'h00                                /
parameter int drop_rx_trn         =  1;      // probability of dropping transaction-----------------------/
parameter int rden_del_dist_rx    = 30000;   // in range [0:15000] clk cycles
parameter int send_del_dist_rx    = 30000;   // in range [0:20000] clk cycles
//===================================================================================
endpackage : trn_cfg_pkg
