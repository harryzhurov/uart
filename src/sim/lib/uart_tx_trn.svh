//-------------------------------------------------------------------------------
//
//     Project: UART
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
class UartTxTrn extends uvm_sequence_item;

    static uint16_t       count = 0;
    uint16_t              id;

    rand bit              send_del;
    rand uint16_t         data_delay;
    rand bit [WORD-1:0]   data;

    function new();

        id = ++count;

    endfunction

    constraint data_cnstr
{
    data        inside {[0:255]};

    data         dist  {0 := (zero_data_tx), [1:255] := (100 - zero_data_tx)};

    }

    constraint delay_cnstr
    {
        data_delay inside {[0:send_del_dist_tx]};

        send_del    dist  {0 := (100 - send_del_exist_tx), 1 := (send_del_exist_tx)};

        (send_del==0) -> (data_delay==0);
        solve send_del before data_delay;
    }

endclass
//-------------------------------------------------------------------------------
class UartTxSeq extends uvm_sequence #(UartTxTrn);

    `uvm_object_utils(UartTxSeq)

    UartTxTrn uart_trn;

    uvm_event empty_e;

    int seq_len = 500;

    function new(string name = "seq");
        super.new(name);
    endfunction

    task body;
        int count = 0;
        repeat(seq_len) begin

            uart_trn = new();

            `SV_RAND_CHECK(uart_trn.randomize());

            empty_e.wait_trigger();

            `uvm_send(uart_trn)

            if( (++count)%(seq_len/10) == 0) begin
                $display("[%t], %3d%%", $realtime, count*100/seq_len);
            end
        end
    endtask
endclass
//-------------------------------------------------------------------------------
`endif // UART_TRANSACTION_SVH


