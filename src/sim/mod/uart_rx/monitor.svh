//===================================================================================
//
//      Class Monitor
//
class Monitor;

    virtual uart_if vif;

    int num_trn_rx;

    rx_trn_t   rx_tr_mnt;
    mnt_rcvd_t mnt_data;

    mailbox #(mnt_rcvd_t) mnt2scb_rx;
    
    function new(mailbox #(mnt_rcvd_t) mnt2scb_rx ,
                 virtual               uart_if vif);
    
        this.mnt2scb_rx = mnt2scb_rx;
        this.vif        = vif;
    
    endfunction 
    
    task automatic receive_rx();

        forever begin

            gen2mnt_rx.get(rx_tr_mnt);

            fork
            begin
                if(!rx_tr_mnt.drop_rx) begin
                    @(vif.rx_data, posedge vif.rx_complete, posedge vif.overrun) begin

                        mnt_data.data        = vif.rx_data;
                        mnt_data.frame_error = vif.frame_error;
                        mnt_data.overrun     = vif.overrun;
                        mnt2scb_rx.put(mnt_data);

                        if(vif.overrun | vif.frame_error) begin
                            reset_err();
                        end
                    end
                end
                else begin
                    mnt2scb_rx.put(mnt_data);
                end

                num_trn_rx++;

                //$display("monitor (rx) : data received = %h", vif.rx_data);
                //$display("monitor (rx) : Num transaction = %d", num_trn_rx);
            end
            begin
                rx_rden_send();
            end
            join_any
        end

    endtask
    
    task automatic rx_rden_send();

        //$display("rx_rden_send start[%t]", $realtime);

        @(posedge vif.rx_complete) begin


            //$display("INFO: rden_delay = %d", rx_mnt_dels.rden_delay);
            //$display("INFO: send_delay = %d", rx_mnt_dels.send_delay);

            #(rx_tr_mnt.rden_delay*CLK_CYCLE);

            @(posedge vif.clk) vif.rx_rden = 1;
            @(posedge vif.clk) vif.rx_rden = 0;


        end

        //$display("rx_rden_send complete [%t]", $realtime);

    endtask
    
    
    task automatic reset_err();
    
        @(posedge vif.clk) vif.rst_err = 1;
        @(posedge vif.clk) vif.rst_err = 0;
        
    endtask
    
    task automatic run();
    
        fork
        
            receive_rx();
            
        join        
        
    endtask

endclass : Monitor
//===================================================================================
