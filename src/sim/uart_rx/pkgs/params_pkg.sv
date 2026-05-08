//===================================================================================
package params_pkg;
//===================================================================================
//
//      Parameters
//
parameter int WORD            = 8   ;
parameter int CLK_FREQ        = 100_000_000;
parameter int BAUD_RATE       = 115200;
parameter int BIT_PERIOD      = CLK_FREQ / BAUD_RATE;
parameter int HALF_PERIOD     = BIT_PERIOD / 2;
parameter int CLK_CYCLE       = 1_000_000_000/CLK_FREQ;
parameter int UART_CYCLE      = BIT_PERIOD*CLK_CYCLE;
//===================================================================================
endpackage : params_pkg
