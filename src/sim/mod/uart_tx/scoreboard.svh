//===================================================================================
//
//      Class Scoreboard
//
class Scoreboard;

    int err          = 0;
    int num_trn_tx   = 0;
    int percent      =  0;
    int last_percent = -1;
    
    tx_pak_t tx_drv_scb;
    tx_pak_t tx_mnt_scb;

    mailbox #(tx_pak_t) drv2scb_tx;
    mailbox #(tx_pak_t) mnt2scb_tx;
    
    covergroup tx_data_cg;
        tx_data : coverpoint tx_mnt_scb.data
        {
            bins dat_0   = {    0    };
            bins dat_63  = {[  1:63 ]};
            bins dat_127 = {[ 64:127]};
            bins dat_254 = {[128:254]};
            bins dat_255 = {   255   };
        }

        option.per_instance = 1;

    endgroup
    
    function new(mailbox #(tx_pak_t) drv2scb_tx,
                 mailbox #(tx_pak_t) mnt2scb_tx);
    
        this.drv2scb_tx  = drv2scb_tx ;
        this.mnt2scb_tx  = mnt2scb_tx ;
        tx_data_cg       = new();
    
    endfunction
    
    function void meas_percent;
        percent = (this.num_trn_tx*100) / (trn_cfg_pkg::num_trn_tx);

        if (percent != last_percent && (percent % 10 == 0 || percent == 100)) begin
            $display("INFO: Scoreboard completed %0d%%", percent);
            last_percent = percent;
        end
    endfunction
    
    task automatic check_tx();
    
        forever begin
        
            drv2scb_tx.get(tx_drv_scb);
            mnt2scb_tx.get(tx_mnt_scb);
            if(tx_drv_scb.data !== tx_mnt_scb.data) begin
            
                $display("INFO (ERROR) (tx) : bad frame, id : drv = %d, mnt = %d",tx_drv_scb.id, tx_mnt_scb.id);
                $display("      Sent data = %h, Received = %h",tx_drv_scb.data, tx_mnt_scb.data);
                err++;
                
            end
            
            num_trn_tx++;
            tx_data_cg.sample();
            meas_percent;
        
        end
        
    endtask
    
    
    task automatic run();
            
         check_tx();
    
    endtask

endclass : Scoreboard
//===================================================================================
