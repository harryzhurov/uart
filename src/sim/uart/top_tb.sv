`timescale 1ns / 1ps

module tb_uart;

    // Generator 100 MHz
    logic clk;
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    logic       txc, rxc;
    logic [7:0] tx_data;
    logic       tx_wren;
    logic [7:0] rx_data;
    logic       rx_rden;
    logic       rst_err;
    logic       tx_empty, tx_complete, rx_complete, frame_error, overrun;

    // Initialization
    uart dut (
        .clk         (clk),
        .txc         (txc),
        .rxc         (rxc),
        .tx_data     (tx_data),
        .tx_wren     (tx_wren),
        .rx_data     (rx_data),
        .rx_rden     (rx_rden),
        .tx_empty    (tx_empty),
        .tx_complete (tx_complete),
        .rx_complete (rx_complete),
        .frame_error (frame_error),
        .overrun     (overrun),
        .rst_err     (rst_err)
    );

    // Test part
    initial begin
        // Zero mode
        tx_data = 8'h00;
        tx_wren = 0;
        rx_rden = 0;
        rst_err = 0;
        rxc = 1;

        #100;
        @(posedge clk) rst_err = 1;  // Reset errors
        @(posedge clk) rst_err = 0;
        #100;

        // ======================================================
        // Test 1: Transmittion of data 0x55
        // ======================================================
        $display("Test 1: Transmit 0x55");
        tx_data = 8'h55;
        @(posedge clk) tx_wren = 1;
        @(posedge clk) tx_wren = 0;
        wait (tx_complete);
        $display("tx_empty = %b \nTest 1 - Success", tx_empty);

        // ======================================================
        // Test 2: Receiving data 0xAA
        // ======================================================
        $display("Test 2: Receive 0xAA");
        // Start (0)
        rxc = 0; #8680;
        // Data MSB first: 0xAA = 10101010
        rxc = 1; #8680; // bit 0
        rxc = 0; #8680; // bit 1
        rxc = 1; #8680; // bit 2
        rxc = 0; #8680; // bit 3
        rxc = 1; #8680; // bit 4
        rxc = 0; #8680; // bit 5
        rxc = 1; #8680; // bit 6
        rxc = 0; #8680; // bit 7
        rxc = 1; #8680; // Stop-bit (1)
        
        wait (rx_complete);
        @(posedge clk) rx_rden = 1;
        @(posedge clk) rx_rden = 0;
        if (rx_data !== 8'hAA)
            $error("Expected 0xAA, got %h", rx_data);
        else
            $display("Test 2 - Success");

        // ======================================================
        // Test 3: Overrunning
        // ======================================================
        $display("Test 3: Overrun test");
        rxc = 0; #8680; // Start
        // 0x55 = 01010101 MSB
        rxc = 0; #8680;
        rxc = 1; #8680;
        rxc = 0; #8680;
        rxc = 1; #8680;
        rxc = 0; #8680;
        rxc = 1; #8680;
        rxc = 0; #8680;
        rxc = 1; #8680;
        rxc = 1; #8680; // Stop
        wait (rx_complete);

        // Next byte (0xAA) - expecting overrun
        rxc = 0; #8680; // Start
        rxc = 1; #8680; // bit 0
        rxc = 0; #8680; 
        rxc = 1; #8680;
        rxc = 0; #8680;
        rxc = 1; #8680;
        rxc = 0; #8680;
        rxc = 1; #8680;
        rxc = 0; #8680; // bit 7
        rxc = 1; #8680; // Stop
        wait (rx_complete);

        if (overrun !== 1'b1)
            $error("Overrun not set");
        else
            $display("Overrun set correctly");

        @(posedge clk) rx_rden = 1;
        @(posedge clk) rx_rden = 0;
        if (rx_data !== 8'hAA)
            $error("Expected 0xAA after overrun, got %h", rx_data);
        else
            $display("Data after overrun OK");

        // Reset error
        @(posedge clk) rst_err = 1;
        @(posedge clk) rst_err = 0;
        if (overrun !== 1'b0)
            $error("Overrun not cleared");
        else
            $display("Overrun cleared \nTest 3 - Success");

        // ======================================================
        // Test 4: Frame error
        // ======================================================
        $display("Test 4: Frame error test");
        // Send 0x55 but Stop_bit = 0
        rxc = 0; #8680; // Start
        rxc = 0; #8680;
        rxc = 1; #8680;
        rxc = 0; #8680;
        rxc = 1; #8680;
        rxc = 0; #8680;
        rxc = 1; #8680;
        rxc = 0; #8680;
        rxc = 1; #8680; // bit 7
        // Stop_bit = 0
        rxc = 0; #8680;

        wait (rx_complete);
        if (frame_error !== 1'b1)
            $error("Frame error not set");
        else
            $display("Frame error set");

        @(posedge clk) rx_rden = 1;
        @(posedge clk) rx_rden = 0;

        // Reset error
        @(posedge clk) rst_err = 1;
        @(posedge clk) rst_err = 0;
        if (frame_error !== 1'b0)
            $error("Frame error not cleared");
        else
            $display("Frame error cleared \nTest 4 - Success");

        $display("All tests completed.");
        #500ms
        $finish;
    end

//    always @(posedge baud_tick) begin
//        if (tx_complete) $display("[%t] TX complete", $time);
//        if (rx_complete) $display("[%t] RX complete, data = %h", $time, rx_data);
//    end

endmodule