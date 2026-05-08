interface uart_if (
    input logic clk,
    input logic baud_pulse
);

    import params_pkg::*;

    logic [WORD-1:0] tx_data;
    logic [WORD-1:0] rx_data;
    logic            txc;
    logic            rxc;
    logic            tx_wren;
    logic            rx_rden;
    logic            rst_err;
    logic            tx_empty;
    logic            tx_complete;
    logic            rx_complete;
    logic            frame_error;
    logic            overrun;

endinterface
