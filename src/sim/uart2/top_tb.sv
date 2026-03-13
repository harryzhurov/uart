`timescale 1ns / 1ps
module UART_TESTBENCH;
//===================================================================================
logic       clk;
logic       txc;
logic       rxc;
logic [7:0] tx_data;
logic       tx_wren;
logic [7:0] rx_data;
logic       rx_rden;
logic       rst_err;
logic       tx_empty;
logic       tx_complete;
logic       rx_complete;
logic       frame_error;
logic       overrun;
//-----------------------------------------------------------------------------------
integer     rx_rand_delay;
integer     rx_rand_rden;
integer     tx_rand_delay;
integer     err = 0;
logic [7:0] rx_rand_data_invert;
logic [7:0] rx_data_buffer;
logic [7:0] rx_rand_data;
logic [7:0] tx_rand_data;
logic [7:0] tx_accum;
logic       rand_stop_bit;

integer     BIT_UART = 8680;
integer     HALF_BIT_UART = BIT_UART/2;
integer     NUMBER_OF_TESTS = 20;
//===================================================================================
//-----------------------------------------------------------------------------------
// Generator 100 MHz
//-----------------------------------------------------------------------------------
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end
//-----------------------------------------------------------------------------------
// Test part
//-----------------------------------------------------------------------------------
initial begin
    initialization();
    fork
    begin
        repeat (NUMBER_OF_TESTS) begin
            rx_random();
            rx_send_data();
        end
    end
    begin
        repeat (NUMBER_OF_TESTS) begin
            tx_random();
            tx_send_data();
        end
    end 
    join
    if(err) $display("Test completed: FAILED ");
    else    $display("Test completed: SUCCESS");
    $finish;
end
//===================================================================================
//-----------------------------------------------------------------------------------
// Tasks
//-----------------------------------------------------------------------------------
task automatic initialization();
    tx_data = 8'h00;
    tx_wren = 0;
    rx_rden = 0;
    rxc = 1;
    @(posedge clk) rst_err = 1;     // Reset errors
    @(posedge clk) rst_err = 0;
endtask
//-----------------------------------------------------------------------------------
task automatic rx_random();
    rx_data_buffer = rx_rand_data_invert;
    rx_rand_data    = $urandom_range(0, 255);
    rand_stop_bit   = $urandom_range(0,   1);
    rx_rand_delay   = $urandom_range(0, 10*BIT_UART);
    rx_rand_rden    = $urandom_range(0, 15*BIT_UART);
    for(int i=0; i<8; i++) rx_rand_data_invert[i] = rx_rand_data[7-i];  // LSB to MSB for checking
endtask
//-----------------------------------------------------------------------------------
task automatic rx_send_data();
    fork
    begin
        #rx_rand_delay;
        rxc = 1'b0;                                                     // START BIT
        for(int i=0; i<8; i++) begin
            #BIT_UART;
            rxc = rx_rand_data[i];
        end
        #BIT_UART;
        rxc = rand_stop_bit;                                            // STOP_BIT (0 or 1)
        #(BIT_UART);
        wait(rx_complete);
        rx_check_errors();
        rxc = 1;                                                        // Return rxc to high 
    end
    begin
        #rx_rand_rden;                                                  // Random delay for checking overrun
        @(posedge clk) rx_rden = 1'b1;
        @(posedge clk) rx_rden = 1'b0;
    end
    begin
        rx_check_data();
    end
    join 
endtask
//-----------------------------------------------------------------------------------
task automatic rx_check_data();
    if (rx_data !== rx_data_buffer) begin
        Error();
        $display("ERROR: (rx) Data doesn`t match");
        $display("Waited: %d, Received: %d", rx_data_buffer, rx_data);
    end
endtask
//-----------------------------------------------------------------------------------
task automatic rx_check_errors();
    if(!rand_stop_bit) begin
        if(!frame_error) begin
            Error();
            $display("ERROR: (rx) Frame_error");
        end
    //if (overrun) $display("Overrun, delay = %d", rx_rand_delay);
    if(frame_error || overrun) reset_errors();
    end
endtask
//-----------------------------------------------------------------------------------
task automatic reset_errors();
    @(posedge clk) rst_err = 1;
    @(posedge clk) rst_err = 0;
    if (overrun) begin
        Error();
        $display("ERROR: No reset errors occurred");
    end
    if (frame_error) begin
        Error();
        $display("ERROR: No reset errors occurred");
    end
endtask
//-----------------------------------------------------------------------------------
task automatic tx_random();
    tx_rand_data  = $urandom_range(0, 255);
    tx_rand_delay = $urandom_range(0, 10*BIT_UART);
endtask
//-----------------------------------------------------------------------------------
task automatic tx_send_data();
    #tx_rand_delay;
    tx_data = tx_rand_data;
    @(posedge clk) tx_wren = 1;
    @(posedge clk) tx_wren = 0;
    accum_tx_data();
    wait(tx_complete);
    if(!txc) begin
        Error();
        $display("ERROR: (tx): Stop bit = 0");
    end
    tx_check_data();
endtask
//-----------------------------------------------------------------------------------
task automatic accum_tx_data();                                         // Accumulate tx data for checking
    wait(!txc);
    #(HALF_BIT_UART);
    repeat (8) begin
        #BIT_UART;
        tx_accum = {tx_accum[6:0], txc};
    end
endtask
//-----------------------------------------------------------------------------------
task automatic tx_check_data();
    wait (tx_complete); 
    if (tx_data !== tx_accum) begin
        Error();
        $display("ERROR: (tx) Data doesn`t match");
    end
endtask
//-----------------------------------------------------------------------------------
task Error();
    err = err + 1;
endtask
//===================================================================================
//-----------------------------------------------------------------------------------
// Declaration
//-----------------------------------------------------------------------------------
UART_MAIN dut (
    .clk         ( clk         ),
    .txc         ( txc         ),
    .rxc         ( rxc         ),
    .tx_data     ( tx_data     ),
    .tx_wren     ( tx_wren     ),
    .rx_data     ( rx_data     ),
    .rx_rden     ( rx_rden     ),
    .tx_empty    ( tx_empty    ),
    .tx_complete ( tx_complete ),
    .rx_complete ( rx_complete ),
    .frame_error ( frame_error ),
    .overrun     ( overrun     ),
    .rst_err     ( rst_err     )
);
endmodule