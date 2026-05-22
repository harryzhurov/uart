//===================================================================================
//
//      Class Monitor
//
class Monitor;

    virtual uart_if vif;

    int    num_trn_tx;
    int    percent      =  0;
    int    last_percent = -1;
    data_t tx_data_mnt;

    mailbox #(data_t) mnt2scb_tx;
    
    covergroup tx_data_cg @(posedge vif.clk);
        tx_data : coverpoint tx_data_mnt
        {
            bins dat_0   = {    0    };
            bins dat_63  = {[  1:63 ]};
            bins dat_127 = {[ 64:127]};
            bins dat_254 = {[128:254]};
            bins dat_255 = {   255   };
        }

        option.per_instance = 1;

    endgroup
    
    function new(mailbox #(data_t) mnt2scb_tx ,
                 virtual           uart_if vif);
    
        this.mnt2scb_tx = mnt2scb_tx;
        this.vif        = vif;
        tx_data_cg      = new();
    
    endfunction
    
    function void meas_percent;
        percent = (this.num_trn_tx*100) / (trn_cfg_pkg::num_trn_tx);

        if (percent != last_percent && (percent % 10 == 0 || percent == 100)) begin
            $display("INFO: Monitor completed %0d%% (%0d/%0d)", percent, this.num_trn_tx, trn_cfg_pkg::num_trn_tx);
            last_percent = percent;
        end
    endfunction
    
    task automatic receive_tx();
        forever begin
            wait(!vif.txc);
            #(UART_CYCLE+UART_CYCLE/2);
    
            for(int i=0; i<WORD; i++) begin
                tx_data_mnt = {tx_data_mnt[WORD-2:0],vif.txc};
                #UART_CYCLE;
            end

            tx_data_cg.sample();
            mnt2scb_tx.put(tx_data_mnt);
            
            num_trn_tx++;
            meas_percent;
    
        end
    endtask
    
    task automatic run();
    
        fork
        
            receive_tx();
            
        join        
        
    endtask

endclass : Monitor
//===================================================================================
