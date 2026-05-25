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
    
    tx_pak_t tx_pak_mnt;

    mailbox #(tx_pak_t) mnt2scb_tx;
    
    function new(mailbox #(tx_pak_t) mnt2scb_tx ,
                 virtual             uart_if vif);
    
        this.mnt2scb_tx = mnt2scb_tx;
        this.vif        = vif;
    
    endfunction
    
    function void meas_percent;
        percent = (this.num_trn_tx*100) / (trn_cfg_pkg::num_trn_tx);

        if (percent != last_percent && (percent % 10 == 0 || percent == 100)) begin
            $display("INFO: Monitor completed %0d%%", percent);
            last_percent = percent;
        end
    endfunction
    
    task automatic receive_tx();

        forever begin

            @(negedge vif.txc);
            
            #(UART_CYCLE+UART_CYCLE/2);
    
            for(int i=0; i<WORD; i++) begin
                tx_data_mnt = {tx_data_mnt[WORD-2:0],vif.txc};
                #UART_CYCLE;
            end
            
            tx_pak_mnt.data = tx_data_mnt;
            tx_pak_mnt.id   = num_trn_tx;
            mnt2scb_tx.put(tx_pak_mnt);
            
            num_trn_tx++;

            meas_percent;
    
        end
    endtask
    
    task automatic run();

        receive_tx();
            
    endtask

endclass : Monitor
//===================================================================================
