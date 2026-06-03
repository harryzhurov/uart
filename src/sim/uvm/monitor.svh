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

import uvm_pkg   ::*;
import params_pkg::*;

//-------------------------------------------------------------------------------
class Resp;

    data_t data;
    bit    frame_error;
    bit    overrun;
    bit    drop_trn;

    int    num;

    function new();

    endfunction

    function string compare(Resp resp);

        string msg = "";

        if(data !== resp.data) begin
            msg = $sformatf("ERROR: (scb) : #%0d, stim data (%x) mismatch with resp data (%x)");
            return msg;
        end

        if(frame_error !== resp.frame_error) begin
            msg = $sformatf("ERROR: (scb) : #%0d, stim stop bit (%x) mismatch with resp stop bit (%x)");

            return msg;
        end

        if(overrun !== resp.overrun) begin
            msg = $sformatf("ERROR: (scb) : #%0d, stim overrun (%x) mismatch with resp overrun (%x)");
            return msg;
        end

        return msg;

    endfunction

endclass
//-------------------------------------------------------------------------------
class Monitor extends uvm_monitor;

    `uvm_component_utils(Monitor)

    virtual out_if out;

    int mnt_trn_id = 0;

    uvm_analysis_port #(Resp) resp_port;

    function new(string name, uvm_component parent);
        super.new(name, parent);

        resp_port = new("mon_resp_port", this);
    endfunction


    function void build_phase(uvm_phase phase);
        if( !uvm_config_db #(virtual out_if)::get(this, "", "out", out) ) begin
            `uvm_error("", "get DUT output interface from config_db failed");
        end
    endfunction

    task main_phase(uvm_phase phase);

            int time_out = 0;

            fork
                //--------------------------------------------------------
                begin : receive_trn

                    forever begin
                        Resp resp = new;

                        @(posedge out.rx_complete, posedge out.overrun);

                        resp_port.data        = out.rx_data;
                        resp_port.frame_error = out.frame_error;
                        resp_port.overrun     = out.overrun;
                        resp_port.drop_trn    = 0;

                        #UART_CYCLE;

                        resp_port.write(resp);
                        ++mnt_trn_id;
                        time_out = 20;

                    end
                end
                //--------------------------------------------------------
                begin : receive_complete

                    forever begin

                        @(posedge out.rx_complete)
                        -> out.rx_rden_en;

                    end
                end
                //--------------------------------------------------------
                begin : receive_errors

                    forever begin

                        @(posedge out.frame_error, posedge out.overrun);
                        -> out.reset_err;

                    end
                end
                //--------------------------------------------------------
                begin : stop_monitor

                    #UART_CYCLE;
                    if(--time_out == 0) begin
                        break;
                    end
                end
                //--------------------------------------------------------
            join_any
        end
    endtask
    //----------------------------------------------------------------
    function void report_phase(uvm_phase phase);
        $display("[%t], incoming packet count: %0d", $realtime, incoming_packet_cnt);
    endfunction
    //----------------------------------------------------------------

endclass
//-------------------------------------------------------------------------------
`endif // UDP_RX_AGENT_SVH
