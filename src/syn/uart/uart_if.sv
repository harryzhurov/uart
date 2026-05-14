//=======================================================
interface uart_if;
//=======================================================
    import params_pkg::*;
//=======================================================
    logic            clk;
    logic            baud_tick;
    logic            baud_pulse;

    logic            rxc;
    logic            txc;

    logic            init_en;

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
    modport uart_mp
    (
        input  clk,
        input  baud_tick,
        input  init_en,
        input  rxc,
        input  rx_rden,
        input  rst_err,
        output rx_data,
        output rx_complete,
        output frame_error,
        output overrun,
        
        input  txc,
        input  tx_wren,
        output tx_data,
        output tx_empty,
        output tx_complete
    );
    
    modport tb_mp
    (
        output clk,
        output baud_pulse,
        output rxc,
        output rx_rden,
        output rst_err,
        input  rx_data,
        input  rx_complete,
        input  frame_error,
        input  overrun,
        
        output txc,
        output tx_wren,
        input  tx_data,
        input  tx_empty,
        input  tx_complete
    );
 //=======================================================
endinterface
//=======================================================
