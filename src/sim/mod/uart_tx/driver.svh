//===================================================================================
//
//      Class Driver
//
class Driver;

    virtual uart_if vif;

    semaphore sem_scb2drv;

    int num_trn_tx;
    
    tx_trn_t tx_tr_drv;

    mailbox #(tx_trn_t) gen2drv_tx;
    
    function new(mailbox #(tx_trn_t) gen2drv_tx ,
                 virtual             uart_if vif,
                 semaphore           sem_scb2drv);
    
        this.gen2drv_tx  = gen2drv_tx;
        this.vif         = vif;
        this.sem_scb2drv = sem_scb2drv;
    
    endfunction 
    
    task automatic run_tx();
    
        forever begin
        
            gen2drv_tx.get(tx_tr_drv);
            
            #(tx_tr_drv.data_delay*CLK_CYCLE);
    
             if(vif.tx_empty)
                vif.tx_data = tx_tr_drv.data;
             else begin
                wait(vif.tx_empty);
                vif.tx_data = tx_tr_drv.data;
             end
    
            @(posedge vif.clk) vif.tx_wren = 1;
            @(posedge vif.clk) vif.tx_wren = 0;

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
