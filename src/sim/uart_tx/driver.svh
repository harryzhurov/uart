//===================================================================================
//
//      Class Driver
//
class Driver;

    virtual uart_if uif;

    int num_trn_tx;
    
    tx_trn_t tx_tr_drv;

    mailbox #(tx_trn_t) gen2drv_tx;
    
    function new(mailbox #(tx_trn_t) gen2drv_tx,
                 virtual uart_if uif           );
    
        this.gen2drv_tx = gen2drv_tx;
        this.uif        = uif;
    
    endfunction 
    
    task automatic run_tx();
    
        forever begin
        
            gen2drv_tx.get(tx_tr_drv);
            
            #(tx_tr_drv.data_delay*CLK_CYCLE);
    
             if(uif.tx_empty)
                uif.tx_data = tx_tr_drv.data;
             else begin
                wait(uif.tx_empty);
                uif.tx_data = tx_tr_drv.data;
             end
    
            @(posedge uif.clk) uif.tx_wren = 1;
            @(posedge uif.clk) uif.tx_wren = 0;

            #20ns;
            
            num_trn_tx++;
        
        end
    
    endtask
    
    task automatic run();
    
        fork
        
            run_tx();
        
        join
    
    endtask

endclass : Driver
//===================================================================================
