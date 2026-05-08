//------------------------------------------------------ 
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

    constraint cst
    {
        data       inside {[0:255             ]};
        rden_delay inside {[0:rden_del_dist_rx]};
        send_delay inside {[0:send_del_dist_rx]};

        stop_bit    dist  {0 := (wrong_stop_exist_rx)     , 1       := (100 - wrong_stop_exist_rx) };
        wrong_rden  dist  {0 := (100 - rden_del_exist_rx) , 1       := (rden_del_exist_rx)         };
        data        dist  {0 := (zero_data_rx)            , [1:255] := (100 - zero_data_rx)        };
        del_send    dist  {0 := (100 - send_del_exist_rx) , 1       := (send_del_exist_rx)         };
        
        (del_send == 0) -> (send_delay==0);
        solve del_send before send_delay;
        (wrong_rden==0) -> (rden_delay==0);
        solve wrong_rden before rden_delay;
    }

endclass : Rx_transaction
