//===================================================================================
//
//      Class Monitor
//
class Monitor;

    virtual uart_if vif;

    int    num_trn_rx;
    int    num_trn_tx;
    data_t tx_data_mnt;

    mnt_dels_t rx_mnt_dels;
    mnt_rcvd_t mnt_data;

    mailbox #(mnt_rcvd_t) mnt2scb_rx;
    mailbox #(mnt_dels_t) gen2mnt_rx;
    mailbox #(  data_t  ) mnt2scb_tx;
    
    function new(mailbox #(mnt_rcvd_t) mnt2scb_rx,
                 mailbox #(mnt_dels_t) gen2mnt_rx,
                 mailbox #(  data_t  ) mnt2scb_tx,
                 virtual uart_if vif             );
    
        this.mnt2scb_rx = mnt2scb_rx;
        this.gen2mnt_rx = gen2mnt_rx;
        this.mnt2scb_tx = mnt2scb_tx;
        this.vif        = vif;
    
    endfunction 
    
    task automatic receive_rx();
    
        forever begin

            @(vif.rx_data, posedge vif.rx_complete, posedge vif.overrun) begin
                mnt_data.data        = vif.rx_data;
                mnt_data.frame_error = vif.frame_error;
                mnt_data.overrun     = vif.overrun;
                mnt2scb_rx.put(mnt_data);
                if(vif.overrun | vif.frame_error)
                    reset_err();
            end
            
            num_trn_rx++;
            
            //$display("monitor (rx) : data received = %h", vif.rx_data);
            //$display("monitor (rx) : Num transaction = %d", num_trn_rx);

        end
    
    endtask
    
    task automatic receive_tx();

        forever begin

            wait(!vif.txc);
            #(UART_CYCLE+UART_CYCLE/2);

            for(int i=0; i<WORD; i++) begin
                tx_data_mnt = {tx_data_mnt[WORD-2:0],vif.txc};
                #UART_CYCLE;
            end

            mnt2scb_tx.put(tx_data_mnt);

            num_trn_tx++;
            
            //$display("monitor (tx) : data received = %h", tx_data_mnt);
            //$display("monitor (tx) : Num transaction = %d", num_trn_tx);

        end
    endtask
    
    task automatic rx_rden_send();

        forever begin

            gen2mnt_rx.get(rx_mnt_dels);
            
            //$display("rx_rden_send start[%t]", $realtime);
            
            @(posedge vif.rx_complete) begin

                
                //$display("INFO: rden_delay = %d", rx_mnt_dels.rden_delay);
                //$display("INFO: send_delay = %d", rx_mnt_dels.send_delay);

                #(rx_mnt_dels.rden_delay*CLK_CYCLE);
                
                @(posedge vif.clk) vif.rx_rden = 1;
                @(posedge vif.clk) vif.rx_rden = 0;
    
            end
            
            //$display("rx_rden_send complete [%t]", $realtime);
        end
        
    endtask
    
    
    task automatic reset_err();
    
        @(posedge vif.clk) vif.rst_err = 1;
        @(posedge vif.clk) vif.rst_err = 0;
        
    endtask
    
    task automatic run();
    
        fork
        
            receive_rx();
            rx_rden_send();
            receive_tx();
            
        join        
        
    endtask

endclass : Monitor
//===================================================================================
