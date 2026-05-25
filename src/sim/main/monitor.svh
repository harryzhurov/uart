//===================================================================================
//
//      Class Monitor
//
class Monitor;

    virtual   uart_if vif;

    int    num_trn_rx;
    int    num_trn_tx;
    int    percent      =  0;
    int    last_percent = -1;
    data_t tx_data_mnt;

    rx_trn_t   rx_tr_mnt;
    mnt_rcvd_t mnt_data;
    tx_pak_t   tx_pak_mnt;

    mailbox #(mnt_rcvd_t) mnt2scb_rx;
    mailbox #( tx_pak_t ) mnt2scb_tx;
    
    function new(mailbox #(mnt_rcvd_t) mnt2scb_rx ,
                 mailbox #( tx_pak_t ) mnt2scb_tx ,
                 virtual               uart_if vif);
    
        this.mnt2scb_rx  = mnt2scb_rx;
        this.mnt2scb_tx  = mnt2scb_tx;
        this.vif         = vif;

    endfunction
    
    function void meas_percent;
        percent = ((this.num_trn_rx+this.num_trn_tx)*100) / (total_tests);

        if (percent != last_percent && (percent % 10 == 0 || percent == 100)) begin
            $display("INFO: Monitor completed %0d%%", percent);
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

                meas_percent;

                #UART_CYCLE;

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

        end
    endtask
    
    task automatic run();
    
        @(negedge vif.init_en);
        
        fork
        
            receive_rx();
            receive_tx();
            
        join        
        
    endtask
//===================================================================================
endclass : Monitor
//===================================================================================
