//===================================================================================
//
//      Class Scoreboard
//
class Scoreboard;

    int err        = 0;
    int num_trn_rx = 0;
    int num_trn_tx = 0;

    data_t rx_reversed_data;
    data_t tx_data_shift;
    
    rx_trn_t   rx_tr_scb;
    mnt_rcvd_t mnt_data;
    tx_trn_t   tx_tr_scb;
    
    mailbox #( rx_trn_t ) gen2scb_rx;
    mailbox #(mnt_rcvd_t) mnt2scb_rx;
    mailbox #( tx_trn_t ) gen2scb_tx;
    mailbox #(  data_t  ) mnt2scb_tx;
    
    function new(mailbox #( rx_trn_t ) gen2scb_rx,
                 mailbox #(mnt_rcvd_t) mnt2scb_rx,
                 mailbox #( tx_trn_t ) gen2scb_tx,
                 mailbox #(  data_t  ) mnt2scb_tx);
    
        this.gen2scb_rx = gen2scb_rx;
        this.mnt2scb_rx = mnt2scb_rx;
        this.gen2scb_tx = gen2scb_tx;
        this.mnt2scb_tx = mnt2scb_tx;
    
    endfunction
    
    task automatic check_rx();
    
        forever begin

            //$display("rx_check start, num = %d, time [%t]",num_trn_rx, $realtime);
    
            gen2scb_rx.get(rx_tr_scb);
            mnt2scb_rx.get(mnt_data );
            
            for(int i=0; i<WORD; i++) begin
                rx_reversed_data[i] = mnt_data.data[WORD-1-i];
            end
            
            if(rx_tr_scb.data !== rx_reversed_data) begin
            
                //$display("INFO: Error: rx_data doesn`t match, transaction ID = %d", rx_tr_scb.id);
                //$display("      Sent data = %h, Received = %h",rx_tr_scb.data,rx_reversed_data);
                $display("INFO (ERROR) (rx) : bad frame = %d, time = [%t]",num_trn_rx, $realtime);
                err++;
            
            end
            
            if(rx_tr_scb.stop_bit == mnt_data.frame_error) begin
                $display("INFO (ERROR) (rx) : frame error, time = [%t]", $realtime);
                err++;
            end
            
            num_trn_rx++;
            
            //$display("rx_check done, num = %d, time [%t]",num_trn_rx, $realtime);
        
        end
    
    endtask
    
    task automatic check_tx();

        forever begin

            gen2scb_tx.get(tx_tr_scb);
            mnt2scb_tx.get(tx_data_shift);
            if(tx_tr_scb.data !== tx_data_shift) begin

                /*$display("INFO: Error: tx_data doesn`t match, transaction ID = %d", tx_tr_scb.id);
                $display("      Sent data = %h, Received = %h",tx_tr_scb.data,tx_data_shift);*/
                $display("INFO (ERROR) (tx) : bad frame = %d, time = [%t]",num_trn_tx, $realtime);
                err++;

            end

            num_trn_tx++;

        end

    endtask
    
    task automatic run();
        
        fork
            
            check_rx();
            check_tx();
        
        join
    
    endtask

endclass : Scoreboard
//===================================================================================
