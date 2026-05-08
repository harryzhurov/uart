//===================================================================================
//
//      Class Environment
//
class Environment;

    Generator   gen;
    Driver      drv;
    Monitor     mnt;
    Scoreboard  scb;
    
    mailbox #(    rx_trn_t    ) gen2drv_rx;
    mailbox #(    rx_trn_t    ) gen2scb_rx;
    mailbox #(logic [WORD-1:0]) mnt2scb_rx;
    mailbox #(   mnt_dels_t   ) gen2mnt_rx;
    
    virtual uart_if uif;
    
    function new(virtual uart_if uif);

        this.uif   = uif;
    
        gen2drv_rx = new();
        gen2scb_rx = new();
        mnt2scb_rx = new();
        gen2mnt_rx = new();
        
        gen = new(gen2drv_rx,gen2scb_rx,gen2mnt_rx,uif);
        drv = new(gen2drv_rx,uif);
        mnt = new(mnt2scb_rx,gen2mnt_rx,uif);
        scb = new(gen2scb_rx,mnt2scb_rx,uif);
        
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
            
            wait(scb.num_trn_rx == num_trn_rx);
            wait(mnt.num_trn_rx == num_trn_rx);
        
        join
        
    endtask

endclass : Environment
//===================================================================================
