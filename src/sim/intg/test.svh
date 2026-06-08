//-------------------------------------------------------------------------------
//
//     Project: UART Rx
//
//     Purpose: Test
//
//     Author : Matthew S. Grebnev, 2026
//
//-------------------------------------------------------------------------------

`ifndef UART_INTG_TEST_SVH
`define UART_INTG_TEST_SVH
//-------------------------------------------------------------------------------

`include "uvm_macros.svh"
`include "scoreboard.svh"
`include "agent_rx.svh"
`include "agent_tx.svh"

`include "simutils.svh"

import uvm_pkg::*;

class UartTest extends uvm_test;

    `uvm_component_utils(UartTest)

    uvm_event empty_e;

    Scoreboard                 scbd;
    Agent_rx                   agn_r;
    Agent_tx                   agn_t;
    uvm_sequencer #(UartRxTrn) seq_rx;
    uvm_sequencer #(UartTxTrn) seq_tx;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        seq_rx = uvm_sequencer #(UartRxTrn)::type_id::create("seq_r", this);
        seq_tx = uvm_sequencer #(UartTxTrn)::type_id::create("seq_t", this);
        scbd   = Scoreboard::type_id::create("scbd",  this);
        agn_r  = Agent_rx  ::type_id::create("agn_r", this);
        agn_t  = Agent_tx  ::type_id::create("agn_t", this);
        empty_e  = new("empty_e");
        uvm_config_db #(uvm_event)::set(this, "agn_t.mon_t", "empty_e", empty_e);
        uvm_config_db #(uvm_event)::set(this, "seq_tx","empty_e", empty_e);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agn_r.drv_r.seq_item_port.connect(seq_rx.seq_item_export);
        agn_t.drv_t.seq_item_port.connect(seq_tx.seq_item_export);
        agn_r.drv_r.trn_port_rx.connect(scbd.stim_port_rx);
        agn_t.drv_t.trn_port_tx.connect(scbd.stim_port_tx);
        agn_r.mon_r.resp_port_rx.connect(scbd.resp_port_rx);
        agn_t.mon_t.resp_port_tx.connect(scbd.resp_port_tx);
    endfunction

    task main_phase(uvm_phase phase);

        UartRxSeq seq_r;
        UartTxSeq seq_t;

        phase.raise_objection(this);

        log_print(">>>>>> UART INTEGRATION TEST START <<<<<<");

        seq_r = UartRxSeq::type_id::create("seq_rx");
        seq_t = UartTxSeq::type_id::create("seq_tx");

        seq_t.empty_e = empty_e;

        fork
            seq_r.start(seq_rx);
            seq_t.start(seq_tx);
        join_any

        wait(scbd.time_out == 0);

        phase.drop_objection(this);
        log_print(">>>>>> UART INTEGRATION TEST FINISH <<<<<<");
    endtask
endclass
//-------------------------------------------------------------------------------
`endif // UART_INTG_TEST_SVH
