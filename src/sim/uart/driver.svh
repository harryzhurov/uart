//===================================================================================
//
//      Class Driver
//
class Driver;

    virtual uart_if vif;

    int    num_trn_rx;
    int    num_trn_tx;
    data_t reversed_data;
    
    rx_trn_t rx_tr_drv;
    tx_trn_t tx_tr_drv;

    mailbox #(rx_trn_t) gen2drv_rx;
    mailbox #(tx_trn_t) gen2drv_tx;
    
    function new(mailbox #(rx_trn_t) gen2drv_rx,
                 mailbox #(tx_trn_t) gen2drv_tx,
                 virtual uart_if vif           );
    
        this.gen2drv_rx = gen2drv_rx;
        this.gen2drv_tx = gen2drv_tx;
        this.vif        = vif;
    
    endfunction 
    
    task automatic run_rx();
    
        forever begin

            //$display("rx_run start, num = %d, time [%t]",num_trn_rx, $realtime);
        
            gen2drv_rx.get(rx_tr_drv);
            
            #(rx_tr_drv.send_delay*CLK_CYCLE);
    
            wait(vif.baud_pulse);
            vif.rxc = 0;
    
            for(int i=0; i<WORD; i++) begin
                #(UART_CYCLE);
                vif.rxc = rx_tr_drv.data[i];
            end
            
            #(UART_CYCLE) vif.rxc = rx_tr_drv.stop_bit;
            
            #(UART_CYCLE) vif.rxc = 1;
            #(UART_CYCLE);
            
            num_trn_rx++;
            
            for(int i = 0; i < WORD; ++i) begin
                reversed_data[i] = rx_tr_drv.data[7-i];
            end
            
            //$display("driver (rx): data sent = %h", reversed_data);
            //$display("driver (rx): Num transaction = %d", num_trn_rx);
            
            //$display("rx_run done, num = %d, time [%t]",num_trn_rx, $realtime);
        
        end
    
    endtask
    
    task automatic run_tx();

        forever begin

            gen2drv_tx.get(tx_tr_drv);

            #(tx_tr_drv.data_delay*CLK_CYCLE);

             if(vif.tx_empty)
                vif.tx_data = tx_tr_drv.data;
             else begin
                wait(vif.tx_empty);
                vif.tx_data = tx_tr_drv.data;
             end

            @(posedge vif.clk) vif.tx_wren = 1;
            @(posedge vif.clk) vif.tx_wren = 0;

            #20ns;

            num_trn_tx++;
            
            //$display("driver (tx): data sent = %h", tx_tr_drv.data);
            //$display("driver (tx): Num transaction = %d", num_trn_tx);

        end

    endtask
    
    task automatic run();
    
        fork
        
            run_rx();
            run_tx();
        
        join
    
    endtask

endclass : Driver
//===================================================================================
