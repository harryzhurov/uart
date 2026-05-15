//===================================================================================
//
//      Class Environment
//
class Environment;

    Generator   gen;
    Driver      drv;
    Monitor     mnt;
    Scoreboard  scb;
    
    mailbox #( rx_trn_t ) gen2drv_rx;
    mailbox #( rx_trn_t ) gen2scb_rx;
    mailbox #(mnt_rcvd_t) mnt2scb_rx;
    mailbox #(mnt_dels_t) gen2mnt_rx;
    mailbox #( tx_trn_t ) gen2drv_tx;
    mailbox #( tx_trn_t ) gen2scb_tx;
    mailbox #(  data_t  ) mnt2scb_tx;
    
    virtual uart_if vif;
    
    function new(virtual uart_if vif);

        this.vif   = vif;
    
        gen2drv_rx = new();
        gen2scb_rx = new();
        mnt2scb_rx = new();
        gen2mnt_rx = new();
        gen2drv_tx = new();
        gen2scb_tx = new();
        mnt2scb_tx = new();
        
        gen = new(gen2drv_rx,gen2scb_rx,gen2mnt_rx,gen2drv_tx,gen2scb_tx);
        drv = new(gen2drv_rx,gen2drv_tx,vif);
        mnt = new(mnt2scb_rx,gen2mnt_rx,mnt2scb_tx,vif);
        scb = new(gen2scb_rx,mnt2scb_rx,gen2scb_tx,mnt2scb_tx);
        
    endfunction;
    
    task automatic run();
        
        fork
        
            gen.run();
            drv.run();
            mnt.run();
            scb.run();
            
        join_any
        
        run_wait_end();
        
        if(!scb.err) $display("\033[32mINFO: Test succeed!\033[0m");
        else $display("\033[31mINFO: Test failed! Number of error = %d \033[0m", scb.err);
        
        $display("Final coverage: %0.2f%%", $get_coverage());
        
        $finish;
        
    endtask
    
    task automatic run_wait_end();
    
        fork
            
            wait(scb.num_trn_rx == num_trn_rx);
            wait(mnt.num_trn_rx == num_trn_rx);
            wait(scb.num_trn_tx == num_trn_tx);
            wait(mnt.num_trn_tx == num_trn_tx);
        
        join
        
    endtask
//===================================================================================
endclass : Environment
//===================================================================================
