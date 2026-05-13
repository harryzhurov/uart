//===================================================================================
//
//      Class Scoreboard
//
class Scoreboard;

    int err        = 0;
    int num_trn_tx = 0;
    
    data_t tx_data_shift;
    
    tx_trn_t tx_tr_scb;

    mailbox #(tx_trn_t) gen2scb_tx;
    mailbox #( data_t ) mnt2scb_tx;
    
    virtual uart_if uif;
    
    function new(mailbox #(tx_trn_t) gen2scb_tx,
                 mailbox #( data_t ) mnt2scb_tx,
                 virtual uart_if uif);
    
        this.gen2scb_tx = gen2scb_tx;
        this.mnt2scb_tx = mnt2scb_tx;
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
    
    
    task automatic run();
        
        fork
            
            check_tx();
        
        join
    
    endtask

endclass : Scoreboard
//===================================================================================
