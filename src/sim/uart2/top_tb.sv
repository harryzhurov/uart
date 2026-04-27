`timescale 1ns / 1ps
module UART_TESTBENCH;
localparam NUMBER_OF_TESTS = 100  ;
localparam WORD            = 8   ;
localparam NUM_TEST_LEN    = 9   ;

localparam CLK_FREQ       = 100_000_000;
localparam BAUD_RATE      = 115200;
localparam BIT_PERIOD     = CLK_FREQ / BAUD_RATE;
localparam HALF_PERIOD    = BIT_PERIOD / 2;
localparam CLK_CYCLE      = 1_000_000_000/CLK_FREQ  ;
localparam UART_CYCLE     = BIT_PERIOD*CLK_CYCLE;
//---------------------------------------------
typedef struct {
    int zero_data        = 100;  // probability of data = 2'h00 (1%)
    int send_del_exist   = 1000;  // probobility of delay existance before data sending (10%)
    int send_del_dist    = 5000; // in range [0:5000] clk cycles
    }
    tx_random_t;
    tx_random_t tx_cfg;

typedef struct {
    int wrong_stop_exist = 200;  // probability of stop bit = 0 (2%)
    int send_del_exist   = 200;  // probability of delay existance before data sending (2%)
    int send_del_dist    = 10000;// in range [0:10000] clk cycles
    int rden_del_exist   = 1000;  // probability of delay existance before rx_rden flag sending (10%)
    int rden_del_dist    = 10000;// in range [0:10000] clk cycles
    int zero_data        = 500;  // probability of data = 2'h00 (5%)
    }
    rx_random_t;
    rx_random_t rx_cfg;
//---------------------------------------------
// UART interface

logic            clk;
logic [WORD-1:0] tx_data;
logic [WORD-1:0] rx_data;
logic            txc;
logic            rxc;
logic            tx_wren;
logic            rx_rden;
logic            rst_err;
logic            tx_empty;
logic            tx_complete;
logic            rx_complete;
logic            frame_error;
logic            overrun;
//---------------------------------------------
// Declaration internal signals

logic [ WORD-1:0] tx_array_sent     [NUMBER_OF_TESTS-1:0] = '{default: 0};
logic [ WORD-1:0] rx_array_sent     [NUMBER_OF_TESTS-1:0] = '{default: 0};
logic [ WORD-1:0] tx_array_received [NUMBER_OF_TESTS-1:0] = '{default: 0};
logic [ WORD-1:0] rx_array_received [NUMBER_OF_TESTS-1:0] = '{default: 0};
logic [ WORD-1:0] tx_rand_data;
logic [ WORD-1:0] rx_reversed_data;
logic [  WORD:0 ] rx_rand_data;
logic [    7:0  ] tx_data_shift;

logic             overrun_flag       = 0;
logic             baud_pulse         = 0;

int               rx_send_data_delay = 0;
int               rx_rden_delay      = 0;
int               tx_send_data_delay = 0;
int               tx_arr_sent_index  = 0;
int               tx_arr_rcvd_index  = 0;
int               rx_arr_sent_index  = 0;
int               rx_arr_rcvd_index  = 0;
int               err                = 0;
//===================================================================================
// Class tx random

class txRandomizer;
    int zero_data;
    int send_del_exist;
    int send_del_dist;

    rand bit       send_del;
    rand bit [7:0] data;
    rand int       data_delay;

    function new(tx_random_t tx_cfg);
        zero_data      = tx_cfg.zero_data;
        send_del_exist = tx_cfg.send_del_exist;
        send_del_dist  = tx_cfg.send_del_dist;
    endfunction

    constraint cst
    {
        data       inside {[0:255          ]};
        data_delay inside {[0:send_del_dist]};

        send_del   dist {0 := (100 - (send_del_exist/100)), 1 := (send_del_exist/100)};
    }

// Class rx random

class rxRandomizer;
    int wrong_stop_exist;
    int send_del_exist;
    int send_del_dist;
    int rden_del_exist;
    int rden_del_dist;
    int zero_data;

    rand bit       stop_bit;
    rand bit       send_del;
    rand bit       wrong_rden;
    rand int       send_delay;
    rand int       rden_delay;
    rand bit [7:0] data;

    function new(rx_random_t rx_cfg);
        wrong_stop_exist = rx_cfg.wrong_stop_exist;
        send_del_exist   = rx_cfg.send_del_exist;
        send_del_dist    = rx_cfg.send_del_dist;
        rden_del_exist   = rx_cfg.rden_del_exist;
        rden_del_dist    = rx_cfg.rden_del_dist;
        zero_data        = rx_cfg.zero_data;
    endfunction

    constraint cst
    {
        data       inside {[0:255          ]};
        rden_delay inside {[0:rden_del_dist]};
        send_delay inside {[0:send_del_dist]};

        stop_bit    dist {0 := (wrong_stop_exist/100)        , 1 := (100 - wrong_stop_exist/100) };
        send_del    dist {0 := (100 - (send_del_exist/100))  , 1 := (send_del_exist/100)         };
        wrong_rden  dist {0 := (100 - (rden_del_exist/100))  , 1 := (rden_del_exist/100)         };
        data        dist {0 := (zero_data/100)               , [1:255] := (100 - (zero_data/100))};
    }

endclass
//===================================================================================
// Generator 100 MHz

initial begin
    clk = 0;
    forever #(CLK_CYCLE/2) clk = ~clk;
end
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