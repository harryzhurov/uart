//-------------------------------------------------------------------------------
//
//     Project: UART Rx
//
//     Purpose: Monitor
//
//     Author : Matthew S. Grebnev, 2026
//
//-------------------------------------------------------------------------------

`ifndef UART_RX_MONITOR_SVH
`define UART_RX_MONITOR_SVH
//-------------------------------------------------------------------------------

`include "uvm_macros.svh"

import uvm_pkg::*;

//-------------------------------------------------------------------------------
class Resp;

    uint8_t  data;
    logic    frame_error;
    logic    drop_trn;

    uint16_t num;

    function new();

    endfunction

    function string compare(Resp resp);

        string msg = "";

        if(data !== resp.data) begin
            msg = $sformatf("ERROR: (scb) : stim data (%x) mismatch with resp data (%x)", data, resp.data);
            return msg;
        end

        if(frame_error !== resp.frame_error) begin
            msg = $sformatf("ERROR: (scb) : stim stop bit (%x) mismatch with resp stop bit (%x)", frame_error, resp.frame_error);

            return msg;
        end

    endfunction

endclass
//-------------------------------------------------------------------------------
class Monitor extends uvm_monitor;

    `uvm_component_utils(Monitor)

    virtual out_if out;

    uint16_t id       = 0;
    uint16_t time_out = 0;

    uvm_analysis_port #(Resp) resp_port;

    uvm_event rx_trn_done;
    uvm_event error_flags;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        resp_port = new("mon_resp_port", this);
    endfunction


    function void build_phase(uvm_phase phase);
        if( !uvm_config_db #(virtual out_if)::get(this, "", "out", out) ) begin
            `uvm_error("", "get DUT output interface from config_db failed");
        end
        if( !uvm_config_db #(uvm_event)::get(this, "", "rx_done", rx_trn_done) ) begin
            `uvm_error("", "get rx_done event form config_db failed");
        end
        if( !uvm_config_db #(uvm_event)::get(this, "", "er_flag", error_flags) ) begin
            `uvm_error("", "get er_flag event form config_db failed");
        end
    endfunction

    task main_phase(uvm_phase phase);

        fork
            //--------------------------------------------------------
            begin : receive_trn

                forever begin

                    Resp resp = new;

                    @(posedge out.rx_complete, posedge out.overrun);

                    resp.data        = out.rx_data;
                    resp.frame_error = out.frame_error;
                    resp.drop_trn    = 0;
                    resp.num         = id;

                    #UART_CYCLE;

                    resp_port.write(resp);
                    ++id;
                    time_out = 50;

                end
            end
            //--------------------------------------------------------
            begin : receive_complete

                forever begin

                    @(posedge out.rx_complete)
                    rx_trn_done.trigger();

                end
            end
            //--------------------------------------------------------
            begin : receive_errors

                forever begin

                    @(posedge out.frame_error, posedge out.overrun);
                    error_flags.trigger();

                end
            end
            //--------------------------------------------------------
            begin : stop_monitor
                forever begin
                    #UART_CYCLE ;
                    if(--time_out == 0) begin
                        break;
                    end
                end
            end
            //--------------------------------------------------------
        join_any
    endtask
    //----------------------------------------------------------------
    function void report_phase(uvm_phase phase);
        $display("[%t], incoming packet count: %0d", $realtime, id);
    endfunction
    //----------------------------------------------------------------

endclass
//-------------------------------------------------------------------------------
`endif // UDP_RX_AGENT_SVH
