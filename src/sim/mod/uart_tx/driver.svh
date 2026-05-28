//===================================================================================
//
//      Class Driver
//
class Driver;

    virtual uart_if vif;

    int num_trn_tx   =  0;
    int percent      =  0;
    int last_percent = -1;
    int id;
    
    tx_trn_t tx_tr_drv;
    tx_pak_t tx_pak_drv;

    mailbox #(tx_trn_t) gen2drv_tx;
    mailbox #(tx_pak_t) drv2scb_tx;
    
    function new(mailbox #(tx_trn_t) gen2drv_tx ,
                 mailbox #(tx_pak_t) drv2scb_tx ,
                 virtual             uart_if vif);
    
        this.gen2drv_tx  = gen2drv_tx;
        this.drv2scb_tx  = drv2scb_tx;
        this.vif         = vif;
    
    endfunction
    
    function void meas_percent;
        percent = (this.num_trn_tx*100) / (trn_cfg_pkg::num_trn_tx);

        if (percent != last_percent && (percent % 10 == 0 || percent == 100)) begin
            $display("INFO: Driver completed %0d%%", percent);
            last_percent = percent;
        end
    endfunction
    
    task automatic run_tx();
    
        repeat (trn_cfg_pkg::num_trn_tx) begin
        
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
            
            tx_pak_drv.data = tx_tr_drv.data;
            tx_pak_drv.id   = num_trn_tx;
            drv2scb_tx.put(tx_pak_drv);

            #20ns;
            
            num_trn_tx++;
            
            meas_percent;
        
        end
    
    endtask
    
    task automatic run();

        
        run_tx();

    
    endtask

endclass : Driver
//===================================================================================
