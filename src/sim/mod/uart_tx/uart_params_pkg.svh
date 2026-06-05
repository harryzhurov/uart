//-------------------------------------------------------------------------------
//
//     Project: UART
//
//     Purpose: Parameters for UART
//
//     Author : Matthew S. Grebnev, 2026
//
//-------------------------------------------------------------------------------
package uart_params_pkg;
//-------------------------------------------------------------------------------
    // Probabilities

    parameter int  zero_data_tx        =     1; // probability of data = 2'h00--------------------------\
    parameter int  send_del_exist_tx   =     0; // probobility of delay existance before data sending -- > (%)
    parameter int  send_del_dist_tx    = 30000; // in range [0:10000] clk

//-------------------------------------------------------------------------------
endpackage
//-------------------------------------------------------------------------------
