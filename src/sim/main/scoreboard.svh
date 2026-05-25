//===================================================================================
//
//      Class Scoreboard
//
class Scoreboard;

    int err          =  0;
    int num_trn_rx   =  0;
    int num_trn_tx   =  0;
    int percent      =  0;
    int last_percent = -1;

    data_t rx_reversed_data;
    data_t tx_data_shift;
    
    rx_trn_t  rx_tr_scb;
    mnt_rcvd_t mnt_data;
    tx_pak_t tx_drv_scb;
    tx_pak_t tx_mnt_scb;
    
    mailbox #( rx_trn_t ) drv2scb_rx;
    mailbox #(mnt_rcvd_t) mnt2scb_rx;
    mailbox #( tx_pak_t ) drv2scb_tx;
    mailbox #( tx_pak_t ) mnt2scb_tx;
    
    covergroup rx_data_cg;
        rx_data : coverpoint mnt_data.data
        {
            bins dat_0   = {    0    };
            bins dat_63  = {[  1:63 ]};
            bins dat_127 = {[ 64:127]};
            bins dat_254 = {[128:254]};
            bins dat_255 = {   255   };
        }
        rx_err_fr : coverpoint mnt_data.frame_error
        {
            bins err_0 = {0};
            bins err_1 = {1};
        }
        rx_err_ov : coverpoint mnt_data.overrun
        {
            bins err_0 = {0};
            bins err_1 = {1};
        }

    endgroup

    covergroup rx_del_cg;
        rx_rden_delay : coverpoint rx_tr_scb.rden_delay
        {
            bins del_0  = {      0      };
            bins del_10 = {[    1:10000]};
            bins del_20 = {[10001:20000]};
            bins del_30 = {[20000:30000]};
        }

        rx_send_delay : coverpoint rx_tr_scb.send_delay
        {
            bins del_0  = {      0      };
            bins del_10 = {[    1:10000]};
            bins del_20 = {[10001:20000]};
            bins del_30 = {[20000:30000]};
        }

    endgroup
    
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
    
    function new(mailbox #( rx_trn_t ) drv2scb_rx,
                 mailbox #(mnt_rcvd_t) mnt2scb_rx,
                 mailbox #( tx_pak_t ) drv2scb_tx,
                 mailbox #( tx_pak_t ) mnt2scb_tx);
    
        this.drv2scb_rx = drv2scb_rx;
        this.mnt2scb_rx = mnt2scb_rx;
        this.drv2scb_tx = drv2scb_tx;
        this.mnt2scb_tx = mnt2scb_tx;
        rx_data_cg      = new();
        rx_del_cg       = new();
        tx_data_cg      = new();
    
    endfunction
    
    function void meas_percent;
        percent = (((this.num_trn_rx+this.num_trn_tx)*100) / total_tests);

        if (percent != last_percent && (percent % 10 == 0 || percent == 100)) begin
            $display("INFO: Scoreboard completed RX %0d%%", percent);
            last_percent = percent;
        end
    endfunction
    
    function void check_rx_data;
        if(!rx_tr_scb.drop_rx) begin

            if(rx_tr_scb.data !== rx_reversed_data) begin

                $display("INFO (ERROR) (rx) : data dismatch, ID = %d",num_trn_rx);
                $display("      Sent data = %h, Received = %h",rx_tr_scb.data,rx_reversed_data);
                err++;
            end
        end
    endfunction
    
    function void check_frame_error;
        if(!rx_tr_scb.drop_rx) begin
            if(rx_tr_scb.stop_bit == mnt_data.frame_error) begin
                $display("INFO (ERROR) (rx) : frame error, ID = %d",num_trn_rx);
                $display("      Sent data = %h, Received = %h",rx_tr_scb.data,rx_reversed_data);
                err++;
            end
        end
    endfunction

    task automatic check_rx();
    
        forever begin

            drv2scb_rx.get(rx_tr_scb);
            mnt2scb_rx.get(mnt_data );

            for(int i=0; i<WORD; i++) begin
                rx_reversed_data[i] = mnt_data.data[WORD-1-i];
            end

            check_rx_data;
            check_frame_error;
            
            num_trn_rx++;

            meas_percent;

            rx_data_cg.sample();
            rx_del_cg.sample();

        end
    
    endtask
    
    task automatic check_tx();

        forever begin

            drv2scb_tx.get(tx_drv_scb);
            mnt2scb_tx.get(tx_mnt_scb);
            if(tx_drv_scb.data !== tx_mnt_scb.data) begin

                $display("INFO (ERROR) (tx) : bad frame, ID : drv = %d, mnt = %d",tx_drv_scb.id, tx_mnt_scb.id);
                $display("      Sent data = %h, Received = %h",tx_drv_scb.data, tx_mnt_scb.data);
                err++;

            end

            num_trn_tx++;

            tx_data_cg.sample();

        end

    endtask
    
    task automatic run();
        
        fork
            
            check_rx();
            check_tx();
        
        join
    
    endtask
//===================================================================================
endclass : Scoreboard
//===================================================================================
