`timescale 1ns / 1ps

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

    localparam CLK_FREQ   = 100_000_000;
    localparam BAUD_RATE  = 115200;
    localparam BIT_PERIOD = CLK_FREQ / BAUD_RATE; // 868
    localparam HALF_PERIOD = BIT_PERIOD / 2;      // 434

    // ======================================================
    //  Generator of refference frequancy UART
    // ======================================================
    logic [9:0] baud_cnt = 0;
    logic baud_tick;
    always @(posedge clk) begin
        if (baud_cnt == BIT_PERIOD - 1) begin
            baud_cnt <= 0;
            baud_tick <= 1;
        end else begin
            baud_cnt <= baud_cnt + 1;
            baud_tick <= 0;
        end
    end

    // ======================================================
    //  Transmitter (TX)
    // ======================================================
    typedef enum logic [1:0] { TX_IDLE, TX_START, TX_DATA, TX_STOP } tx_state_t;
    tx_state_t tx_state = TX_IDLE;

    logic [7:0] tx_buffer;
    logic [7:0] tx_shift;
    logic [3:0] tx_bit_cnt;
    logic tx_empty_reg;
    logic tx_complete_reg;

    // Catch tx_wren
    always @(posedge clk) begin
        if (tx_wren) begin
            tx_buffer <= tx_data;
            tx_empty_reg <= 1'b0;   // buffer is busy
        end
    end

    // Body of transmitter
    always @(posedge clk) begin
        case (tx_state)
            TX_IDLE: begin
                tx_complete_reg <= 1'b0;
                if (tx_empty_reg == 1'b0) begin
                    tx_shift <= tx_buffer;
                    tx_empty_reg <= 1'b1;   // buffer is ready for new data
                    tx_state <= TX_START;
                end
            end
            TX_START: begin
                if (baud_tick) begin
                    txc <= 1'b0;    // Start bit
                    tx_bit_cnt <= 4'd0;
                    tx_state <= TX_DATA;
                end
            end
            TX_DATA: begin
                if (baud_tick) begin
                    txc <= tx_shift[7];     // MSB first
                    tx_shift <= {tx_shift[6:0],1'b0 };      // shift to the left
                    if (tx_bit_cnt == 4'd7) begin
                        tx_state <= TX_STOP;
                    end else begin
                        tx_bit_cnt <= tx_bit_cnt + 1;
                    end
                end
            end
            TX_STOP: begin
                if (baud_tick) begin
                    txc <= 1'b1;                           // Stop bit
                    if (tx_empty_reg == 1'b0) begin        // Next data is already ready
                        tx_shift <= tx_buffer;
                        tx_empty_reg <= 1'b1;
                        tx_state <= TX_START;
                    end else begin
                        tx_state <= TX_IDLE;
                        tx_complete_reg <= 1'b1;           // Done
                    end
                end
            end
        endcase
    end

    assign tx_empty   = tx_empty_reg;
    assign tx_complete = tx_complete_reg;

    // -----------------------------------------------------------------
    //  Receiver (RX)
    // -----------------------------------------------------------------
    // Synchronization
    logic rxc_meta, rxc_sync;
    always @(posedge clk) begin
        rxc_meta <= rxc;
        rxc_sync <= rxc_meta;
    end

    // Catch start bit
    logic rxc_prev;
    always @(posedge clk) begin
        rxc_prev <= rxc_sync;
    end
    wire start_detected = (rxc_prev == 1'b1 && rxc_sync == 1'b0);

    typedef enum logic [2:0] { RX_IDLE, RX_HALF, RX_DATA, RX_STOP } rx_state_t;
    rx_state_t rx_state = RX_IDLE;

    logic [9:0] rx_timer;
    logic [3:0] rx_bit_cnt;
    logic [7:0] rx_shift;
    logic [7:0] rx_data_reg;
    logic rx_complete_reg = 1'b0;
    logic frame_error_reg = 1'b0;
    logic overrun_reg = 1'b0;
    
    // Catch rx_rden
    always @(posedge clk) begin
        if (rx_rden) begin
            rx_complete_reg <= 1'b0;
        end

        // Body of receiver
        case (rx_state)
            RX_IDLE: begin
                rx_timer <= 10'd0;
                if (start_detected) begin
                    rx_state <= RX_HALF;
                end
            end
            RX_HALF: begin
                rx_timer <= rx_timer + 1;
                if (rx_timer == HALF_PERIOD - 1) begin  // Middle of the ref freq
                    if (rxc_sync == 1'b0) begin
                        rx_state <= RX_DATA;
                        rx_timer <= 10'd0;
                        rx_bit_cnt <= 4'd0;
                    end else begin
                        rx_state <= RX_IDLE;
                    end
                end
            end
            RX_DATA: begin
                rx_timer <= rx_timer + 1;
                if (rx_timer == BIT_PERIOD - 1) begin
                    // MSB first
                    rx_shift <= {rx_shift[6:0], rxc_sync};
                    if (rx_bit_cnt == 4'd7) begin
                        rx_state <= RX_STOP;
                        rx_timer <= 10'd0;
                    end else begin
                        rx_bit_cnt <= rx_bit_cnt + 1;
                        rx_timer <= 10'd0;
                    end
                end
            end
            RX_STOP: begin
                rx_timer <= rx_timer + 1;
                if (rx_timer == BIT_PERIOD - 1) begin
                    // Checking stop bit
                    if (rxc_sync != 1'b1) begin
                        frame_error_reg <= 1'b1;
                    end
                    // Overrun?
                    if (rx_complete_reg) begin
                        overrun_reg <= 1'b1;
                    end
                    rx_data_reg <= rx_shift;
                    rx_complete_reg <= 1'b1;
                    rx_state <= RX_IDLE;
                end
            end
        endcase

        // Reset errors
        if (rst_err) begin
            frame_error_reg <= 1'b0;
            overrun_reg     <= 1'b0;
        end
    end

    assign rx_data     = rx_data_reg;
    assign rx_complete = rx_complete_reg;
    assign frame_error = frame_error_reg;
    assign overrun     = overrun_reg;

    // Initialization of txc
    initial txc = 1'b1;

endmodule