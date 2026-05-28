//==================================================
class in_transaction extends uvm_sequence_item;
//==================================================
  `uvm_object_utils(in_transaction)

    logic               rx_rden;

    rand bit [WORD-1:0] data;
    rand bit            stop_bit;
    rand bit            wrong_rden;
    rand bit            del_send;
    rand bit            drop_rx;
    rand int            send_delay;
    rand int            rden_delay;
    rand int            drop_rx_del;
    
    constraint data_cnstr
    {
        data        inside {[0:255]};
        drop_rx_del inside {[0:0],[UART_CYCLE:UART_CYCLE*8]};

        stop_bit    dist  {0 := (wrong_stop_exist_rx), 1       := (100 - wrong_stop_exist_rx)};
        data        dist  {0 := (zero_data_rx)       , [1:255] := (100 - zero_data_rx)       };
        drop_rx     dist  {0 := (100 - drop_rx_trn)  , 1       := (drop_rx_trn)              };

        (drop_rx==0) -> (drop_rx_del==0);
        (drop_rx==1) -> (drop_rx_del!=0);
        solve drop_rx before drop_rx_del;

    }

    constraint delay_cnstr
    {

        rden_delay inside {[0:rden_del_dist_rx]};
        send_delay inside {[0:send_del_dist_rx]};

        wrong_rden  dist  {0 := (100 - rden_del_exist_rx), 1 := (rden_del_exist_rx)};
        del_send    dist  {0 := (100 - send_del_exist_rx), 1 := (send_del_exist_rx)};

        (del_send == 0) -> (send_delay==0);
        solve del_send before send_delay;
        (wrong_rden==0) -> (rden_delay==0);
        solve wrong_rden before rden_delay;

    }

    function new(string name = "in_transaction");
        super.new(name);
    endfunction
//==================================================
endclass
//==================================================

//==================================================
class out_transaction extends uvm_sequence_item;
//==================================================
    `uvm_object_utils(out_transaction)

    logic [WORD-1:0] rx_data;
    logic            rx_complete;
    logic            frame_error;
    logic            overrun;
    
    function new (string name = "out_transaction");
        super.new(name);
    endfunction
//==================================================
endclass : out_transaction
//==================================================
