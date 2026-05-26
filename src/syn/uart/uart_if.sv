//=======================================================
interface uart_if;
//=======================================================
    import params_pkg::*;
//=======================================================
    logic            clk;
    logic            baud_pulse;

    logic            rxc;
    logic            txc;

    logic [WORD-1:0] rx_data;
    logic            rx_rden;
    logic            rx_complete;
    logic            frame_error;
    logic            overrun;
    logic            rst_err;
    logic            rx_done;

    logic [WORD-1:0] tx_data;
    logic            tx_wren;
    logic            tx_empty;
    logic            tx_complete;
    logic            tx_done;
    
    event            rx_rden_en;
    event            reset_err;
//=======================================================
    
    modport uart_mp
    (
        input  clk,

        input  rxc,
        input  rx_rden,
        input  rst_err,
        input  rx_done,
        output rx_data,
        output rx_complete,
        output frame_error,
        output overrun,
        
        input  tx_wren,
        input  tx_data,
        input  tx_done,
        output txc,
        output tx_empty,
        output tx_complete
    );
    
//======================================================
endinterface
//=======================================================
