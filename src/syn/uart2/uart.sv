`timescale 1ns / 1ps
// ======================================================
//
//          Instance
//
module uart (
    input  logic       clk,          // 100 MHz

    output logic       txc,
    input  logic       rxc,

    input  logic [7:0] tx_data,
    input  logic       tx_wren,
    output logic [7:0] rx_data,
    input  logic       rx_rden,
    output logic       tx_empty,
    output logic       tx_complete,
    output logic       rx_complete,
    output logic       frame_error,
    output logic       overrun,
    input  logic       rst_err
);
// ======================================================
//
//          Params
//
// ======================================================
//
//          Logic
//
logic [2:0] rxc_shift       = 0;
logic [1:0] tx_stat         = 0;        
logic [1:0] rx_stat         = 0;
logic [9:0] baud_cnt        = 0;
logic [7:0] tx_buffer       = 0;
logic [7:0] tx_shift        = 0;
logic [3:0] tx_bit_cnt      = 0;
logic [9:0] rx_timer        = 0;
logic [3:0] rx_bit_cnt      = 0;
logic [7:0] rx_shift        = 0;
logic       rx_timer_en     = 0;
logic       baud_tick;
logic       rxc_delayed;
logic       rxc_sync;
logic       rxc_prev;
logic       start_detected;
logic       tx_empty_clr;

logic [1:0] init    = 0;
logic       init_en;
localparam CLK_FREQ       = 100_000_000;
localparam BAUD_RATE      = 115200;
localparam BIT_PERIOD     = CLK_FREQ / BAUD_RATE; // 868
localparam HALF_PERIOD    = BIT_PERIOD / 2;       // 434
localparam LAST_BIT       = 7;
localparam TX_STATE_HOLD  = 0;
localparam TX_STATE_NEXT  = 1;
localparam TX_STATE_START = 2;
localparam RX_STATE_HOLD  = 0;
localparam RX_STATE_NEXT  = 1;
localparam RX_STATE_IDLE  = 2;
// ======================================================
//
//          Structs
//
typedef enum logic [1:0]
{
    TX_IDLE,
    TX_START,
    TX_DATA,
    TX_STOP
}
tx_state_t;

tx_state_t tx_state = TX_IDLE;

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
//-------------------------------------------------------
//
//  Generator of reference frequancy UART
//
always_ff @(posedge clk) begin
    baud_cnt  <= baud_cnt + 1;
    baud_tick <= 0;
    if (baud_cnt == BIT_PERIOD - 1) begin
        baud_cnt  <= 0;
        baud_tick <= 1;
    end
end
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
//
//      Transmitter (TX)
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
//  Catch tx_wren
//
always_ff @(posedge clk) begin
    if(init_en) begin
        tx_empty  <= 1'b1;
    end
    if (tx_wren) begin
        tx_buffer <= tx_data;
        tx_empty  <= 1'b0;
    end
    else if(tx_empty_clr) begin
        tx_empty  <= 1'b1;
    end
end
//-------------------------------------------------------
//
//  Body of Transmitter
//
always_ff @(posedge clk) begin
    if(init_en) begin
    
        txc <= 1'b1;
    
    end
    case (tx_state)
    TX_IDLE: begin
        tx_stat     <= TX_STATE_HOLD;
        tx_complete <= 1'b0;
        if (!tx_empty) begin
            tx_shift     <= tx_buffer;
            tx_stat      <= TX_STATE_NEXT;
        end
    end
    TX_START: begin
        tx_empty_clr <= 1'b1;
        tx_stat     <= TX_STATE_HOLD;
        if (baud_tick) begin
            txc        <= 1'b0;
            tx_bit_cnt <= 4'd0;
            tx_stat    <= TX_STATE_NEXT;
        end
    end
    TX_DATA: begin
        tx_stat      <= TX_STATE_HOLD;
        tx_empty_clr <= 1'b0;
        if (baud_tick) begin
            txc        <= tx_shift[7];
            tx_shift   <= {tx_shift[6:0],1'b0 };
            tx_bit_cnt <= tx_bit_cnt + 1;
            if (tx_bit_cnt == LAST_BIT) begin
                tx_stat <= TX_STATE_NEXT;
            end
        end
    end
    TX_STOP: begin
        tx_stat <= TX_STATE_HOLD;
        if (baud_tick) begin
            txc <= 1'b1;
            if (tx_empty == 1'b0) begin
                tx_shift     <= tx_buffer;
                tx_stat      <= TX_STATE_START;
            end else begin
                tx_complete  <= 1'b1;
                tx_stat      <= TX_STATE_NEXT;
            end
        end
    end
    endcase
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
