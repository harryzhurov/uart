//===================================================================================
//
//      Class Driver
//
class Driver;

    int num_trn_tx;
    int num_trn_rx;
    
    tx_trn_t tx_tr_drv;
    rx_trn_t rx_tr_drv;

    mailbox #(tx_trn_t) gen2drv_tx;
    mailbox #(rx_trn_t) gen2drv_rx;
    
    function new(mailbox #(tx_trn_t) gen2drv_tx,
                 mailbox #(rx_trn_t) gen2drv_rx);
    
        this.gen2drv_tx = gen2drv_tx;
        this.gen2drv_rx = gen2drv_rx;
    
    endfunction 
    
    task automatic run_tx();
    
        forever begin
        
            gen2drv_tx.get(tx_tr_drv);
            
            #(tx_tr_drv.data_delay*CLK_CYCLE);
    
             if(tx_empty) 
                tx_data = tx_tr_drv.data;
             else begin
                wait(tx_empty);
                tx_data = tx_tr_drv.data;
             end
    
            @(posedge clk) tx_wren = 1;
            @(posedge clk) tx_wren = 0;
    
            wait(tx_complete);
            
            num_trn_tx++;
        
        end
    
    endtask
    
    task automatic run_rx();
    
        forever begin

            //$display("rx_run start, num = %d, time [%t]",num_trn_rx, $realtime);
        
            gen2drv_rx.get(rx_tr_drv);
            
            #(rx_tr_drv.send_delay*CLK_CYCLE);
    
            wait(baud_pulse);
            rxc = 0;
    
            for(int i=0; i<WORD; i++) begin
                #(UART_CYCLE);
                rxc = rx_tr_drv.data[i];
            end
            
            #(UART_CYCLE) rxc = rx_tr_drv.stop_bit;
            
            #(UART_CYCLE) rxc = 1;
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
