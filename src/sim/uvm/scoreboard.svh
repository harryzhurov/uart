//-------------------------------------------------------------------------------
//
//     Project: UART Rx
//
//     Purpose: Scoreboard
//
//     Author : Matthew S. Grebnev, 2026
//
//-------------------------------------------------------------------------------

`ifndef UART_RX_SCOREBOARD_SVH
`define UART_RX_SCOREBOARD_SVH
//-------------------------------------------------------------------------------

`include "uvm_macros.svh"
`include "uart_rx_trn.svh"
`include "monitor.svh"

import uvm_pkg    ::*;
import params_pkkg::*;

class Scoreboard extends uvm_component;

    `uvm_component_utils(Scoreboard)

    `uvm_analysis_imp_decl(_stim)
    `uvm_analysis_imp_decl(_resp)

    uvm_analysis_imp_stim #(UartTrn, Scoreboard) stim_port;
    uvm_analysis_imp_resp #(Resp,    Scoreboard) resp_port;

    Resp stim_q[$];                                                       
    Resp resp_q[$];

    int  stim_pkt_count;
    int  time_out;

    //----------------------------------------------------------------
    function new(string name, uvm_component parent);
        super.new(name, parent);

        stim_port = new("stim_port", this);
        resp_port = new("resp_port", this);

        stim_pkt_count = 0;
    endfunction
    //----------------------------------------------------------------
    function void write_stim(UartTrn trn);
        time_out = 25;
        ++stim_pkt_count;
        stim_q.push_back(stim);
    endfunction
    //----------------------------------------------------------------
    function void write_resp(Resp resp);
        resp_q.push_back(resp);
    endfunction
    //----------------------------------------------------------------
    task main_phase(uvm_phase phase);

        forever begin
            #UART_CYCLE;
            if(--wdt == 0) begin
                $display("\n[%t], Scoreboard Responce Port timeout expired\n", $realtime);
                break;
            end
        end
    endtask
    //----------------------------------------------------------------
    function void check_phase(uvm_phase phase);

        string err_msg = "";

        $display("[%t], stim_q.size: %0d", $realtime, stim_q.size());
        $display("[%t], resp_q.size: %0d", $realtime, resp_q.size());

        if(!stim_q.size()) begin
            err_msg = $sformatf("ERROR: no valid stimulus");
        end
        else if(stim_q.size() != resp_q.size()) begin
            err_msg = $sformatf("ERROR: stimulus item count [%0d] not equeal responce item count [%0d]",
                               stim_q.size(),
                               resp_q.size());
        end
        else begin
            while(stim_q.size()) begin
                Resp stim = stim_q.pop_front();
                Resp resp = resp_q.pop_front();

//              $display("[%t], stim: %p", $realtime, stim);
//              $display("[%t], resp: %p", $realtime, resp);

                err_msg = stim.compare(resp);
                if(err_msg) begin
                    break;
                end
            end
        end

        if(err_msg) begin
            log_print(err_msg, colorRED);

            $display("\n");
            log_print("****** TEST FAILED ******", colorRED);
            $display("\n");
            raise_sim_fatal_error();
        end

        $display("\n");
        log_print("****** TEST PASSED ******", colorGREEN);
        $display("\n");

    endfunction
    //----------------------------------------------------------------

endclass
//-------------------------------------------------------------------------------
`endif // UART_RX_SCOREBOARD_SVH


