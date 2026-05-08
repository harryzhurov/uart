//===================================================================================
//
//      Class Transactions
//
class Tx_transaction;

    static int          count = 0;
    int                 id;
               
    rand bit            send_del;
    rand int            data_delay;
    rand bit [WORD-1:0] data;

    function new();
        
        id = count++;
        
    endfunction

    constraint cst
    {
        data       inside {[0:255             ]};
        data_delay inside {[0:send_del_dist_tx]};
        
        data        dist  {0 := (zero_data_tx)            , [1:255] := (100 - zero_data_tx)  };
        send_del    dist  {0 := (100 - send_del_exist_tx) , 1       := (send_del_exist_tx)   };
        
        (send_del==0) -> (data_delay==0);
        solve send_del before data_delay;          
    }


endclass : Tx_transaction
//===================================================================================

