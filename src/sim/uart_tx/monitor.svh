//===================================================================================
//
//      Class Monitor
//
class Monitor;

    virtual uart_if uif;

    int num_trn_tx;

    logic [WORD-1:0] tx_data_mnt;

    mailbox #(logic [WORD-1:0]) mnt2scb_tx;
    
    function new(mailbox #(logic [WORD-1:0]) mnt2scb_tx,
                 virtual uart_if uif                  );
    
        this.mnt2scb_tx = mnt2scb_tx;
        this.uif        = uif;
    
    endfunction 
    
    task automatic receive_tx();
        forever begin
            wait(!uif.txc);
            #(UART_CYCLE+UART_CYCLE/2);
    
            for(int i=0; i<WORD; i++) begin
                tx_data_mnt = {tx_data_mnt[WORD-2:0],uif.txc};
                #UART_CYCLE;
            end
    
            mnt2scb_tx.put(tx_data_mnt);
            
            num_trn_tx++;
    
        end
    endtask
    
    task automatic run();
    
        fork
        
            receive_tx();
            
        join        
        
    endtask

endclass : Monitor
//===================================================================================
