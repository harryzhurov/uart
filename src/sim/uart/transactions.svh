//===================================================================================
class Rx_transaction;

    static int          count = 0;
    int                 id;
               
    rand bit            stop_bit;
    rand bit            wrong_rden;
    rand bit            del_send;
    rand int            send_delay;
    rand int            rden_delay;
    rand bit [WORD-1:0] data;

    function new();
        
        id = count++;
        
    endfunction

    constraint data_cnstr
    {
        data       inside {[0:255]};

        stop_bit    dist  {0 := (wrong_stop_exist_rx), 1       := (100 - wrong_stop_exist_rx)};
        data        dist  {0 := (zero_data_rx)       , [1:255] := (100 - zero_data_rx)       };

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
    rand int            data_delay;
    rand bit [WORD-1:0] data;

    function new();

        id = count++;

    endfunction

    constraint cst
    {
        data       inside {[0:255             ]};
        data_delay inside {[0:send_del_dist_tx]};

        data        dist  {0 := (zero_data_tx)           , [1:255] := (100 - zero_data_tx)};
        send_del    dist  {0 := (100 - send_del_exist_tx), 1       := (send_del_exist_tx) };

        (send_del==0) -> (data_delay==0);
        solve send_del before data_delay;
    }


endclass : Tx_transaction
//===================================================================================


