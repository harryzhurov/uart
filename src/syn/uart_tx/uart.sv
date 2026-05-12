`timescale 1ns / 1ps
// ======================================================
//
//          Instance
//
module uart (
    input  logic       clk,          // 100 MHz

    output logic       txc,

    input  logic [7:0] tx_data,
    input  logic       tx_wren,
    output logic       tx_empty,
    output logic       tx_complete
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
localparam WORD           = 8;
// ======================================================
//
//          Logic
//
logic [     9:0] baud_cnt        = 0;
logic [WORD-1:0] tx_buffer       = 0;
logic [WORD-1:0] tx_shift        = 0;
logic [     3:0] tx_bit_cnt      = 0;
logic            baud_tick;
logic            start_detected  = 0;
logic            tx_empty_clr    = 0;

logic [1:0]      init            = 0;
logic            init_en         = 0;
// ======================================================
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
// ======================================================
//
//          Processes
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

tx_stat_t  tx_stat  = TX_STATE_HOLD;
tx_state_t tx_state = TX_IDLE;

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
//  Buffer logic
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
//  TX state machine
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
            if (tx_bit_cnt == LAST_BIT) begin
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
                tx_complete  <= 1'b1;
                tx_stat      <= TX_STATE_NEXT;
            end
        end
    end
    endcase
end
// ======================================================
endmodule : uart
// ======================================================
