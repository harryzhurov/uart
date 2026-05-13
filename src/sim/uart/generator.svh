//===================================================================================
//
//      Class Generator
//
class Generator;

    Rx_transaction rx_trn;
    Tx_transaction tx_trn;

    mnt_dels_t rx_mnt_del;
    rx_trn_t   rx_tr_gen ;
    tx_trn_t   tx_tr_gen ;
    
    virtual uart_if uif;

    mailbox #( rx_trn_t ) gen2drv_rx;
    mailbox #( tx_trn_t ) gen2drv_tx;
    mailbox #( rx_trn_t ) gen2scb_rx;
    mailbox #( tx_trn_t ) gen2scb_tx;
    mailbox #(mnt_dels_t) gen2mnt_rx;
    
    function new(mailbox #( rx_trn_t ) gen2drv_rx,
                 mailbox #( rx_trn_t ) gen2scb_rx,
                 mailbox #(mnt_dels_t) gen2mnt_rx,
                 mailbox #( tx_trn_t ) gen2drv_tx,
                 mailbox #( tx_trn_t ) gen2scb_tx,
                 virtual uart_if uif            );
    
        this.gen2drv_rx = gen2drv_rx;
        this.gen2scb_rx = gen2scb_rx;
        this.gen2mnt_rx = gen2mnt_rx;
        this.gen2drv_tx = gen2drv_tx;
        this.gen2scb_tx = gen2scb_tx;
        this.uif        = uif;
        
    endfunction
    
    task automatic run_rx();
    
        repeat (num_trn_rx) begin
        
            rx_trn = new();
            rx_trn.randomize();
            
            if(!rx_trn.randomize()) $display("INFO: ERROR: rx_transaction_randomization failed!");
            
            rx_tr_gen.data        = rx_trn.data;
            rx_tr_gen.send_delay  = rx_trn.send_delay;
            rx_tr_gen.rden_delay  = rx_trn.rden_delay;
            rx_tr_gen.stop_bit    = rx_trn.stop_bit;
            rx_tr_gen.id          = rx_trn.id;
            
            rx_mnt_del.rden_delay = rx_trn.rden_delay;
            rx_mnt_del.send_delay = rx_trn.send_delay;
            
            
            gen2drv_rx.put(rx_tr_gen );
            gen2scb_rx.put(rx_tr_gen );
            gen2mnt_rx.put(rx_mnt_del);
            gen2mnt_rx.put(rx_mnt_del);
            
        end
    
    endtask

    task automatic run_tx();

        repeat (num_trn_tx) begin

            tx_trn = new();
            tx_trn.randomize();

            if(!tx_trn.randomize()) $display("INFO: ERROR: tx_transaction_randomization failed!");

            tx_tr_gen.data       = tx_trn.data;
            tx_tr_gen.data_delay = tx_trn.data_delay;
            tx_tr_gen.id         = tx_trn.id;

            gen2drv_tx.put(tx_tr_gen);
            gen2scb_tx.put(tx_tr_gen);

        end

    endtask
    
    task run();

        fork

            run_rx();
            run_tx();

        join

    endtask
    
    
endclass : Generator
