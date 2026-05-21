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
    mailbox #( rx_trn_t ) drv2scb_rx;
    mailbox #(mnt_rcvd_t) mnt2scb_rx;
    
    virtual uart_if vif;
    
    semaphore sem_scb2drv;
    
    function new(virtual uart_if vif);

        this.vif    = vif;
        sem_scb2drv = new();
    
        gen2drv_rx  = new();
        drv2scb_rx  = new();
        mnt2scb_rx  = new();
        
        gen = new(gen2drv_rx);
        drv = new(gen2drv_rx,drv2scb_rx,vif,sem_scb2drv);
        mnt = new(mnt2scb_rx,vif);
        scb = new(drv2scb_rx,mnt2scb_rx,sem_scb2drv);
        
    endfunction;
    
    task automatic run();
        
        gen.run();
        
        fork
        
            drv.run();
            mnt.run();

        join_none
        
        run_wait_end();
        
        fork

            scb.run;
            
        join_none
        
        wait( scb.num_trn_rx == trn_cfg_pkg::num_trn_rx);
        
        if(!scb.err) $display("\033[32mINFO: Test succeed!\033[0m");
        else $display("\033[31mINFO: Test failed! Number of error = %d \033[0m", scb.err);
        
        $display("Final coverage: %0.2f%%", $get_coverage());

        $finish;
        
    endtask
    
    task automatic run_wait_end();
    
        fork
            
            wait(drv.num_trn_rx == trn_cfg_pkg::num_trn_rx);
            $display("INFO: Driver finished");
            wait(mnt.num_trn_rx == trn_cfg_pkg::num_trn_rx);
            $display("INFO: Monitor finished");
        
        join
        
    endtask

endclass : Environment
//===================================================================================
