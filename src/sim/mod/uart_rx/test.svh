//-------------------------------------------------------------------------------
//
//     Project: UART Rx
//
//     Purpose: Test
//
//     Author : Matthew S. Grebnev, 2026
//
//-------------------------------------------------------------------------------

`ifndef UART_RX_TEST_SVH
`define UART_RX_TEST_SVH
//-------------------------------------------------------------------------------

`include "uvm_macros.svh"
`include "scoreboard.svh"
`include "driver.svh"
`include "monitor.svh"

`include "simutils.svh"

import uvm_pkg::*;

class UartRxTest extends uvm_test;

    `uvm_component_utils(UartRxTest)

    uvm_event rx_trn_done;
    uvm_event error_flags;

    Scoreboard               scbd;
    uvm_sequencer #(UartTrn) seqr;
    Driver                   drv;
    Monitor                  mon;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        scbd  = Scoreboard::type_id::create("scbd", this);
        seqr  = uvm_sequencer #(UartTrn)::type_id::create("seqr", this);
        drv   = Driver::type_id::create("drv", this);
        mon   = Monitor::type_id::create("mon", this);
        rx_trn_done = new("rx_trn_done");
        error_flags = new("error_flags");
        uvm_config_db #(uvm_event)::set(this, "mon", "rx_done", rx_trn_done);
        uvm_config_db #(uvm_event)::set(this, "drv", "rx_done", rx_trn_done);
        uvm_config_db #(uvm_event)::set(this, "mon", "er_flag", error_flags);
        uvm_config_db #(uvm_event)::set(this, "drv", "er_flag", error_flags);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        drv.seq_item_port.connect(seqr.seq_item_export);
        drv.trn_port.connect(scbd.stim_port);
        mon.resp_port.connect(scbd.resp_port);

    endfunction

    task main_phase(uvm_phase phase);
        UartRxSeq seq;
        phase.raise_objection(this);

        log_print(">>>>>> UART Rx TEST START <<<<<<");

        seq = UartRxSeq::type_id::create("seq");
        seq.start(seqr);

        wait(scbd.time_out == 0) ;

        phase.drop_objection(this);
        log_print(">>>>>> UART Rx TEST FINISH <<<<<<");
    endtask
endclass
//-------------------------------------------------------------------------------
`endif // UART_RX_TEST_SVH


