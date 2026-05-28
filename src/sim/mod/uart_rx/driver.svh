//===================================================================================
//
//      Class Driver
//
class Driver;

    virtual uart_if vif;

    int    num_trn_rx;
    int    percent;
    int    last_percent = -1;
    int    drop_time;
    data_t reversed_data;
    
    rx_trn_t rx_tr_drv;

    mailbox #(rx_trn_t) gen2drv_rx;
    mailbox #(rx_trn_t) drv2scb_rx;
    
    function new(mailbox #(rx_trn_t) gen2drv_rx ,
                 mailbox #(rx_trn_t) drv2scb_rx ,
                 virtual             uart_if vif);
    
        this.gen2drv_rx  = gen2drv_rx;
        this.drv2scb_rx  = drv2scb_rx;
        this.vif         = vif;
    
    endfunction
    
    function void meas_percent;
        percent = (this.num_trn_rx*100) / (trn_cfg_pkg::num_trn_rx);

        if (percent != last_percent && (percent % 10 == 0 || percent == 100)) begin
            $display("INFO: Driver completed %0d%%", percent);
            last_percent = percent;
        end
    endfunction
    
    task automatic run_rx();

        repeat (trn_cfg_pkg::num_trn_rx) begin

            gen2drv_rx.get(rx_tr_drv);

            send_rx();

            num_trn_rx++;
            
            meas_percent;
            
            drv2scb_rx.put(rx_tr_drv);

        end
    endtask

    task automatic send_rx();

        #(rx_tr_drv.send_delay*CLK_CYCLE);
        
        wait(vif.baud_pulse);
        vif.rxc = 0;
        
        drop_time = $time + rx_tr_drv.drop_rx_del;
        
        for(int i=0; i<WORD; i++) begin

            #(UART_CYCLE);
            
            if(rx_tr_drv.drop_rx && ($time >= drop_time)) begin

                vif.rxc = 1;
                
                #(UART_CYCLE*10);
                return;
            end

            vif.rxc = rx_tr_drv.data[i];
        end
        
        #(UART_CYCLE) vif.rxc = rx_tr_drv.stop_bit;

        #(UART_CYCLE) vif.rxc = 1;
        #(UART_CYCLE);
        
    endtask
    
    task automatic rx_rden_send();

        forever begin

            @(vif.rx_rden_en);

            #(rx_tr_drv.rden_delay*CLK_CYCLE);

            @(posedge vif.clk) vif.rx_rden = 1;
            @(posedge vif.clk) vif.rx_rden = 0;
            
        end

    endtask

    task automatic reset_error();
        forever begin
            @(vif.reset_err);
            @(posedge vif.clk) vif.rst_err = 1;
            @(posedge vif.clk) vif.rst_err = 0;
        end
    endtask
    
    task automatic run();
    
        fork
        
            run_rx();
            rx_rden_send();
            reset_error();
        
        join
    
    endtask

endclass : Driver
//===================================================================================
