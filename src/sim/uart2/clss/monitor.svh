//===================================================================================
//
//      Class Monitor
//
class Monitor;

    int num_trn_tx;
    int num_trn_rx;
    int err;

    logic [WORD-1:0] tx_data_mnt;
    logic [WORD-1:0] rx_data_mnt;

    mnt_dels_t  rx_mnt_dels;

    mailbox #(logic [WORD-1:0]) mnt2scb_tx;
    mailbox #(logic [WORD-1:0]) mnt2scb_rx;
    mailbox #(   mnt_dels_t   ) gen2mnt_rx;
    
    function new(mailbox #(logic [WORD-1:0]) mnt2scb_tx,
                 mailbox #(logic [WORD-1:0]) mnt2scb_rx,
                 mailbox #(   mnt_dels_t   ) gen2mnt_rx);
    
        this.mnt2scb_tx = mnt2scb_tx;
        this.mnt2scb_rx = mnt2scb_rx;
        this.gen2mnt_rx = gen2mnt_rx;
    
    endfunction 
    
    task automatic receive_rx();
    
        forever begin

            @(posedge rx_complete, posedge overrun) begin
                wait(baud_pulse);
                mnt2scb_rx.put(rx_data);
            end
            
            num_trn_rx++;
        end
    
    endtask
    
    task automatic rx_rden_send();

        forever begin

            gen2mnt_rx.get(rx_mnt_dels);
            
            //$display("rx_rden_send start[%t]", $realtime);
            
            @(posedge rx_complete) begin

                
                /*$display("INFO: rden_delay = %d", rx_mnt_dels.rden_delay);
                $display("INFO: send_delay = %d", rx_mnt_dels.send_delay);*/

                #(rx_mnt_dels.rden_delay*CLK_CYCLE);
                
                @(posedge clk) rx_rden = 1;
                @(posedge clk) rx_rden = 0;
    
                if(overrun | frame_error)
                    reset_err();
    
            end
            
            //$display("rx_rden_send complete [%t]", $realtime);
        end
        
    endtask
    
    task automatic receive_tx();
        forever begin
            wait(!txc);
            #(UART_CYCLE+UART_CYCLE/2);
    
            for(int i=0; i<WORD; i++) begin
                tx_data_mnt = {tx_data_mnt[WORD-2:0],txc};
                #UART_CYCLE;
            end
    
            mnt2scb_tx.put(tx_data_mnt);
            
            num_trn_tx++;
    
        end
    endtask
    
    task automatic reset_err();
    
        @(posedge clk) rst_err = 1;
        @(posedge clk) rst_err = 0;
        
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
