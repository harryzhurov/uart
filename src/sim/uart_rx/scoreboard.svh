//===================================================================================
//
//      Class Scoreboard
//
class Scoreboard;

    int err        = 0;
    int num_trn_rx = 0;

    data_t rx_reversed_data;
    
    rx_trn_t   rx_tr_scb;
    logic [WORD-1:0] rx_data_rcvd;
    logic [WORD-1:0] rx_reversed_data;
    mnt_rcvd_t mnt_data;
    
    mailbox #( rx_trn_t ) gen2scb_rx;
    mailbox #(mnt_rcvd_t) mnt2scb_rx;
    
    virtual uart_if uif;
    
    function new(mailbox #( rx_trn_t ) gen2scb_rx,
                 mailbox #(mnt_rcvd_t) mnt2scb_rx,
                 virtual uart_if uif);
    
        this.gen2scb_rx = gen2scb_rx;
        this.mnt2scb_rx = mnt2scb_rx;
        this.uif        = uif;
    
    endfunction
    
    
    task automatic check_rx();
    
        forever begin

            //$display("rx_check start, num = %d, time [%t]",num_trn_rx, $realtime);
    
            gen2scb_rx.get(rx_tr_scb);
            mnt2scb_rx.get(mnt_data );
            
            for(int i=0; i<WORD; i++) begin
                rx_reversed_data[i] = mnt_data.data[WORD-1-i];
            end
            
            if(rx_tr_scb.data !== rx_reversed_data) begin
            
                //$display("INFO: Error: rx_data doesn`t match, transaction ID = %d", rx_tr_scb.id);
                //$display("      Sent data = %h, Received = %h",rx_tr_scb.data,rx_reversed_data);
                err++;
            
            end
            
            num_trn_rx++;
            
            //$display("rx_check done, num = %d, time [%t]",num_trn_rx, $realtime);
        
        end
    
    endtask
    
    task automatic run();
        
        fork
            
            check_rx();
        
        join
    
    endtask

endclass : Scoreboard
//===================================================================================
