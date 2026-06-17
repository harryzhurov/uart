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

typedef enum logic[1:0]
{
    HOLD,
    NEXT
}
pre_state_t;

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

pre_state_t pre_state       = HOLD;
rx_state_t  rx_state        = RX_IDLE;
//=======================================================
//
//          Process
//
//-------------------------------------------------------
//
//  RX state machine manage
//
always_comb begin

    case(rx_state)

        RX_IDLE : 
            pre_state = ( start_detected         ) ? NEXT : HOLD;
        RX_HALF :
            pre_state = ( rx_timer == HALF_PERIOD) ? NEXT : HOLD;
        RX_DATA : 
            pre_state = ( rx_bit_cnt == WORD-1   ) ? NEXT : HOLD;
        RX_STOP : 
            pre_state = ( rx_timer == BIT_PERIOD ) ? NEXT : HOLD;
    endcase
end

always_ff @(posedge clk) begin

    case (pre_state)
        HOLD:
            rx_state <= rx_state;
        NEXT:
            case (rx_state)
                RX_IDLE: rx_state <= RX_HALF;
                RX_HALF: rx_state <= ( rxc_shift[2] == 1'b0 ) ? RX_DATA : RX_IDLE;
                RX_DATA: rx_state <= RX_STOP;
                RX_STOP: rx_state <= RX_IDLE; 
            endcase
    endcase

end

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
