//=======================================================
//
//      Transmitter
//
//=======================================================
import params_pkg::*;
//=======================================================
module uart_tx (
    input  logic            clk,

    output logic            txc,
    input  logic            baud_tick,

    input  logic            init_en,
    input  logic [WORD-1:0] tx_data,
    input  logic            tx_empty_clr,
    output logic            tx_empty,
    output logic            tx_done
);
//=======================================================
//
//          Structs
//
typedef enum logic[1:0]
{
    TX_STATE_HOLD,
    TX_STATE_NEXT,
    TX_STATE_START
}
tx_stat_t;

typedef enum logic [1:0]
{
    TX_IDLE,
    TX_START,
    TX_DATA,
    TX_STOP
}
tx_state_t;
//=======================================================
//
//          Logic
//
logic [WORD-1:0] tx_buffer       = 0;
logic [WORD-1:0] tx_shift        = 0;
logic [     3:0] tx_bit_cnt      = 0;
logic            tx_empty_clr    = 0;


tx_stat_t        tx_stat         = TX_STATE_HOLD;
tx_state_t       tx_state        = TX_IDLE;
//=======================================================
//
//          Processes
//
//-------------------------------------------------------
//
//  TX state machine manager
//
always_ff@(negedge clk) begin
    if(tx_stat == TX_STATE_HOLD) begin
    end
    else if(tx_stat == TX_STATE_NEXT) begin
       case(tx_state)
        TX_IDLE  : tx_state <= TX_START;
        TX_START : tx_state <= TX_DATA;
        TX_DATA  : tx_state <= TX_STOP;
        TX_STOP  : tx_state <= TX_IDLE;
       endcase
    end
    else if (tx_stat == TX_STATE_START) begin
       tx_state <= TX_START;
    end
end
//-------------------------------------------------------
//
//  TX state machine
//
always_ff @(posedge clk) begin
    case (tx_state)
    TX_IDLE: begin
        tx_stat     <= TX_STATE_HOLD;
        if (!tx_empty) begin
            tx_shift     <= tx_buffer;
            tx_empty_clr <= 1'b1;
            tx_stat      <= TX_STATE_NEXT;
        end
    end
    TX_START: begin
        tx_empty_clr <= 1'b0;
        tx_stat      <= TX_STATE_HOLD;
        if (baud_tick) begin
            txc        <= 1'b0;
            tx_bit_cnt <= 4'd0;
            tx_stat    <= TX_STATE_NEXT;
        end
    end
    TX_DATA: begin
        tx_stat      <= TX_STATE_HOLD;
        if (baud_tick) begin
            txc        <= tx_shift[7];
            tx_shift   <= {tx_shift[6:0],1'b0 };
            tx_bit_cnt <= tx_bit_cnt + 1;
            if (tx_bit_cnt == WORD-1) begin
                tx_stat <= TX_STATE_NEXT;
            end
        end
    end
    TX_STOP: begin
        tx_stat <= TX_STATE_HOLD;
        if (baud_tick) begin
            txc <= 1'b1;
            if (!tx_empty) begin
                tx_shift     <= tx_buffer;
                tx_empty_clr <= 1'b1;
                tx_stat      <= TX_STATE_START;
            end else begin

                tx_done <= 1'b1;
                tx_stat <= TX_STATE_NEXT;
            end
        end
    end
    endcase
end
//=======================================================
endmodule : uart_tx
//=======================================================
