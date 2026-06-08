//-------------------------------------------------------------------------------
//
//     Project: UART TX
//
//     Purpose: Test
//
//     Author : Matthew S. Grebnev, 2026
//
//-------------------------------------------------------------------------------

`ifndef UART_TX_TEST_SVH
`define UART_TX_TEST_SVH
//-------------------------------------------------------------------------------

`include "uvm_macros.svh"
`include "scoreboard.svh"
`include "driver.svh"
`include "monitor.svh"

`include "simutils.svh"

import uvm_pkg::*;

class UartTxTest extends uvm_test;

    `uvm_component_utils(UartTxTest)

    Scoreboard                 scbd;
    uvm_sequencer #(UartTxTrn) seqr;
    Driver                     drv;
    Monitor                    mon;

    uvm_event empty_e;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        scbd  = Scoreboard::type_id::create("scbd", this);
        seqr  = uvm_sequencer #(UartTxTrn)::type_id::create("seqr", this);
        drv   = Driver::type_id::create("drv", this);
        mon   = Monitor::type_id::create("mon", this);
        empty_e = new("empty_e");
        uvm_config_db #(uvm_event)::set(this, "mon", "empty_e", empty_e);
        uvm_config_db #(uvm_event)::set(this, "seqr","empty_e", empty_e);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        drv.seq_item_port.connect(seqr.seq_item_export);
        drv.trn_port.connect(scbd.stim_port);
        mon.resp_port.connect(scbd.resp_port);

    endfunction

    task main_phase(uvm_phase phase);
        UartTxSeq seq;
        phase.raise_objection(this);

        log_print(">>>>>> UART Tx TEST START <<<<<<");

        seq = UartTxSeq::type_id::create("seq");
        seq.empty_e = empty_e;
        seq.start(seqr);

        wait(scbd.time_out == 0) ;

        phase.drop_objection(this);
        log_print(">>>>>> UART Tx TEST FINISH <<<<<<");
    endtask
endclass
//-------------------------------------------------------------------------------
`endif // UART_TX_TEST_SVH


