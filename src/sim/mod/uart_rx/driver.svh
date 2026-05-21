//===================================================================================
//
//      Class Driver
//
class Driver;

    virtual uart_if vif;
    
    semaphore sem_scb2drv;

    int    num_trn_rx;
    data_t reversed_data;
    
    rx_trn_t rx_tr_drv;

    mailbox #(rx_trn_t) gen2drv_rx;
    mailbox #(rx_trn_t) drv2scb_rx;
    
    function new(mailbox #(rx_trn_t) gen2drv_rx ,
                 mailbox #(rx_trn_t) drv2scb_rx ,
                 virtual             uart_if vif,
                 semaphore           sem_scb2drv);
    
        this.gen2drv_rx  = gen2drv_rx;
        this.drv2scb_rx  = drv2scb_rx;
        this.vif         = vif;
        this.sem_scb2drv = sem_scb2drv;
    
    endfunction 
    
    task automatic run_rx();

        forever begin

            gen2drv_rx.get(rx_tr_drv);

            if(sem_scb2drv.try_get(1))
                reinit_rxc();
            else begin

                fork
                    begin : dropping_rx

                        if(rx_tr_drv.drop_rx) begin

                            #(rx_tr_drv.drop_rx_del) $display("DROP RX!, time = [%t]",$realtime);
                            disable normal_transaction_rx;

                        end
                        else begin
                            #(1000*UART_CYCLE);
                        end

                    end
                    begin : normal_transaction_rx

                        send_rx();
                        disable dropping_rx;

                    end
                join_any

                num_trn_rx++;

                disable fork;

                vif.rxc = 1;
                #(UART_CYCLE);
                
                drv2scb_rx.put(rx_tr_drv);

            end
        end
    endtask

    task automatic send_rx();

        //$display("rx_run start, num = %d, time [%t]",num_trn_rx, $realtime);

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

        for(int i = 0; i < WORD; ++i) begin
            reversed_data[i] = rx_tr_drv.data[7-i];
        end

        //$display("driver (rx): data sent = %h", reversed_data);
        //$display("driver (rx): Num transaction = %d", num_trn_rx);

        //$display("rx_run done, num = %d, time [%t]",num_trn_rx, $realtime);

    endtask
    
    task automatic rx_rden_send();


        @(posedge vif.rx_rden_en) begin


            //$display("INFO: rden_delay = %d", rx_mnt_dels.rden_delay);
            //$display("INFO: send_delay = %d", rx_mnt_dels.send_delay);

            #(rx_tr_drv.rden_delay*CLK_CYCLE);

            @(posedge vif.clk) vif.rx_rden = 1;
            @(posedge vif.clk) vif.rx_rden = 0;

        end

        //$display("rx_rden_send complete [%t]", $realtime);

    endtask

    task automatic reinit_rxc();

        vif.rxc = 1;
        #(10*UART_CYCLE);

    endtask
    
    task automatic run();
    
        fork
        
            run_rx();
        
        join
    
    endtask

endclass : Driver
//===================================================================================
