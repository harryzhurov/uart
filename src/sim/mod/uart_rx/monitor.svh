//===================================================================================
//
//      Class Monitor
//
class Monitor;

    virtual uart_if vif;

    int num_trn_rx   =  0;
    int percent      =  0;
    int last_percent = -1;

    rx_trn_t   rx_tr_mnt;
    mnt_rcvd_t mnt_data;

    mailbox #(mnt_rcvd_t) mnt2scb_rx;
    
    function new(mailbox #(mnt_rcvd_t) mnt2scb_rx ,
                 virtual               uart_if vif);
    
        this.mnt2scb_rx = mnt2scb_rx;
        this.vif        = vif;
    
    endfunction
    
    function void meas_percent;
        percent = (this.num_trn_rx*100) / (trn_cfg_pkg::num_trn_rx);

        if (percent != last_percent && (percent % 10 == 0 || percent == 100)) begin
            $display("INFO: Monitor completed %0d%% (%0d/%0d)", percent, this.num_trn_rx, trn_cfg_pkg::num_trn_rx);
            last_percent = percent;
        end
    endfunction
    
    task automatic receive_rx();

        forever begin

            fork
            begin
                @(posedge vif.rx_complete, posedge vif.overrun);

                mnt_data.data        = vif.rx_data;
                mnt_data.frame_error = vif.frame_error;
                mnt_data.overrun     = vif.overrun;

                mnt2scb_rx.put(mnt_data);

                num_trn_rx++;
                
                $display("MONITOR : num_trn_rx = %d", num_trn_rx);

                meas_percent;

            end
            begin
                @(posedge vif.rx_complete)
                -> vif.rx_rden_en;
            end
            begin
                @(posedge vif.frame_error, posedge vif.overrun);
                -> vif.reset_err;
            end
            join_any
        end

    endtask
    
    task automatic run();
    
        fork

            @(negedge vif.init_en);
        
            receive_rx();
            
        join        
        
    endtask

endclass : Monitor
//===================================================================================
