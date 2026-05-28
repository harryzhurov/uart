//===================================================================================
//
//      Class Environment
//
class Environment;

    Generator   gen;
    Driver      drv;
    Monitor     mnt;
    Scoreboard  scb;
    
    mailbox #(tx_trn_t) gen2drv_tx;
    mailbox #(tx_pak_t) drv2scb_tx;
    mailbox #(tx_pak_t) mnt2scb_tx;
    
    virtual uart_if vif;
    
    function new(virtual uart_if vif);

        this.vif    = vif;
    
        gen2drv_tx  = new();
        drv2scb_tx  = new();
        mnt2scb_tx  = new();
        
        gen = new(gen2drv_tx);
        drv = new(gen2drv_tx,drv2scb_tx,vif);
        mnt = new(mnt2scb_tx,vif);
        scb = new(drv2scb_tx,mnt2scb_tx);
        
    endfunction;
    
    task automatic run();
        
        gen.run();

        fork
        
            drv.run();
            mnt.run();

        join_none
        
        run_wait_end();
        
        fork

            scb.run();
            
        join_none
        
        fork
            wait(scb.num_trn_tx == trn_cfg_pkg::num_trn_tx);
        join
        
        wait(scb.num_trn_tx == trn_cfg_pkg::num_trn_tx);
        
        if(!scb.err) $display("\033[32mINFO: Test succeed!\033[0m");
        else $display("\033[31mINFO: Test failed! Number of error = %d \033[0m", scb.err);
        
        $display("Final coverage: %0.2f%%", $get_coverage());

        $finish;
        
    endtask
    
    task automatic run_wait_end();
        begin
            wait(drv.num_trn_tx == num_trn_tx);
            $display("INFO: Driver finished TX");
        end
        begin
            wait(mnt.num_trn_tx == num_trn_tx);
            $display("INFO: Monitor finished TX");
        end
    endtask

endclass : Environment
//===================================================================================
