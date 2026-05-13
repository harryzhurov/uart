//===================================================================================
//
//      Class Monitor
//
class Monitor;

    virtual uart_if uif;

    int num_trn_rx;

    mnt_dels_t rx_mnt_dels;
    mnt_rcvd_t mnt_data;

    mailbox #(mnt_rcvd_t) mnt2scb_rx;
    mailbox #(mnt_dels_t) gen2mnt_rx;
    
    function new(mailbox #(mnt_rcvd_t) mnt2scb_rx,
                 mailbox #(mnt_dels_t) gen2mnt_rx,
                 virtual uart_if uif             );
    
        this.mnt2scb_rx = mnt2scb_rx;
        this.gen2mnt_rx = gen2mnt_rx;
        this.uif        = uif;
    
    endfunction 
    
    task automatic receive_rx();
    
        forever begin

            @(uif.rx_data, posedge uif.rx_complete, posedge uif.overrun) begin
                mnt_data.data        = uif.rx_data;
                mnt_data.frame_error = uif.frame_error;
                mnt_data.overrun     = uif.overrun;
                mnt2scb_rx.put(mnt_data);
                if(uif.overrun | uif.frame_error)
                    reset_err();
            end
            
            num_trn_rx++;
            
            //$display("monitor : data received = %h", uif.rx_data);
            //$display("monitor : Num transaction = %d", num_trn_rx);

        end
    
    endtask
    
    task automatic rx_rden_send();

        forever begin

            gen2mnt_rx.get(rx_mnt_dels);
            
            //$display("rx_rden_send start[%t]", $realtime);
            
            @(posedge uif.rx_complete) begin

                
                //$display("INFO: rden_delay = %d", rx_mnt_dels.rden_delay);
                //$display("INFO: send_delay = %d", rx_mnt_dels.send_delay);

                #(rx_mnt_dels.rden_delay*CLK_CYCLE);
                
                @(posedge uif.clk) uif.rx_rden = 1;
                @(posedge uif.clk) uif.rx_rden = 0;
    
            end
            
            //$display("rx_rden_send complete [%t]", $realtime);
        end
        
    endtask
    
    
    task automatic reset_err();
    
        @(posedge uif.clk) uif.rst_err = 1;
        @(posedge uif.clk) uif.rst_err = 0;
        
    endtask
    
    task automatic run();
    
        fork
        
            receive_rx();
            rx_rden_send();
            
        join        
        
    endtask

endclass : Monitor
//===================================================================================
