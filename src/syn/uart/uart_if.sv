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
    logic [WORD-1:0] rx_buffer;
    logic            rx_rden;
    logic            rx_complete;
    logic            frame_error;
    logic            overrun;
    logic            rst_err;
    logic            rx_done;

    logic [WORD-1:0] tx_data;
    logic [WORD-1:0] tx_buffer;
    logic            tx_wren;
    logic            tx_empty;
    logic            tx_complete;
    logic            tx_done;
    logic            tx_empty_clr;
//=======================================================
    modport uart_mp
    (
        input  clk,
        input  baud_tick,
        input  init_en,

        input  rxc,
        input  rx_rden,
        input  rst_err,
        input  rx_done,
        input  rx_buffer,
        output rx_data,
        output rx_complete,
        output frame_error,
        output overrun,
        
        input  tx_wren,
        input  tx_done,
        input  tx_empty_clr,
        output txc,
        output tx_buffer,
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
        
        output tx_wren,
        input  txc,
        input  tx_data,
        input  tx_empty,
        input  tx_complete
    );
 //=======================================================
endinterface
//=======================================================
