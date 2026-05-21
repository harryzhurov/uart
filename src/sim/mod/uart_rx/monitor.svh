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

            fork
            begin
                @(vif.rx_data, posedge vif.rx_complete, posedge vif.overrun);

                mnt_data.data        = vif.rx_data;
                mnt_data.frame_error = vif.frame_error;
                mnt_data.overrun     = vif.overrun;
                if(num_trn_rx != 0)
                    mnt2scb_rx.put(mnt_data);

                if(vif.overrun | vif.frame_error) begin
                    reset_err();
                end

                num_trn_rx++;
                
                #UART_CYCLE;

                //$display("monitor (rx) : data received = %h", vif.rx_data);
                //$display("monitor (rx) : Num transaction = %d", num_trn_rx);
            end
            begin
                rx_catch_complete();
            end
            join_any
        end

    endtask
    
    task automatic rx_catch_complete();

        @(posedge vif.rx_complete) -> vif.rx_rden_en;

    endtask
    
    
    task automatic reset_err();
    
        @(posedge vif.clk) vif.rst_err = 1;
        @(posedge vif.clk) vif.rst_err = 0;
        
    endtask
    
    task automatic run();
    
        fork

            @(negedge vif.init_en);
            #CLK_CYCLE;
        
            receive_rx();
            
        join        
        
    endtask

endclass : Monitor
//===================================================================================
