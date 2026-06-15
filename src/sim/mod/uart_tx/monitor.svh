//-------------------------------------------------------------------------------
//
//     Project: UART TX
//
//     Purpose: Monitor
//
//     Author : Matthew S. Grebnev, 2026
//
//-------------------------------------------------------------------------------

`ifndef UART_TX_MONITOR_SVH
`define UART_TX_MONITOR_SVH
//-------------------------------------------------------------------------------

`include "uvm_macros.svh"

import uvm_pkg::*;

//-------------------------------------------------------------------------------
class Resp;

    uint8_t  data;
    uint16_t num;

    function new();

    endfunction

    function string compare(Resp resp);

        string msg = "";

        if(data !== resp.data) begin
            msg = $sformatf("ERROR: (scb) : stim data (%x) mismatch with resp data (%x)", data, resp.data);
            return msg;
        end

    endfunction

endclass
//-------------------------------------------------------------------------------
class Monitor extends uvm_monitor;

    `uvm_component_utils(Monitor)

    virtual out_if out;

    uint8_t  tx_data_pre = 0;
    uint16_t id          = 0;
    uint16_t time_out    = 0;

    uvm_analysis_port #(Resp) resp_port;

    uvm_event empty_e;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        resp_port = new("mon_resp_port", this);
    endfunction


    function void build_phase(uvm_phase phase);
        if( !uvm_config_db #(virtual out_if)::get(this, "", "out", out) ) begin
            `uvm_error("", "get DUT output interface from config_db failed");
        end
        if( !uvm_config_db #(uvm_event)::get(this, "", "empty_e", empty_e) ) begin
            `uvm_error("", "get tx_empty_event from config_db failed");
        end
    endfunction

    task main_phase(uvm_phase phase);

        phase.raise_objection(this);

        fork
            //--------------------------------------------------------
            begin : receive_trn

                forever begin

                    Resp resp = new;

                    @(negedge out.txc);

                    #(UART_CYCLE+UART_CYCLE/2);

                    for(int i = 0; i < WORD; i++) begin
                        tx_data_pre = {tx_data_pre[WORD-2:0],out.txc};
                        #UART_CYCLE;
                    end

                    resp.data = tx_data_pre;
                    resp.num  = id;

                    resp_port.write(resp);
                    ++id;
                    time_out = 50;

                end
            end
            //--------------------------------------------------------
            begin : trigg_tx_empty
                forever begin
                    #(CLK_CYCLE);
                    if(out.tx_empty) begin
                        empty_e.trigger();
                    end
                end
            end
            //--------------------------------------------------------
            begin : stop_monitor
                forever begin
                    #UART_CYCLE ;
                    if(--time_out) begin
                        break;
                    end
                end
            end
            //--------------------------------------------------------

        join_any

        phase.drop_objection(this);

    endtask
    //----------------------------------------------------------------
    function void report_phase(uvm_phase phase);
        $display("[%t], incoming packet count: %0d", $realtime, id);
    endfunction
    //----------------------------------------------------------------

endclass
//-------------------------------------------------------------------------------
`endif // UDP_TX_MONITOR_SVH
