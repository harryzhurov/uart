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
`include "driver_rx.svh"
`include "driver_tx.svh"
`include "monitor.svh"

`include "simutils.svh"

import uvm_pkg::*;

class UartTest extends uvm_test;

    `uvm_component_utils(UartTest)

    uvm_event rx_trn_done;
    uvm_event error_flags;
    uvm_event empty_e;

    Scoreboard                 scbd;
    uvm_sequencer #(UartRxTrn) seqr_rx;
    uvm_sequencer #(UartTxTrn) seqr_tx;
    Driver_rx                  drv_r;
    Driver_tx                  drv_t;
    Monitor                    mon;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        scbd     = Scoreboard::type_id::create("scbd", this);
        seqr_rx  = uvm_sequencer #(UartRxTrn)::type_id::create("seqr_rx", this);
        seqr_tx  = uvm_sequencer #(UartTxTrn)::type_id::create("seqr_tx", this);
        drv_r    = Driver_rx::type_id::create("drv_r", this);
        drv_t    = Driver_tx::type_id::create("drv_t", this);
        mon      = Monitor::type_id::create("mon", this);
        rx_trn_done = new("rx_trn_done");
        error_flags = new("error_flags");
        empty_e     = new("empty_e");
        uvm_config_db #(uvm_event)::set(this, "mon",   "rx_done", rx_trn_done);
        uvm_config_db #(uvm_event)::set(this, "drv_r", "rx_done", rx_trn_done);
        uvm_config_db #(uvm_event)::set(this, "mon",   "er_flag", error_flags);
        uvm_config_db #(uvm_event)::set(this, "drv_r", "er_flag", error_flags);
        uvm_config_db #(uvm_event)::set(this, "mon", "empty_e", empty_e);
        uvm_config_db #(uvm_event)::set(this, "seqr_tx","empty_e", empty_e);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        drv_r.seq_item_port.connect(seqr_rx.seq_item_export);
        drv_t.seq_item_port.connect(seqr_tx.seq_item_export);
        drv_r.trn_port_rx.connect(scbd.stim_port_rx);
        drv_t.trn_port_tx.connect(scbd.stim_port_tx);
        mon.resp_port_rx.connect(scbd.resp_port_rx);
        mon.resp_port_tx.connect(scbd.resp_port_tx);

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
            seq_r.start(seqr_rx);
            seq_t.start(seqr_tx);
        join_any

        wait(scbd.time_out == 0);

        phase.drop_objection(this);
        log_print(">>>>>> UART INTEGRATION TEST FINISH <<<<<<");
    endtask
endclass
//-------------------------------------------------------------------------------
`endif // UART_INTG_TEST_SVH


