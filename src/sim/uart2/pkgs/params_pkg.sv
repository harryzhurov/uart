//===================================================================================
package params_pkg;
//===================================================================================
//
//      Parameters
//
localparam WORD            = 8   ;
localparam CLK_FREQ        = 100_000_000;
localparam BAUD_RATE       = 115200;
localparam BIT_PERIOD      = CLK_FREQ / BAUD_RATE;
localparam HALF_PERIOD     = BIT_PERIOD / 2;
localparam CLK_CYCLE       = 1_000_000_000/CLK_FREQ;
localparam UART_CYCLE      = BIT_PERIOD*CLK_CYCLE;
//===================================================================================
endpackage
