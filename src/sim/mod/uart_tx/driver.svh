//===================================================================================
//
//      Class Driver
//
class Driver;

    virtual uart_if vif;

    semaphore sem_scb2drv;

    int num_trn_tx;
    int percent      =  0;
    int last_percent = -1;
    
    tx_trn_t tx_tr_drv;

    mailbox #(tx_trn_t) gen2drv_tx;
    
    function new(mailbox #(tx_trn_t) gen2drv_tx ,
                 virtual             uart_if vif,
                 semaphore           sem_scb2drv);
    
        this.gen2drv_tx  = gen2drv_tx;
        this.vif         = vif;
        this.sem_scb2drv = sem_scb2drv;
    
    endfunction
    
    function void meas_percent;
        percent = (this.num_trn_tx*100) / (trn_cfg_pkg::num_trn_tx);

        if (percent != last_percent && (percent % 10 == 0 || percent == 100)) begin
            $display("INFO: Driver completed %0d%% (%0d/%0d)", percent, this.num_trn_tx, trn_cfg_pkg::num_trn_tx);
            last_percent = percent;
        end
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
            
            meas_percent;
        
        end
    
    endtask
    
    task automatic run();
    
        fork
        
            run_tx();
        
        join
    
    endtask

endclass : Driver
//===================================================================================
