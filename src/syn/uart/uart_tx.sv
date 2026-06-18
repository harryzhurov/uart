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

tx_state_t  tx_state        = TX_IDLE;
tx_state_t  tx_state_next   = tx_state;
//=======================================================
//
//          Processes
//
//-------------------------------------------------------
//
//  TX state machine manager
//
always_ff @(posedge clk) begin
    tx_state <= tx_state_next;
end

always_comb begin

    automatic tx_state_t next = tx_state;

    unique case (tx_state)
        TX_IDLE: begin
            if(!tx_empty) begin
                next = TX_START;
            end
        end

        TX_START : begin
            if(baud_tick) begin
                next = TX_DATA;
            end
        end

        TX_DATA : begin
            if(tx_bit_cnt == WORD) begin
                next = TX_STOP;
            end
        end

        TX_STOP : begin
            if(baud_tick && !tx_empty) begin
                next = TX_START;
            end
            else if (baud_tick && tx_empty) begin
                next = TX_IDLE;
            end
        end
    endcase

    tx_state_next = next;

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
