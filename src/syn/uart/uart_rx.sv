//=======================================================
//
//      Receiver
//
//=======================================================
import params_pkg::*;
//=======================================================
module uart_rx (
    input  logic            clk,
    input  logic            init_en,

    input  logic            rxc,

    output logic [WORD-1:0] rx_data,
    output logic            rx_done
);
//=======================================================
//
//          Types
//
typedef logic [WORD-1:0] data_t;

typedef enum logic [1:0]
{
    RX_IDLE,
    RX_HALF,
    RX_DATA,
    RX_STOP
}
rx_state_t;
//=======================================================
//
//          Objects
//
logic [2:0] rxc_shift       = 0;
logic [9:0] rx_timer        = 0;
logic [3:0] rx_bit_cnt      = 0;
logic       rx_timer_en     = 0;
logic       start_detected  = 0;
data_t      rx_shift        = 0;

rx_state_t  rx_state        = RX_IDLE;
rx_state_t  rx_state_next   = rx_state;
//=======================================================
//
//          Process
//
//-------------------------------------------------------
//
//  RX state machine manager
//
always_ff @(posedge clk) begin
    rx_state <= rx_state_next;
end

always_comb begin

    automatic rx_state_t next = rx_state;

    unique case(rx_state)

        RX_IDLE : begin
            if(start_detected) begin
                next = RX_HALF;
            end
        end

        RX_HALF : begin
            if(rx_timer == HALF_PERIOD && !rxc_shift[2]) begin
                next = RX_DATA;
            end
            else if (rx_timer == HALF_PERIOD && rxc_shift[2]) begin
                next = RX_IDLE;
            end
        end

        RX_DATA : begin
            if(rx_bit_cnt == WORD) begin
                next = RX_STOP;
            end
        end

        RX_STOP : begin
            if(rx_timer == BIT_PERIOD) begin
                next = RX_IDLE;
            end
        end
    endcase

    rx_state_next = next;
end
//-------------------------------------------------------
//
//  Synchronization
//
always_ff @(posedge clk) begin
    rxc_shift[0] <= rxc;
    rxc_shift[1] <= rxc_shift[0];
    rxc_shift[2] <= rxc_shift[1];
end
//-------------------------------------------------------
//
//  Increment counter rx_timer
//
always_ff @(posedge clk) begin
    rx_timer = (rx_timer_en) ? (rx_timer + 1) : 0;
end
//-------------------------------------------------------
//
//  Catch START bit
//
always_comb start_detected = (rxc_shift[2] && (!rxc_shift[1]));
//-------------------------------------------------------
//
//  Body of Receiver
//
always_ff @(posedge clk) begin

    if(init_en) begin
        rx_data <= 8'h00;
        rx_done <= 1'b0;
    end

    rx_done <= 1'b0;

    case (rx_state)

    RX_IDLE: begin

        rx_timer_en <= 0;

    end
    RX_HALF: begin

        rx_timer_en <= 1;

        if (rx_timer == HALF_PERIOD) begin

            if (rxc_shift[2] == 1'b0) begin

                rx_timer_en <= 0;
                rx_bit_cnt  <= 4'd0;

            end
        end
    end
    RX_DATA: begin

        rx_timer_en <= 1;

        if (rx_timer == BIT_PERIOD) begin

            rx_shift    <= {rx_shift[6:0], rxc_shift[2]};
            rx_bit_cnt  <= rx_bit_cnt + 1;
            rx_timer_en <= 0;

            if (rx_bit_cnt == WORD-1) begin

                rx_timer_en <= 0;

            end
        end
    end
    RX_STOP: begin

        rx_timer_en <= 1;

        if (rx_timer == BIT_PERIOD) begin

            rx_data <= rx_shift;
            rx_done <= 1'b1;

        end
    end
    endcase
end
//=======================================================
endmodule : uart_rx
//=======================================================
