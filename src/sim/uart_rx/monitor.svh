//===================================================================================
//
//      Class Monitor
//
class Monitor;

    virtual uart_if uif;

    int num_trn_rx;

    logic [WORD-1:0] rx_data_mnt;

    mnt_dels_t  rx_mnt_dels;

    mailbox #(logic [WORD-1:0]) mnt2scb_rx;
    mailbox #(   mnt_dels_t   ) gen2mnt_rx;
    
    function new(mailbox #(logic [WORD-1:0]) mnt2scb_rx,
                 mailbox #(   mnt_dels_t   ) gen2mnt_rx,
                 virtual uart_if uif                  );
    
        this.mnt2scb_rx = mnt2scb_rx;
        this.gen2mnt_rx = gen2mnt_rx;
        this.uif        = uif;
    
    endfunction 
    
    task automatic receive_rx();
    
        forever begin
            
            #100ns;
            @(uif.rx_data, posedge uif.rx_complete, posedge uif.overrun);
            
            mnt2scb_rx.put(uif.rx_data);
            
            num_trn_rx++;
            
            $display("monitor : time = [%t] num_tr_rx = %d", $time, num_trn_rx);
            $display("monitor : data = %h", uif.rx_data);
            
        end
    
    endtask
    
    task automatic rx_rden_send();

        forever begin

            gen2mnt_rx.get(rx_mnt_dels);
            
            //$display("rx_rden_send start[%t]", $realtime);
            
            @(posedge uif.rx_complete) begin

                
                /*$display("INFO: rden_delay = %d", rx_mnt_dels.rden_delay);
                $display("INFO: send_delay = %d", rx_mnt_dels.send_delay);*/

                #(rx_mnt_dels.rden_delay*CLK_CYCLE);
                
                @(posedge uif.clk) uif.rx_rden = 1;
                @(posedge uif.clk) uif.rx_rden = 0;
    
                if(uif.overrun | uif.frame_error)
                    reset_err();
    
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
