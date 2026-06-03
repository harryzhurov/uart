//-------------------------------------------------------------------------------
//
//     Project: UART
//
//     Purpose: Parameters for UART
//
//     Author : Matthew S. Grebnev, 2026
//
//-------------------------------------------------------------------------------
`ifndef UART_PARAMS_SVH
`define UART_PARAMS_SVH

`include "common.svh"

//-------------------------------------------------------------------------------
package params_pkg;
    
    // UART settings

    parameter uint32_t WORD            = 8;
    parameter uint32_t CLK_FREQ        = 100_000_000;
    parameter uint32_t BAUD_RATE       = 115200;
    parameter uint32_t BIT_PERIOD      = CLK_FREQ / BAUD_RATE;
    parameter uint32_t HALF_PERIOD     = BIT_PERIOD / 2;
    parameter uint32_t CLK_CYCLE       = 1_000_000_000/CLK_FREQ;
    parameter uint32_t UART_CYCLE      = BIT_PERIOD*CLK_CYCLE;
    
    // Probabilities

    parameter uint32_t wrong_stop_exist_rx =     2;   // probability of stop bit = 0-------------------------------\
    parameter uint32_t send_del_exist_rx   =    30;   // probability of delay existance before data sending         \
    parameter uint32_t rden_del_exist_rx   =    10;   // probability of delay existance before rx_rden flag sending  > (%)
    parameter uint32_t zero_data_rx        =     8;   // probability of data = 2'h00                                /
    parameter uint32_t drop_rx_trn         =     1;   // probability of dropping transaction-----------------------/
    parameter uint32_t rden_del_dist_rx    = 30000;   // in range [0:15000] clk cycles
    parameter uint32_t send_del_dist_rx    = 30000;   // in range [0:20000] clk cycles

//-------------------------------------------------------------------------------
endpackage : params_pkg
//-------------------------------------------------------------------------------
`endif UART_PARAMS_SVH
