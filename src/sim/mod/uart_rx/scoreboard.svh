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
    
    mailbox #( rx_trn_t ) gen2scb_rx;
    mailbox #(mnt_rcvd_t) mnt2scb_rx;
    
    virtual uart_if uif;
    
    function new(mailbox #( rx_trn_t ) gen2scb_rx ,
                 mailbox #(mnt_rcvd_t) mnt2scb_rx ,
                 semaphore             sem_scb2drv);
    
        this.gen2scb_rx  = gen2scb_rx;
        this.mnt2scb_rx  = mnt2scb_rx;
        this.sem_scb2drv = sem_scb2drv;
    
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

        end

    endtask
    
    task automatic run();
        
        fork
            
            check_rx();
        
        join
    
    endtask

endclass : Scoreboard
//===================================================================================
