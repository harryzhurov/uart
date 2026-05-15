//===================================================================================
class Rx_transaction;

    static int          count = 0;
    int                 id;
               
    rand bit            stop_bit;
    rand bit            wrong_rden;
    rand bit            del_send;
    rand bit            drop_rx;
    rand int            send_delay;
    rand int            rden_delay;
    rand bit [WORD-1:0] data;
    rand int            drop_rx_del;

    function new();
        
        id = count++;
        
    endfunction

    constraint data_cnstr
    {
        data        inside {[0:255]};
        drop_rx_del inside {[0:UART_CYCLE*10]};

        stop_bit    dist  {0 := (wrong_stop_exist_rx), 1       := (100 - wrong_stop_exist_rx)};
        data        dist  {0 := (zero_data_rx)       , [1:255] := (100 - zero_data_rx)       };
        
        drop_rx     dist  {0 := ( 100 - drop_rx_trn ), 1       := ( drop_rx_trn)             };
        
        (drop_rx==0) -> (drop_rx_del==0);
        solve drop_rx before drop_rx_del;

    }
    
    constraint delay_cnstr
    {

        rden_delay inside {[0:rden_del_dist_rx]};
        send_delay inside {[0:send_del_dist_rx]};

        wrong_rden  dist  {0 := (100 - rden_del_exist_rx) , 1 := (rden_del_exist_rx)};
        del_send    dist  {0 := (100 - send_del_exist_rx) , 1 := (send_del_exist_rx)};
        
        (del_send == 0) -> (send_delay==0);
        solve del_send before send_delay;
        (wrong_rden==0) -> (rden_delay==0);
        solve wrong_rden before rden_delay;

    }

endclass : Rx_transaction
//===================================================================================
//
//      Class Transactions
//
class Tx_transaction;

    static int          count = 0;
    int                 id;

    rand bit            send_del;
    rand bit            drop_tx;
    rand int            data_delay;
    rand bit [WORD-1:0] data;
    rand int            drop_tx_del;

    function new();

        id = count++;

    endfunction

    constraint data_cnstr
    {
        data        inside {[0:255          ]};
        drop_tx_del inside {[0:UART_CYCLE*10]};

        data        dist  {0 := (zero_data_tx)       , [1:255] := (100 - zero_data_tx)};
        drop_tx     dist  {0 := ( 100 - drop_tx_trn ), 1       := ( drop_tx_trn)      };
        
        (drop_tx==0) -> (drop_tx_del==0);
        solve drop_tx before drop_tx_del;

    }
    
    constraint delay_cnstr
    {
        data_delay inside {[0:send_del_dist_tx]};

        send_del    dist  {0 := (100 - send_del_exist_tx), 1 := (send_del_exist_tx)};

        (send_del==0) -> (data_delay==0);
        solve send_del before data_delay;
    }

//===================================================================================
endclass : Tx_transaction
//===================================================================================
