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

    parameter uint32_t WORD            = 8;
    parameter uint32_t CLK_FREQ        = 100_000_000;
    parameter uint32_t BAUD_RATE       = 115200;
    parameter uint32_t BIT_PERIOD      = CLK_FREQ / BAUD_RATE;
    parameter uint32_t HALF_PERIOD     = BIT_PERIOD / 2;
    parameter uint32_t CLK_CYCLE       = 1_000_000_000/CLK_FREQ;
    parameter uint32_t UART_CYCLE      = BIT_PERIOD*CLK_CYCLE;

//-------------------------------------------------------------------------------
endpackage : params_pkg
//-------------------------------------------------------------------------------
`endif UART_PARAMS_SVH
