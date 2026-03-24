`timescale 1ns / 1ps
module uart_tb();

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
    
endclass
//--------------------------------------------
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
//--------------------------------------------
// Baud pulse generator

initial begin
    baud_pulse = 0;
    forever begin
        #(UART_CYCLE - CLK_CYCLE) baud_pulse = 1;
        #(CLK_CYCLE)              baud_pulse = 0;
    end
end
//--------------------------------------------
// Body of tester

initial begin
    
    init();
    
    fork
    
    begin
        repeat (NUMBER_OF_TESTS) begin
            tx_driver();
        end
    end
    begin
        rx_driver();
    end
    
    join
    
    check_data();
    print_result();
    
    $finish;
        
end

//===================================================================================
//--------------------------------------------
// Tx_randomizer

task automatic tx_randomizer();
    begin 
    txRandomizer tx_obj = new(tx_cfg);
    
    tx_obj.randomize();
    
    tx_rand_data       = tx_obj.data;
    tx_send_data_delay = 0;
    if(tx_obj.send_del)
        tx_send_data_delay = tx_obj.data_delay;
    end
endtask
//--------------------------------------------
// Rx_randomizer

task automatic rx_randomizer();
    begin
    rxRandomizer rx_obj = new(rx_cfg);
    
    rx_obj.randomize();
    
    rx_rand_data       = {rx_obj.stop_bit,rx_obj.data[7:0]};
    rx_send_data_delay = 0;
    rx_rden_delay      = 0;
    if(rx_obj.send_del)
        rx_send_data_delay = rx_obj.send_delay;
    if(rx_obj.wrong_rden)
        rx_rden_delay      = rx_obj.rden_delay;
    end
endtask
//===================================================================================
// TX driver

task automatic tx_driver();
    fork
    begin
        repeat (NUMBER_OF_TESTS) begin
            tx_randomizer();
            tx_send_data(tx_rand_data,tx_send_data_delay);
            tx_array_sent[tx_arr_sent_index] = tx_rand_data;
            tx_arr_sent_index                = tx_arr_sent_index + 1;
        end
    end
    begin
        repeat (NUMBER_OF_TESTS) begin
            receive_txc();
        end
    end
    join_none
    wait (tx_arr_rcvd_index == NUMBER_OF_TESTS);   
endtask
//--------------------------------------------
// RX driver

task automatic rx_driver();
    fork
    begin
        repeat (NUMBER_OF_TESTS) begin
            rx_randomizer();
            reverse_data(rx_rand_data);
            rx_send_data(rx_rand_data,rx_send_data_delay);
            rx_array_sent[rx_arr_sent_index] = rx_reversed_data;
            rx_arr_sent_index                = rx_arr_sent_index + 1;
        end
    end
    begin
        repeat (NUMBER_OF_TESTS) begin
            receive_rx_data(rx_rand_data);
        end
    end
    begin
        repeat (NUMBER_OF_TESTS) begin
            rx_rden_send(rx_rden_delay);
        end
    end
    join_none
    wait (rx_arr_sent_index == NUMBER_OF_TESTS);
endtask
//===================================================================================
// Sending tx data

task automatic tx_send_data(input [7:0] tx_rand_data, input int tx_send_data_delay); 
    begin
        #(tx_send_data_delay*CLK_CYCLE);
        
         if(tx_empty) tx_data = tx_rand_data;
         else begin
            wait(tx_empty);
            tx_data = tx_rand_data;
         end
        
        @(posedge clk) tx_wren = 1;
        @(posedge clk) tx_wren = 0;
        
        wait(tx_complete);
                
    end  
endtask
//--------------------------------------------
// Writting tx received data into array

task automatic receive_txc();    
    begin
        wait(!txc);
        #(UART_CYCLE+UART_CYCLE/2);
        
        for(int i=0; i<WORD; i++) begin
            tx_data_shift = {tx_data_shift[6:0],txc};
            #UART_CYCLE;
        end
        
        tx_array_received[tx_arr_rcvd_index] = tx_data_shift;
        tx_arr_rcvd_index                    = tx_arr_rcvd_index + 1;
        
    end
endtask
//--------------------------------------------
// Sending rxc data

task automatic rx_send_data(input [8:0] rx_rand_data, input int rx_send_data_delay);
    begin
        #(rx_send_data_delay*CLK_CYCLE);
        
        wait(baud_pulse);
        rxc = 0;
        
        for(int i=0; i<WORD+1; i++) begin
            #(UART_CYCLE);
            rxc = rx_rand_data[i];
        end
        #(UART_CYCLE) rxc = 1;
        if(!rx_rand_data[8]) #UART_CYCLE; // For correct detecting start bit
        
        if(!rx_rand_data[8]) begin
            if(!frame_error) $display("INFO : ! frame_error (num test = %d)", rx_arr_rcvd_index);
            reset_err();
        end              
    end
endtask
//--------------------------------------------
// Writting rx received data into array

task automatic receive_rx_data(input [8:0] rx_rand_data);
    begin
        if(!overrun_flag) begin
            @(posedge rx_complete) begin
                rx_array_received[rx_arr_rcvd_index] = rx_data;
                rx_arr_rcvd_index                    = rx_arr_rcvd_index + 1;
            end
        end
        else begin
            @(posedge overrun) begin
                rx_array_received[rx_arr_rcvd_index] = rx_data;
                rx_arr_rcvd_index                    = rx_arr_rcvd_index + 1;
            end
            overrun_flag = 0;
        end
    end
endtask

//--------------------------------------------
// Send rx_rd with delay

task automatic rx_rden_send(input int rx_rden_delay);
    begin
        @(posedge rx_complete) begin
            
            if(rx_rden_delay > UART_CYCLE) 
                overrun_flag = 1;
            
            #(rx_rden_delay*CLK_CYCLE);
            
            if(overrun) begin
                reset_err();
            end            
            
            @(posedge clk) rx_rden = 1;
            @(posedge clk) rx_rden = 0;
        end
    end
endtask
//--------------------------------------------
//Checking data

task check_data;
    begin
        for(int i=0; i<NUMBER_OF_TESTS; i++) begin
            if(tx_array_received[i] != tx_array_sent[i]) begin
                $display("INFO (tx): Sent = %d, Received = %d (num test = %d)", tx_array_sent[i], tx_array_received[i], i);
                error();
            end
            if(rx_array_received[i] != rx_array_sent[i]) begin
                $display("INFO (rx): Sent = %d, Received = %d (num test = %d)", rx_array_sent[i], rx_array_received[i], i);
                error();
            end
        end
    end
endtask
//
// Revercing data
task automatic reverse_data(input [8:0] rx_rand_data);
    begin
        for(int i=0; i<WORD; i++) begin
            rx_reversed_data[i] = rx_rand_data[7-i];
        end
    end
endtask
//--------------------------------------------
// Reset errors

task automatic reset_err();
    begin
        @(posedge clk) rst_err = 1;
        @(posedge clk) rst_err = 0;
    end
endtask
//--------------------------------------------
// Initialization

task init();
    begin
        rxc     = 1'b1;
        rx_rden = 1'b0;
        rst_err = 1'b0;
        tx_wren = 1'b0;
    end
endtask
//--------------------------------------------
// Error

task automatic error();
    
    err = err + 1;
    
endtask
//--------------------------------------------
// Print test result

task print_result();
    
    if(err) $display("INFO : Test failed! ");
    else    $display("INFO : Test succeed!");
    
endtask
//===================================================================================
uart    dut0 
(
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

