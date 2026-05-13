//===================================================================================
//
//      Class Driver
//
class Driver;

    virtual uart_if uif;

    int num_trn_rx;
    data_t reversed_data;
    
    rx_trn_t rx_tr_drv;

    mailbox #(rx_trn_t) gen2drv_rx;
    
    function new(mailbox #(rx_trn_t) gen2drv_rx,
                 virtual uart_if uif           );
    
        this.gen2drv_rx = gen2drv_rx;
        this.uif        = uif;
    
    endfunction 
    
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
        
            run_rx();
        
        join
    
    endtask

endclass : Driver
//===================================================================================
