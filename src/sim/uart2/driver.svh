//===================================================================================
//
//      Class Driver
//
class Driver;

    virtual uart_if uif;

    int num_trn_tx;
    int num_trn_rx;
    
    tx_trn_t tx_tr_drv;
    rx_trn_t rx_tr_drv;

    mailbox #(tx_trn_t) gen2drv_tx;
    mailbox #(rx_trn_t) gen2drv_rx;
    
    function new(mailbox #(tx_trn_t) gen2drv_tx,
                 mailbox #(rx_trn_t) gen2drv_rx,
                 virtual uart_if uif           );
    
        this.gen2drv_tx = gen2drv_tx;
        this.gen2drv_rx = gen2drv_rx;
        this.uif        = uif;
    
    endfunction 
    
    task automatic run_tx();
    
        forever begin
        
            gen2drv_tx.get(tx_tr_drv);
            
            #(tx_tr_drv.data_delay*CLK_CYCLE);
    
             if(uif.tx_empty)
                uif.tx_data = tx_tr_drv.data;
             else begin
                wait(uif.tx_empty);
                uif.tx_data = tx_tr_drv.data;
             end
    
            @(posedge uif.clk) uif.tx_wren = 1;
            @(posedge uif.clk) uif.tx_wren = 0;
    
            wait(uif.tx_complete);
            
            num_trn_tx++;
        
        end
    
    endtask
    
    task automatic run_rx();
    
        forever begin

            //$display("rx_run start, num = %d, time [%t]",num_trn_rx, $realtime);
        
            gen2drv_rx.get(rx_tr_drv);
            
            #(rx_tr_drv.send_delay*CLK_CYCLE);
    
            wait(uif.baud_pulse);
            uif.rxc = 0;
    
            for(int i=0; i<WORD; i++) begin
                #(UART_CYCLE);
                uif.rxc = rx_tr_drv.data[i];
            end
            
            #(UART_CYCLE) uif.rxc = rx_tr_drv.stop_bit;
            
            #(UART_CYCLE) uif.rxc = 1;
            #(UART_CYCLE);
            
            num_trn_rx++;
            
            //$display("rx_run done, num = %d, time [%t]",num_trn_rx, $realtime);
        
        end
    
    endtask
    
    task automatic run();
    
        fork
        
            run_tx();
            run_rx();
        
        join
    
    endtask

endclass : Driver
//===================================================================================
