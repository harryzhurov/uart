`timescale 1ns / 1ps
// ======================================================
//
//          Instance
//
module uart (
    input  logic       clk,          // 100 MHz

    input  logic       rxc,

    output logic [7:0] rx_data,
    input  logic       rx_rden,
    output logic       rx_complete,
    output logic       frame_error,
    output logic       overrun,
    input  logic       rst_err
);
// ======================================================
//
//          Params
//
localparam CLK_FREQ       = 100_000_000;
localparam BAUD_RATE      = 115200;
localparam BIT_PERIOD     = CLK_FREQ / BAUD_RATE; // 868
localparam HALF_PERIOD    = BIT_PERIOD / 2;       // 434
localparam LAST_BIT       = 7;
// ======================================================
//
//          Logic
//
logic [     2:0] rxc_shift       = 0;
logic [     9:0] baud_cnt        = 0;
logic [     9:0] rx_timer        = 0;
logic [     3:0] rx_bit_cnt      = 0;
logic [WORD-1:0] rx_shift        = 0;
logic            rx_timer_en     = 0;
logic            baud_tick;
logic            start_detected;

logic [     1:0] init            = 0;
logic            init_en;
// ======================================================
//
//          Structs
//
typedef enum logic[1:0]
{
    RX_STATE_HOLD,
    RX_STATE_NEXT,
    RX_STATE_IDLE
}
rx_stat_t;
rx_stat_t rx_stat = RX_STATE_HOLD;

typedef enum logic [1:0]
{
    RX_IDLE,
    RX_HALF,
    RX_DATA,
    RX_STOP
}
rx_state_t;

rx_state_t rx_state = RX_IDLE;
// ======================================================
//
//          Process
//
//-------------------------------------------------------
//
//  Initialization
//
always_ff @(posedge clk) begin
    init[0] <= 1'b1;
    init[1] <= init[0];
    init_en <= init[0] && (!init[1]);
end
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
//
//      Receiver (RX)
//
//-------------------------------------------------------
//
//  RX state machine manage
//
always_ff @(negedge clk) begin
     if(rx_stat == RX_STATE_HOLD) begin
     end
     else if(rx_stat == RX_STATE_NEXT) begin
        case(rx_state)
            RX_IDLE : rx_state <= RX_HALF;
            RX_HALF : rx_state <= RX_DATA;
            RX_DATA : rx_state <= RX_STOP;
            RX_STOP : rx_state <= RX_IDLE;
        endcase
     end
     else if (rx_stat == RX_STATE_IDLE) begin
        rx_state <= RX_IDLE;
     end
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
        rx_complete <= 1'b0;
        overrun     <= 1'b0;
        frame_error <= 1'b0;
    end
    if (rx_rden)
        rx_complete <= 1'b0;
    case (rx_state)
    RX_IDLE: begin
        rx_stat     <= RX_STATE_HOLD;
        rx_timer_en <= 0;
        if (start_detected)
            rx_stat <= RX_STATE_NEXT;
    end
    RX_HALF: begin
        rx_stat     <= RX_STATE_HOLD;
        rx_timer_en <= 1;
        if (rx_timer == HALF_PERIOD - 1) begin
            rx_stat <= RX_STATE_IDLE;
            if (rxc_shift[2] == 1'b0) begin
                rx_timer_en <= 0;
                rx_bit_cnt  <= 4'd0;
                rx_stat     <= RX_STATE_NEXT;
            end
        end
    end
    RX_DATA: begin
        rx_stat     <= RX_STATE_HOLD;
        rx_timer_en <= 1;
        if (rx_timer == BIT_PERIOD - 1) begin
            rx_shift    <= {rx_shift[6:0], rxc_shift[2]};
            rx_bit_cnt  <= rx_bit_cnt + 1;
            rx_timer_en <= 0;
            if (rx_bit_cnt == LAST_BIT) begin
                rx_timer_en <= 0;
                rx_stat     <= RX_STATE_NEXT;
            end
        end
    end
    RX_STOP: begin
        rx_stat     <= RX_STATE_HOLD;
        rx_timer_en <= 1;
        if (rx_timer == BIT_PERIOD - 1) begin
            if (!rxc_shift[2]) 
                frame_error <= 1'b1;
            if ( rx_complete ) 
                overrun     <= 1'b1;
            rx_data     <= rx_shift;
            rx_complete <= 1'b1;
            rx_stat     <= RX_STATE_NEXT;
        end
    end
    endcase
//-------------------------------------------------------
//
//  Reset errors
//
    if (rst_err) begin
        frame_error <= 1'b0;
        overrun     <= 1'b0;
    end
end
//-------------------------------------------------------
endmodule
