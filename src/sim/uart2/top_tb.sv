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

typedef struct 
{
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

typedef enum 
{ 
    TX, 
    RX 
} 
direction_t;
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
// Class Generator

class Generator;
    //------------------------------------------------------
    class Tx_trans;
    
        static int     count = 0;
        int            id;
        
        int            zero_data;
        int            send_del_exist;
        int            send_del_dist;
    
        rand bit       send_del;
        rand int       data_delay;
        rand bit [7:0] data;
    
        function new(tx_random_t tx_cfg);
            
            id             = count++;
            
            zero_data      = tx_cfg.zero_data;
            send_del_exist = tx_cfg.send_del_exist;
            send_del_dist  = tx_cfg.send_del_dist;
            
        endfunction
    
        constraint cst
        {
            data       inside {[0:255          ]};
            data_delay inside {[0:send_del_dist]};
            
            data        dist  {0 := (zero_data/100)               , [1:255] := (100 - (zero_data/100))};
            send_del    dist  {0 := (100 - send_del_exist/100)    , 1       := (send_del_exist/100)   };
            
            (send_del==0) -> (data_delay==0);
            solve send_del before data_delay;          
            
        }
    
    endclass
    //------------------------------------------------------ 
    class Rx_trans;
    
        static int     count = 0;
        int            id;
    
        int            wrong_stop_exist;
        int            send_del_exist;
        int            send_del_dist;
        int            rden_del_exist;
        int            rden_del_dist;
        int            zero_data;
    
        rand bit       stop_bit;
        rand bit       wrong_rden;
        rand int       send_delay;
        rand int       rden_delay;
        rand bit [7:0] data;
    
        function new(rx_random_t rx_cfg);
            
            id               = count++;
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
    
            stop_bit    dist  {0 := (wrong_stop_exist/100)        , 1       := (100 - wrong_stop_exist/100) };
            wrong_rden  dist  {0 := (100 - (rden_del_exist/100))  , 1       := (rden_del_exist/100)         };
            data        dist  {0 := (zero_data/100)               , [1:255] := (100 - (zero_data/100))      };
            
            (wrong_rden==0) -> (rden_delay==0);
            solve wrong_rden before rden_delay;
        }
    
    endclass
    //------------------------------------------------------
    
    Tx_trans tx_trans;
    Rx_trans rx_trans;
    
    mailbox gen2drv_tx;
    mailbox gen2drv_rx;
    
    mailbox gen2scb_tx;
    mailbox gen2scb_rx;
    
    function new(mailbox gen2drv_tx,mailbox gen2drv_rx,mailbox gen2scb_tx,mailbox gen2scb_rx);
    
        this.gen2drv_tx = gen2drv_tx;
        this.gen2drv_rx = gen2drv_rx;
        this.gen2scb_tx = gen2scb_tx;
        this.gen2scb_rx = gen2scb_rx;
        
    endfunction
    
    task automatic run();
    
        repeat (NUMBER_OF_TESTS) begin
        
            tx_trans = new(tx_cfg);
            tx_trans.randomize();
            rx_trans = new(rx_cfg);
            rx_trans.randomize();
            
            if(!tx_trans.randomize()) $display("INFO: ERROR: tx_trans_randomization failed!");
            if(!rx_trans.randomize()) $display("INFO: ERROR: rx_trans_randomization failed!");
            
            gen2drv_tx.put(tx_trans);
            gen2drv_rx.put(rx_trans);
            gen2scb_tx.put(tx_trans);
            gen2scb_rx.put(rx_trans);
            
        end
    
    endtask
    
    
endclass
//===================================================================================
// Class Driver

class Driver;

    int       num_trans_tx;
    int       num_trans_rx;

    mailbox   gen2drv_tx;
    mailbox   gen2drv_rx;
    
    Generator gen;
    
    Generator::Tx_trans tx_trans;
    Generator::Rx_trans rx_trans;
    
    function new(mailbox gen2drv_tx, mailbox gen2drv_rx);
    
        this.gen2drv_tx = gen2drv_tx;
        this.gen2drv_rx = gen2drv_rx;
    
    endfunction 
    
    task automatic run_tx();
    
        repeat (NUMBER_OF_TESTS) begin
        
            gen2drv_tx.get(tx_trans);
            
            #(tx_trans.data_delay*CLK_CYCLE);
    
             if(tx_empty) 
                tx_data = tx_trans.data;
             else begin
                wait(tx_empty);
                tx_data = tx_trans.data;
             end
    
            @(posedge clk) tx_wren = 1;
            @(posedge clk) tx_wren = 0;
    
            wait(tx_complete);
            
            num_trans_tx++;
        
        end
    
    endtask
    
    task automatic run_rx();
    
        repeat (NUMBER_OF_TESTS) begin
        
            gen2drv_rx.get(rx_trans);
            
            #(rx_trans.send_delay*CLK_CYCLE);
    
            wait(baud_pulse);
            rxc = 0;
    
            for(int i=0; i<WORD; i++) begin
                #(UART_CYCLE);
                rxc = rx_trans.data[i];
            end
            
            #(UART_CYCLE) rxc = rx_trans.stop_bit;
            
            #(UART_CYCLE) rxc = 1;
            
            num_trans_rx++;
        
        end
    
    endtask
    
    task automatic run();
    
        fork
        
            run_tx();
            run_rx();
        
        join
    
    endtask

endclass
//===================================================================================
// Class Scoreboard

class Scoreboard;

    int         num_trans_tx;
    int         num_trans_rx;
    
    logic [7:0] tx_data_shift;
    logic [7:0] rx_data_rcvd;

    mailbox   gen2scb_tx;
    mailbox   gen2scb_rx;
    mailbox   mnt2scb_tx;
    mailbox   mnt2scb_rx;
    
    Generator gen;
    
    Generator::Tx_trans tx_trans;
    Generator::Rx_trans rx_trans;
    
    function new(mailbox gen2scb_tx, mailbox gen2scb_rx, mailbox mnt2scb_tx, mailbox mnt2scb_rx);
    
        this.gen2scb_tx = gen2scb_tx;
        this.gen2scb_rx = gen2scb_rx;
        this.mnt2scb_tx = mnt2scb_tx;
        this.mnt2scb_rx = mnt2scb_rx;
    
    endfunction
    
    task automatic run();
    
        fork
            begin
                gen2scb_tx.get(tx_trans);
                mnt2scb_tx.get(tx_data_shift);
                if(tx_trans.data !== tx_data_shift) begin
                
                    $write("INFO: Error: tx_data doesn`t match, trans ID = %d", tx_trans.id);
                    $write("/nSent data = %d, Received = %d",tx_trans.data,tx_data_shift);
                    $display();
                    
                end
                
                num_trans_tx++;
                
            end
            begin
            
                gen2scb_rx.get(rx_data_rcvd);
                mnt2scb_rx.get(rx_data_rcvd);
                
                for(int i=0; i<WORD; i++) begin
                    rx_reversed_data[i] = rx_data_rcvd[7-i];
                end
                
                if(rx_trans.data !== rx_reversed_data) begin
                
                    $write("INFO: Error: rx_data doesn`t match, trans ID = %d", rx_trans.id);
                    $write("/nSent data = %d, Received = %d",rx_trans.data,rx_reversed_data);
                    $display(); 
                
                end
                
                num_trans_rx++;
            
            end
        
        join_any
    
    endtask

endclass
//===================================================================================
// Class Monitor

class Monitor;

    int         num_trans_tx;
    int         num_trans_rx;
    
    logic [7:0] tx_data_shift;

    mailbox     mnt2scb_tx;
    mailbox     mnt2scb_rx;
    
    function new(mailbox mnt2scb_tx, mailbox mnt2scb_rx);
    
        this.mnt2scb_tx = mnt2scb_tx;
        this.mnt2scb_rx = mnt2scb_rx;
    
    endfunction 
    
    task automatic receive_rx();
    
        if(!overrun_flag) begin
            @(posedge rx_complete) begin
                mnt2scb_rx.put(rx_data);
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

