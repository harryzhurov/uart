//===================================================================================
//
//      Class Generator
//
class Generator;

    Rx_transaction rx_trn;

    rx_trn_t   rx_tr_gen ;

    mailbox #(rx_trn_t) gen2drv_rx;
    
    function new(mailbox #(rx_trn_t) gen2drv_rx);
    
        this.gen2drv_rx = gen2drv_rx;
        
    endfunction
    
    task automatic run_rx();

        repeat (num_trn_rx) begin

            rx_trn = new();
            void'(rx_trn.randomize());

            if(!rx_trn.randomize()) $display("INFO: ERROR: rx_transaction_randomization failed!");

            rx_tr_gen.data        = rx_trn.data;
            rx_tr_gen.send_delay  = rx_trn.send_delay;
            rx_tr_gen.rden_delay  = rx_trn.rden_delay;
            rx_tr_gen.stop_bit    = rx_trn.stop_bit;
            rx_tr_gen.drop_rx     = rx_trn.drop_rx;
            rx_tr_gen.drop_rx_del = rx_trn.drop_rx_del;
            rx_tr_gen.id          = rx_trn.id;

            gen2drv_rx.put(rx_tr_gen);

        end

    endtask
    
    task run();

            run_rx();

    endtask
    
    
endclass : Generator
