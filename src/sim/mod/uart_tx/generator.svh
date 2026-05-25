//===================================================================================
//
//      Class Generator
//
class Generator;

    Tx_transaction tx_trn;

    tx_trn_t tx_tr_gen;

    mailbox #(tx_trn_t) gen2drv_tx;
    
    function new(mailbox #( tx_trn_t  ) gen2drv_tx);
    
        this.gen2drv_tx = gen2drv_tx;
        
    endfunction
    
    task automatic run();
    
        repeat (num_trn_tx) begin
        
            tx_trn = new();
            tx_trn.randomize();
            
            if(!tx_trn.randomize()) $display("INFO: ERROR: tx_transaction_randomization failed!");
            
            tx_tr_gen.data        = tx_trn.data;
            tx_tr_gen.data_delay  = tx_trn.data_delay;
            tx_tr_gen.id          = tx_trn.id;
            
            gen2drv_tx.put(tx_tr_gen);
            
        end
    
    endtask
    
    
endclass : Generator
