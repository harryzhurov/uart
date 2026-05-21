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
    mailbox #(mnt_rcvd_t) mnt2scb_rx;
    
    virtual uart_if vif;
    
    semaphore sem_scb2drv;
    
    function new(virtual uart_if vif);

        this.vif    = vif;
        sem_scb2drv = new();
    
        gen2drv_rx  = new();
        mnt2scb_rx  = new();
        
        gen = new(gen2drv_rx,gen2scb_rx,gen2mnt_rx);
        drv = new(gen2drv_rx,vif,sem_scb2drv);
        mnt = new(mnt2scb_rx,gen2mnt_rx,vif);
        scb = new(gen2scb_rx,mnt2scb_rx,sem_scb2drv);
        
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
        
        join
        
    endtask

endclass : Environment
//===================================================================================
