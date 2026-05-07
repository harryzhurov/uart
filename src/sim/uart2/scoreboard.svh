//===================================================================================
//
//      Class Scoreboard
//
class Scoreboard;

    int err        = 0;
    int num_trn_tx = 0;
    int num_trn_rx = 0;
    
    logic [WORD-1:0] tx_data_shift;
    logic [WORD-1:0] rx_data_rcvd;
    logic [WORD-1:0] rx_reversed_data;
    
    tx_trn_t tx_tr_scb;
    rx_trn_t rx_tr_scb;

    mailbox #(    tx_trn_t    ) gen2scb_tx;
    mailbox #(    rx_trn_t    ) gen2scb_rx;
    mailbox #(logic [WORD-1:0]) mnt2scb_tx;
    mailbox #(logic [WORD-1:0]) mnt2scb_rx;
    
    virtual uart_if uif;
    
    function new(mailbox #(    tx_trn_t    ) gen2scb_tx,
                 mailbox #(    rx_trn_t    ) gen2scb_rx,
                 mailbox #(logic [WORD-1:0]) mnt2scb_tx,
                 mailbox #(logic [WORD-1:0]) mnt2scb_rx,
                 virtual uart_if uif);
    
        this.gen2scb_tx = gen2scb_tx;
        this.gen2scb_rx = gen2scb_rx;
        this.mnt2scb_tx = mnt2scb_tx;
        this.mnt2scb_rx = mnt2scb_rx;
        this.uif        = uif;
    
    endfunction
    
    task automatic check_tx();
    
        forever begin
        
            gen2scb_tx.get(tx_tr_scb);
            mnt2scb_tx.get(tx_data_shift);
            if(tx_tr_scb.data !== tx_data_shift) begin
            
                /*$display("INFO: Error: tx_data doesn`t match, transaction ID = %d", tx_tr_scb.id);
                $display("      Sent data = %h, Received = %h",tx_tr_scb.data,tx_data_shift);*/
                err++;
                
            end
            
            num_trn_tx++;
        
        end
        
    endtask
    
    task automatic check_rx();
    
        forever begin

            //$display("rx_check start, num = %d, time [%t]",num_trn_rx, $realtime);
    
            gen2scb_rx.get(rx_tr_scb);
            mnt2scb_rx.get(rx_data_rcvd);
            
            for(int i=0; i<WORD; i++) begin
                rx_reversed_data[i] = rx_data_rcvd[WORD-1-i];
            end
            
            if(rx_tr_scb.data !== rx_reversed_data) begin
            
                /*$display("INFO: Error: rx_data doesn`t match, transaction ID = %d", rx_tr_scb.id);
                $display("      Sent data = %h, Received = %h",rx_tr_scb.data,rx_reversed_data);*/
                err++;
            
            end
            
            num_trn_rx++;
            
            //$display("rx_check done, num = %d, time [%t]",num_trn_rx, $realtime);
        
        end
    
    endtask
    
    task automatic run();
        
        fork
            
            check_tx();
            check_rx();
        
        join
    
    endtask

endclass : Scoreboard
//===================================================================================
