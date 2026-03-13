`timescale 1ns / 1ps
// ======================================================
//  Declaration of module
// ======================================================
module UART_MAIN (
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
//  Declaration of signals
// ======================================================
logic [9:0] baud_cnt = 0;
logic [7:0] tx_buffer;
logic [7:0] tx_shift;
logic [3:0] tx_bit_cnt;
logic [9:0] rx_timer;
logic [3:0] rx_bit_cnt;
logic [7:0] rx_shift;
logic [7:0] rx_data_reg;
logic       rx_timer_en;
logic       baud_tick;
logic       tx_empty_reg;
logic       tx_complete_reg;
logic       rxc_delayed;
logic       rxc_sync;
logic       rxc_prev;
logic       start_detected;
logic       rx_complete_reg = 1'b0;
logic       frame_error_reg = 1'b0;
logic       overrun_reg     = 1'b0;
//-------------------------------------------------------
localparam CLK_FREQ    = 100_000_000;
localparam BAUD_RATE   = 115200;
localparam BIT_PERIOD  = CLK_FREQ / BAUD_RATE; // 868
localparam HALF_PERIOD = BIT_PERIOD / 2;       // 434
localparam LAST_BIT    = 7;
//-------------------------------------------------------
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
//-------------------------------------------------------
// ======================================================
//  Generator of refference frequancy UART
// ======================================================
always_ff @(posedge clk) begin
    baud_cnt <= baud_cnt + 1;
    baud_tick <= 0;
    if (baud_cnt == BIT_PERIOD - 1) begin
        baud_cnt  <= 0;
        baud_tick <= 1;
    end
end
// ======================================================
//  Transmitter (TX)
// ======================================================
//-------------------------------------------------------
// Catch tx_wren
//-------------------------------------------------------
always_ff @(posedge clk) begin
    if (tx_wren) begin
        tx_buffer <= tx_data;
        tx_empty <= 1'b0;                       // Buffer is busy
    end
end
//-------------------------------------------------------
// Body of Transmitter
//-------------------------------------------------------
always_ff @(posedge clk) begin
    case (tx_state)
    TX_IDLE: begin
        tx_complete  <= 1'b0;
        if (tx_empty == 1'b0) begin
            tx_shift <= tx_buffer;
            tx_empty <= 1'b1;                   // Buffer is ready for new data
            tx_state <= TX_START;
        end
    end
    TX_START: begin
        if (baud_tick) begin
            txc        <= 1'b0;                 // Start bit
            tx_bit_cnt <= 4'd0;
            tx_state   <= TX_DATA;
        end
    end
    TX_DATA: begin
        if (baud_tick) begin
            txc <= tx_shift[7];                 // LSB first
            tx_shift   <= {tx_shift[6:0],1'b0 };  // Shift to the right
            tx_bit_cnt <= tx_bit_cnt + 1;
            if (tx_bit_cnt == LAST_BIT) begin
                tx_state <= TX_STOP;
            end
        end
    end
    TX_STOP: begin
        if (baud_tick) begin
            txc <= 1'b1;                        // Stop bit
            if (tx_empty == 1'b0) begin         // Next data is already ready
                tx_shift <= tx_buffer;
                tx_empty <= 1'b1;
                tx_state <= TX_START;
            end else begin
                tx_state    <= TX_IDLE;
                tx_complete <= 1'b1;            // Done
            end
        end
    end
    endcase
end
// ======================================================
//  Receiver (RX)
// ======================================================
//-------------------------------------------------------
// Synchronization
//-------------------------------------------------------
always_ff @(posedge clk) begin
    rxc_delayed <= rxc;
    rxc_sync <= rxc_delayed;
    rxc_prev <= rxc_sync;
end
always_ff @(posedge clk) begin  
    rx_timer = (rx_timer_en) ? (rx_timer + 1) : 0;                      // Increment counter rx_timer                        
end
always_comb start_detected = (rxc_prev == 1'b1 && rxc_sync == 1'b0);    // Catch the START bit
//-------------------------------------------------------
// Body of Receiver
//-------------------------------------------------------
always_ff @(posedge clk) begin
    if (rx_rden) rx_complete <= 1'b0;               // Catch rx_rden
    case (rx_state)
    RX_IDLE: begin
        rx_timer_en <= 0;
        if (start_detected) rx_state <= RX_HALF;
    end
    RX_HALF: begin
        rx_timer_en <= 1;
        if (rx_timer == HALF_PERIOD - 1) begin      // Middle of the bit
            rx_state <= RX_IDLE;
            if (rxc_sync == 1'b0) begin
                rx_state    <= RX_DATA;
                rx_timer_en <= 0;
                rx_bit_cnt  <= 4'd0;
            end
        end
    end
    RX_DATA: begin
        rx_timer_en <= 1;
        if (rx_timer == BIT_PERIOD - 1) begin
            rx_shift    <= {rx_shift[6:0], rxc_sync};  // LSB first
            rx_bit_cnt  <= rx_bit_cnt + 1;
            rx_timer_en <= 0;
            if (rx_bit_cnt == LAST_BIT) begin
                rx_state    <= RX_STOP;
                rx_timer_en <= 0;
            end 
        end
    end
    RX_STOP: begin
        rx_timer_en <= 1;
        if (rx_timer == BIT_PERIOD - 1) begin
            if (!rxc_sync)   frame_error <= 1'b1;   // Checking STOP bit
            if (rx_complete) overrun     <= 1'b1;   // Overrun
            rx_data     <= rx_shift;
            rx_complete <= 1'b1;
            rx_state    <= RX_IDLE;
        end
    end
    endcase
    if (rst_err) begin                              // Reset errors
        frame_error <= 1'b0;
        overrun     <= 1'b0;
    end
end
endmodule