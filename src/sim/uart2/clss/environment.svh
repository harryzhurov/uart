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
    mailbox #(    rx_trn_t    ) gen2drv_rx;
    mailbox #(    tx_trn_t    ) gen2scb_tx;
    mailbox #(    rx_trn_t    ) gen2scb_rx;
    mailbox #(logic [WORD-1:0]) mnt2scb_tx;
    mailbox #(logic [WORD-1:0]) mnt2scb_rx;
    mailbox #(   mnt_dels_t   ) gen2mnt_rx;
    
    function new();
    
        gen2drv_tx = new();
        gen2drv_rx = new();
        gen2scb_tx = new();
        gen2scb_rx = new();
        mnt2scb_tx = new();
        mnt2scb_rx = new();
        gen2mnt_rx = new();
        
        gen = new(gen2drv_tx,gen2drv_rx,gen2scb_tx,gen2scb_rx,gen2mnt_rx);
        drv = new(gen2drv_tx,gen2drv_rx);
        mnt = new(mnt2scb_tx,mnt2scb_rx,gen2mnt_rx);
        scb = new(gen2scb_tx,gen2scb_rx,mnt2scb_tx,mnt2scb_rx);
        
    endfunction;
    
    task automatic run();
        
        fork
        
            gen.run();
            drv.run();
            mnt.run();
            scb.run();
            
        join_any
        
        run_wait_end();
        
        if(!err) $display("\033[32mINFO: Test succeed!\033[0m");
        else $display("\033[31mINFO: Test failed! Number of error = %d \033[0m", mnt.err);
        
        $finish;
        
    endtask
    
    task automatic run_wait_end();
    
        fork
            
            wait(scb.num_trn_tx == num_trn_tx);
            wait(mnt.num_trn_tx == num_trn_tx);
            wait(scb.num_trn_rx == num_trn_rx);
            wait(mnt.num_trn_rx == num_trn_rx);
        
        join
        
    endtask

endclass : Environment
//===================================================================================
