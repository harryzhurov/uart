`timescale 1ns / 1ps

module uart_tb();
//===================================================================================
// Parameters

localparam NUMBER_OF_TESTS = 100  ;
localparam WORD            = 8   ;

localparam CLK_FREQ       = 100_000_000;
localparam BAUD_RATE      = 115200;
localparam BIT_PERIOD     = CLK_FREQ / BAUD_RATE;
localparam HALF_PERIOD    = BIT_PERIOD / 2;
localparam CLK_CYCLE      = 1_000_000_000/CLK_FREQ  ;
localparam UART_CYCLE     = BIT_PERIOD*CLK_CYCLE;

typedef struct 
{
    int zero_data        = 100;     // probability of data = 2'h00 (1%)
    int send_del_exist   = 1000;    // probobility of delay existance before data sending (10%)
    int send_del_dist    = 5000;    // in range [0:5000] clk cycles
}
tx_random_t;
tx_random_t tx_cfg;

typedef struct 
{
    int wrong_stop_exist = 200;     // probability of stop bit = 0 (2%)
    int send_del_exist   = 200;     // probability of delay existance before data sending (2%)
    int send_del_dist    = 10000;   // in range [0:10000] clk cycles
    int rden_del_exist   = 1000;    // probability of delay existance before rx_rden flag sending (10%)
    int rden_del_dist    = 15000;   // in range [0:15000] clk cycles
    int zero_data        = 500;     // probability of data = 2'h00 (5%)
}
rx_random_t;
rx_random_t rx_cfg;
//===================================================================================
// Signals

typedef struct 
{ 
    logic [7:0] data;
    int         data_delay;  
    int         id;
} 
tx_trans_t;

typedef struct 
{ 
    logic [7:0] data;
    int         rden_delay;
    int         send_delay;
    int         id;
    bit         stop_bit;
} 
rx_trans_t;
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

logic             overrun_flag       = 0;
logic             baud_pulse         = 0;
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
    
    tx_trans_t tx_tr_gen;
    rx_trans_t rx_tr_gen;
    
    mailbox #(tx_trans_t) gen2drv_tx;
    mailbox #(rx_trans_t) gen2drv_rx;
    
    mailbox #(tx_trans_t) gen2scb_tx;
    mailbox #(rx_trans_t) gen2scb_rx;
    
    mailbox #(   int    ) gen2mnt_rx;
    
    function new(mailbox #(tx_trans_t) gen2drv_tx,
                 mailbox #(rx_trans_t) gen2drv_rx,
                 mailbox #(tx_trans_t) gen2scb_tx,
                 mailbox #(rx_trans_t) gen2scb_rx,
                 mailbox #(   int    ) gen2mnt_rx);
    
        this.gen2drv_tx = gen2drv_tx;
        this.gen2drv_rx = gen2drv_rx;
        this.gen2scb_tx = gen2scb_tx;
        this.gen2scb_rx = gen2scb_rx;
        this.gen2mnt_rx = gen2mnt_rx;
        
    endfunction
    
    task automatic run();
    
        repeat (NUMBER_OF_TESTS) begin
        
            tx_trans = new(tx_cfg);
            tx_trans.randomize();
            rx_trans = new(rx_cfg);
            rx_trans.randomize();
            
            if(!tx_trans.randomize()) $display("INFO: ERROR: tx_trans_randomization failed!");
            if(!rx_trans.randomize()) $display("INFO: ERROR: rx_trans_randomization failed!");
            
            tx_tr_gen.data       = tx_trans.data;
            tx_tr_gen.data_delay = tx_trans.data_delay;
            tx_tr_gen.id         = tx_trans.id;
            
            rx_tr_gen.data       = rx_trans.data;
            rx_tr_gen.send_delay = rx_trans.send_delay;
            rx_tr_gen.rden_delay = rx_trans.rden_delay;
            rx_tr_gen.stop_bit   = rx_trans.stop_bit;
            rx_tr_gen.id         = tx_trans.id;
            
            
            gen2drv_tx.put(     tx_tr_gen       );
            gen2drv_rx.put(     rx_tr_gen       );
            gen2scb_tx.put(     tx_tr_gen       );
            gen2scb_rx.put(     rx_tr_gen       );
            gen2mnt_rx.put(rx_tr_gen.rden_delay );
            
        end
    
    endtask
    
    
endclass
//===================================================================================
// Class Driver

class Driver;

    int       num_trans_tx;
    int       num_trans_rx;
    
    tx_trans_t tx_tr_drv;
    rx_trans_t rx_tr_drv;

    mailbox #(tx_trans_t) gen2drv_tx;
    mailbox #(rx_trans_t) gen2drv_rx;
    
    function new(mailbox #(tx_trans_t) gen2drv_tx,
                 mailbox #(rx_trans_t) gen2drv_rx);
    
        this.gen2drv_tx = gen2drv_tx;
        this.gen2drv_rx = gen2drv_rx;
    
    endfunction 
    
    task automatic run_tx();
    
        forever begin
        
            gen2drv_tx.get(tx_tr_drv);
            
            #(tx_tr_drv.data_delay*CLK_CYCLE);
    
             if(tx_empty) 
                tx_data = tx_tr_drv.data;
             else begin
                wait(tx_empty);
                tx_data = tx_tr_drv.data;
             end
    
            @(posedge clk) tx_wren = 1;
            @(posedge clk) tx_wren = 0;
    
            wait(tx_complete);
            
            num_trans_tx++;
        
        end
    
    endtask
    
    task automatic run_rx();
    
        forever begin
        
            gen2drv_rx.get(rx_tr_drv);
            
            #(rx_tr_drv.send_delay*CLK_CYCLE);
    
            wait(baud_pulse);
            rxc = 0;
    
            for(int i=0; i<WORD; i++) begin
                #(UART_CYCLE);
                rxc = rx_tr_drv.data[i];
            end
            
            #(UART_CYCLE) rxc = rx_tr_drv.stop_bit;
            
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
    logic [7:0] rx_reversed_data;
    
    tx_trans_t tx_tr_scb;
    rx_trans_t rx_tr_scb;

    mailbox #(tx_trans_t ) gen2scb_tx;
    mailbox #(rx_trans_t ) gen2scb_rx;
    mailbox #(logic [7:0]) mnt2scb_tx;
    mailbox #(logic [7:0]) mnt2scb_rx;
    
    function new(mailbox #(tx_trans_t ) gen2scb_tx,
                 mailbox #(rx_trans_t ) gen2scb_rx,
                 mailbox #(logic [7:0]) mnt2scb_tx,
                 mailbox #(logic [7:0]) mnt2scb_rx);
    
        this.gen2scb_tx = gen2scb_tx;
        this.gen2scb_rx = gen2scb_rx;
        this.mnt2scb_tx = mnt2scb_tx;
        this.mnt2scb_rx = mnt2scb_rx;
    
    endfunction
    
    task automatic check_tx();
    
        forever begin
        
            gen2scb_tx.get(tx_tr_scb);
            mnt2scb_tx.get(tx_data_shift);
            if(tx_tr_scb.data !== tx_data_shift) begin
            
                $display("INFO: Error: tx_data doesn`t match, trans ID = %d", tx_tr_scb.id);
                $display("Sent data = %h, Received = %h",tx_tr_scb.data,tx_data_shift);
                
            end
            
            num_trans_tx++;
        
        end
        
    endtask
    
    task automatic check_rx();
    
        forever begin
    
            gen2scb_rx.get(rx_tr_scb);
            mnt2scb_rx.get(rx_data_rcvd);
            
            for(int i=0; i<WORD; i++) begin
                rx_reversed_data[i] = rx_data_rcvd[7-i];
            end
            
            if(rx_tr_scb.data !== rx_reversed_data) begin
            
                $display("INFO: Error: rx_data doesn`t match, trans ID = %d", rx_tr_scb.id);
                $display("Sent data = %h, Received = %h",rx_tr_scb.data,rx_reversed_data);
            
            end
            
            num_trans_rx++;
        
        end
    
    endtask
    
    task automatic run();
        
        fork
            
            check_tx();
            check_rx();
        
        join
    
    endtask

endclass
//===================================================================================
// Class Monitor

class Monitor;

    int         num_trans_tx;
    int         num_trans_rx;
    

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
                mnt2scb_rx.put(rx_data);
            end
            overrun_flag = 0;
        end
        
        num_trans_rx++;
    
    endtask
    
    task automatic rx_rden_send();
        begin
            @(posedge rx_complete) begin
    
//                if( > UART_CYCLE)
//                    overrun_flag = 1;
    
                #(rx_rden_delay*CLK_CYCLE);
    
                if(overrun) begin
                    reset_err();
                end
    
                @(posedge clk) rx_rden = 1;
                @(posedge clk) rx_rden = 0;
            end
        end
        
    endtask
    
    task automatic receive_tx();
        begin
            wait(!txc);
            #(UART_CYCLE+UART_CYCLE/2);
    
            for(int i=0; i<WORD; i++) begin
                tx_data_shift = {tx_data_shift[6:0],txc};
                #UART_CYCLE;
            end
    
            mnt2scb_tx.put(tx_data_shift);
            
            num_trans_tx++;
    
        end
    endtask
    
    task automatic reset_err();
    
        @(posedge clk) rst_err = 1;
        @(posedge clk) rst_err = 0;
        
    endtask
    
    task automatic run();
    
        fork
        
            receive_rx();
            rx_rden_send();
            
        join        
    endtask

endclass 
//===================================================================================
// Class Environment

class Environment;

    Generator   gen;
    Driver      drv;
    Monitor     mnt;
    Scoreboard  scb;
    
    mailbox gen2drv_tx;
    mailbox gen2drv_rx;
    mailbox gen2scb_tx;
    mailbox gen2scb_rx;
    mailbox mnt2scb_tx;
    mailbox mnt2scb_rx;
    
    function new();
    
        gen2drv_tx = new();
        gen2drv_rx = new();
        gen2scb_tx = new();
        gen2scb_rx = new();
        mnt2scb_tx = new();
        mnt2scb_rx = new();
        
        gen = new(gen2drv_tx,gen2drv_rx,gen2scb_tx,gen2scb_rx);
        drv = new(gen2drv_tx,gen2drv_rx);
        mnt = new(mnt2scb_tx,mnt2scb_rx);
        scb = new(gen2scb_tx,gen2scb_rx,mnt2scb_tx,mnt2scb_rx);
        
    endfunction;
    
    task automatic run();
        
        fork
        
            gen.run();
            drv.run();
            mnt.run();
            scb.run();
            
        join_any
        
        run_wait_end();
        
        $finish;
        
    endtask
    
    task automatic run_wait_end();
    
        fork
            
            wait(scb.num_trans_tx == NUMBER_OF_TESTS);
            wait(mnt.num_trans_tx == NUMBER_OF_TESTS);
            wait(scb.num_trans_rx == NUMBER_OF_TESTS);
            wait(mnt.num_trans_rx == NUMBER_OF_TESTS);
        
        join
        
    endtask

endclass
    
//===================================================================================

Environment env;

//--------------------------------------------
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
// Initialization

task automatic init();
    
    rxc     = 1;
    tx_data = 8'h00;
    tx_wren = 0;
    rx_rden = 0;
    rst_err = 0;
    
endtask
//--------------------------------------------
// Test

initial begin

    env = new();
    
    init();
    
    env.run();

end

//===================================================================================
uart dut0
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

