//=======================================================
//
//      Transmitter
//
//=======================================================
import params_pkg::*;
//=======================================================
module uart_tx (
    input  logic            clk,
    input  logic            baud_tick,
    input  logic            init_en,

    output logic            txc,

    input  logic [WORD-1:0] tx_data,
    input  logic            tx_wren,
    output logic            tx_empty,
    output logic            tx_done
);
//=======================================================
//
//          Structs
//
typedef logic [WORD-1:0] data_t;

typedef enum logic
{
    HOLD,
    NEXT
}
pre_state_t;

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
data_t      tx_shift        = 0;
data_t      tx_buffer       = 0;
logic [3:0] tx_bit_cnt      = 0;

pre_state_t pre_state       = HOLD;
tx_state_t  tx_state        = TX_IDLE;
//=======================================================
//
//          Processes
//
//-------------------------------------------------------
//
//  TX state machine manager
//
always_comb begin

    case(tx_state)
        TX_IDLE :
            pre_state = ( !tx_empty ) ? NEXT : HOLD;
        TX_START: 
            pre_state = ( baud_tick ) ? NEXT : HOLD;
        TX_DATA :
            pre_state = ( tx_bit_cnt == WORD-1 ) ? NEXT : HOLD;
        TX_STOP :
            pre_state = ( baud_tick ) ? NEXT : HOLD;
    endcase
end

always_ff @(posedge clk) begin

    case(pre_state)
        HOLD:
            tx_state <= tx_state;
        NEXT:
            case(tx_state)
                TX_IDLE : tx_state <= TX_START;
                TX_START: tx_state <= TX_DATA;
                TX_DATA : tx_state <= TX_STOP;
                TX_STOP : tx_state <= (tx_empty) ? TX_IDLE : TX_START;
            endcase
    endcase
end
//-------------------------------------------------------
//
//  TX state machine
//
always_ff @(posedge clk) begin

    if(init_en) begin
        txc      <= 1'b1;
        tx_empty <= 1'b1;
    end
    
    if(tx_wren) begin

        tx_empty  <= 1'b0;
        tx_buffer <= tx_data;

    end

    tx_done <= 1'b0;

    case (tx_state)

    TX_IDLE: begin

        if (!tx_empty) begin

            tx_shift <= tx_buffer;
            tx_empty <= 1'b1;

        end
    end
    TX_START: begin

        if (baud_tick) begin

            txc        <= 1'b0;
            tx_bit_cnt <= 4'd0;

        end
    end
    TX_DATA: begin

        if (baud_tick) begin

            txc        <= tx_shift[7];
            tx_shift   <= {tx_shift[6:0],1'b0 };
            tx_bit_cnt <= tx_bit_cnt + 1;

        end
    end
    TX_STOP: begin

        if (baud_tick) begin

            txc <= 1'b1;

            if (!tx_empty) begin

                tx_shift <= tx_buffer;
                tx_empty <= 1'b1;

            end else begin

                tx_done <= 1'b1;

            end
        end
    end
    endcase
end
//=======================================================
endmodule : uart_tx
//=======================================================
