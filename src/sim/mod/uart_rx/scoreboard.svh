//===================================================================================
//
//      Class Scoreboard
//
class Scoreboard;

    int err        = 0;
    int num_trn_rx = 0;

    data_t rx_reversed_data;
    
    rx_trn_t   rx_tr_scb;
    mnt_rcvd_t mnt_data;
    
    semaphore sem_scb2drv;
    
    mailbox #(mnt_rcvd_t) mnt2scb_rx;
    
    virtual uart_if uif;
    
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
    
                 mailbox #(mnt_rcvd_t) mnt2scb_rx ,
                 semaphore             sem_scb2drv);
    
        this.mnt2scb_rx  = mnt2scb_rx;
        this.sem_scb2drv = sem_scb2drv;
        rx_data_cg       = new();
        rx_del_cg        = new();
    
    endfunction
    
    
    function check_rx_data;
        if(rx_tr_scb.data !== rx_reversed_data) begin

            $display("INFO (ERROR) (rx) : bad frame = %d, time = [%t]",num_trn_rx, $realtime);
            $display("      Sent data = %h, Received = %h",rx_tr_scb.data,rx_reversed_data);
            err++;
            return 1;
        end

        return 0;

    endfunction

    function check_frame_error;
        if(rx_tr_scb.stop_bit == mnt_data.frame_error) begin
            $display("INFO (ERROR) (rx) : frame error, time = [%t]", $realtime);
            err++;
            return 1;
        end
        return 0;
    endfunction

    task automatic check_rx();

        forever begin

            gen2scb_rx.get(rx_tr_scb);
            mnt2scb_rx.get(mnt_data );

            for(int i=0; i<WORD; i++) begin
                rx_reversed_data[i] = mnt_data.data[WORD-1-i];
            end

            if(!rx_tr_scb.drop_rx) begin

                if(check_rx_data & check_frame_error)
                    sem_scb2drv.put(1);

            end
            num_trn_rx++;
            rx_data_cg.sample();
            rx_del_cg.sample();

        end

    endtask
    
    task automatic run();
        
        fork
            
            check_rx();
        
        join
    
    endtask

endclass : Scoreboard
//===================================================================================
