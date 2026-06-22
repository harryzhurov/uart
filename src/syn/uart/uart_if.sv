//=======================================================
interface uart_if;
//=======================================================
    import params_pkg::*;
//=======================================================
    logic            rxc;
    logic            txc;

    logic [WORD-1:0] rx_data;
    logic            rx_rden;
    logic            rx_complete;
    logic            frame_error;
    logic            overrun;
    logic            rst_err;

    logic [WORD-1:0] tx_data;
    logic            tx_wren;
    logic            tx_empty;
    logic            tx_complete;
//=======================================================

    modport s
    (
        input rxc,
        input rx_rden,
        input rst_err,
        input tx_wren,
        input tx_data,
        output rx_data,
        output rx_complete,
        output frame_error,
        output overrun,
        output txc,
        output tx_empty,
        output tx_complete
    );

    modport m
    (
        output rxc,
        output rx_rden,
        output rst_err,
        output tx_wren,
        output tx_data,
        input  rx_data,
        input  rx_complete,
        input  frame_error,
        input  overrun,
        input  txc,
        input  tx_empty,
        input  tx_complete
    );


//======================================================
endinterface
//=======================================================
