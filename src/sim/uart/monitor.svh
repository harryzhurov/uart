//===================================================================================
//
//      Class Monitor
//
class Monitor;

    virtual   uart_if vif;

    int    num_trn_rx;
    int    num_trn_tx;
    data_t tx_data_mnt;

    rx_trn_t rx_tr_mnt;
    mnt_rcvd_t mnt_data;

    mailbox #(mnt_rcvd_t) mnt2scb_rx;
    mailbox #( rx_trn_t ) gen2mnt_rx;
    mailbox #(  data_t  ) mnt2scb_tx;
    
    covergroup rx_data_cg @(posedge vif.clk);
        rx_data : coverpoint vif.rx_data
        {
            bins dat_0   = {    0    };
            bins dat_63  = {[  1:63 ]};
            bins dat_127 = {[ 64:127]};
            bins dat_254 = {[128:254]};
            bins dat_255 = {   255   };
        }
        rx_err_fr : coverpoint vif.frame_error
        {
            bins err_0 = {0};
            bins err_1 = {1};
        }
        rx_err_run : coverpoint vif.overrun
        {
            bins err_0 = {0};
            bins err_1 = {1};
        }
        
        option.per_instance = 1;

    endgroup
    
    covergroup rx_del_cg;
        rx_rden_delay : coverpoint rx_tr_mnt.rden_delay
        {
            bins del_0  = {      0      };
            bins del_10 = {[    1:10000]};
            bins del_20 = {[10001:20000]};
            bins del_30 = {[20000:30000]};
        }
        
        option.per_instance = 1;

    endgroup
    
    covergroup tx_data_cg @(posedge vif.clk);
        tx_data : coverpoint tx_data_mnt
        {
            bins dat_0   = {    0    };
            bins dat_63  = {[  1:63 ]};
            bins dat_127 = {[ 64:127]};
            bins dat_254 = {[128:254]};
            bins dat_255 = {   255   };
        }
        
        option.per_instance = 1;

    endgroup
    
    function new(mailbox #(mnt_rcvd_t) mnt2scb_rx ,
                 mailbox #( rx_trn_t ) gen2mnt_rx ,
                 mailbox #(  data_t  ) mnt2scb_tx ,
                 virtual               uart_if vif);
    
        this.mnt2scb_rx  = mnt2scb_rx;
        this.gen2mnt_rx  = gen2mnt_rx;
        this.mnt2scb_tx  = mnt2scb_tx;
        this.vif         = vif;
        rx_data_cg       = new();
        rx_del_cg        = new();
        tx_data_cg       = new();

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
                        rx_data_cg.sample();
                        
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
    
    task automatic receive_tx();

        forever begin

            wait(!vif.txc);
            #(UART_CYCLE+UART_CYCLE/2);

            for(int i=0; i<WORD; i++) begin
                tx_data_mnt = {tx_data_mnt[WORD-2:0],vif.txc};
                #UART_CYCLE;
            end
            if(!vif.txc)
                $display("INFO : ERROR (tx) : wrong stop bit");

            tx_data_cg.sample();
            mnt2scb_tx.put(tx_data_mnt);

            num_trn_tx++;
            
            //$display("monitor (tx) : data received = %h", tx_data_mnt);
            //$display("monitor (tx) : Num transaction = %d", num_trn_tx);

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

            rx_del_cg.sample();

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
            receive_tx();
            
        join        
        
    endtask
//===================================================================================
endclass : Monitor
//===================================================================================
