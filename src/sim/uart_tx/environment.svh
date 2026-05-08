//===================================================================================
//
//      Class Environment
//
class Environment;

    Generator   gen;
    Driver      drv;
    Monitor     mnt;
    Scoreboard  scb;
    
    mailbox #(    tx_trn_t    ) gen2drv_tx;
    mailbox #(    tx_trn_t    ) gen2scb_tx;
    mailbox #(logic [WORD-1:0]) mnt2scb_tx;
    
    virtual uart_if uif;
    
    function new(virtual uart_if uif);

        this.uif   = uif;
    
        gen2drv_tx = new();
        gen2scb_tx = new();
        mnt2scb_tx = new();
        
        gen = new(gen2drv_tx,gen2scb_tx,uif);
        drv = new(gen2drv_tx,uif);
        mnt = new(mnt2scb_tx,uif);
        scb = new(gen2scb_tx,mnt2scb_tx,uif);
        
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
        
        $finish;
        
    endtask
    
    task automatic run_wait_end();
    
        fork
            
            wait(scb.num_trn_tx == num_trn_tx);
            wait(mnt.num_trn_tx == num_trn_tx);
        
        join
        
    endtask

endclass : Environment
//===================================================================================
