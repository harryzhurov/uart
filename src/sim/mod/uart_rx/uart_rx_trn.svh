//-------------------------------------------------------------------------------
//
//     Project: UART_Rx
//
//     Purpose: Transactions. UVM Sequence Items and UVM Sequence
//
//     Author : Matthew S. Grebnev, 2026
//
//-------------------------------------------------------------------------------

`ifndef UART_TRANSACTION_SVH
`define UART_TRANSACTION_SVH
//-------------------------------------------------------------------------------

`include "uvm_macros.svh"
`include "common.svh"

import uvm_pkg::*;
import uart_params_pkg::*;

//-------------------------------------------------------------------------------
class UartTrn extends uvm_sequence_item;

    static uint16_t       count = 0;
    uint16_t              id;

    rand   bit            stop_bit;
    rand   bit            wrong_rden;
    rand   bit            del_send;
    rand   bit            drop_rx;
    rand   uint16_t       send_delay;
    rand   uint16_t       rden_delay;
    rand   uint16_t       drop_rx_del;
    rand   uint8_t        data;

    function new();

        id = ++count;

    endfunction

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

endclass
//-------------------------------------------------------------------------------
class UartRxSeq extends uvm_sequence #(UartTrn);

    `uvm_object_utils(UartRxSeq)

    UartTrn uart_trn;

    int seq_len = 2000;

    function new(string name = "uart rx seq");
        super.new(name);
    endfunction

    task body;
        int count = 0;
        repeat(seq_len) begin

            uart_trn = new();

            `SV_RAND_CHECK(uart_trn.randomize());

            `uvm_send(uart_trn)

            if( (++count)%(seq_len/10) == 0) begin
                $display("[%t], %3d%%", $realtime, count*100/seq_len);
            end
        end
    endtask
endclass

//-------------------------------------------------------------------------------
`endif // UART_TRANSACTION_SVH


