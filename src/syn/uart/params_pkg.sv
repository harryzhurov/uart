//===================================================================================
package params_pkg;
//===================================================================================
//
//      Parameters
//
localparam int WORD            = 8   ;
localparam int CLK_FREQ        = 100_000_000;
localparam int BAUD_RATE       = 115200;
localparam int BIT_PERIOD      = CLK_FREQ / BAUD_RATE;
localparam int HALF_PERIOD     = BIT_PERIOD / 2;
localparam int CLK_CYCLE       = 1_000_000_000/CLK_FREQ;
localparam int UART_CYCLE      = BIT_PERIOD*CLK_CYCLE;
//===================================================================================
endpackage : params_pkg
