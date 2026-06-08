//-------------------------------------------------------------------------------
//
//     Project: UART Rx
//
//     Purpose: Scoreboard
//
//     Author : Matthew S. Grebnev, 2026
//
//-------------------------------------------------------------------------------

`ifndef UART_INTG_SCOREBOARD_SVH
`define UART_INTG_SCOREBOARD_SVH
//-------------------------------------------------------------------------------

`include "uvm_macros.svh"
`include "uart_rx_trn.svh"
`include "uart_tx_trn.svh"
`include "agent_rx.svh"
`include "agent_tx.svh"
`include "simutils.svh"

import uvm_pkg::*;

class Scoreboard extends uvm_component;

    `uvm_component_utils(Scoreboard)

    `uvm_analysis_imp_decl(_stim_rx)
    `uvm_analysis_imp_decl(_resp_rx)
    `uvm_analysis_imp_decl(_stim_tx)
    `uvm_analysis_imp_decl(_resp_tx)

    uvm_analysis_imp_stim_rx #(Resp_rx,Scoreboard) stim_port_rx;
    uvm_analysis_imp_stim_tx #(Resp_tx,Scoreboard) stim_port_tx;
    uvm_analysis_imp_resp_rx #(Resp_rx,Scoreboard) resp_port_rx;
    uvm_analysis_imp_resp_tx #(Resp_tx,Scoreboard) resp_port_tx;

    Resp_rx stim_q_r[$];
    Resp_tx stim_q_t[$];
    Resp_rx resp_q_r[$];
    Resp_tx resp_q_t[$];

    uint8_t        reverse_data;
    uint32_t       stim_pkt_count;
    uint32_t       resp_pkt_count;
    const uint16_t TIMEOUT  = 100;
    uint16_t       time_out = TIMEOUT;

    //----------------------------------------------------------------
    function new(string name, uvm_component parent);
        super.new(name, parent);

        stim_port_rx = new("stim_port_rx", this);
        stim_port_tx = new("stim_port_tx", this);
        resp_port_rx = new("resp_port_rx", this);
        resp_port_tx = new("resp_port_tx", this);

        stim_pkt_count = 0;
    endfunction
    //---------------------------------s-------------------------------
    function void write_stim_rx(Resp_rx stim);
        time_out = TIMEOUT;
        ++stim_pkt_count;

        for(int i=0; i<WORD; i++) begin
            reverse_data[i] = stim.data[WORD-1-i];
        end

        stim.data = reverse_data;

        stim_q_r.push_back(stim);
    endfunction
    //---------------------------------s-------------------------------
    function void write_stim_tx(Resp_tx stim);
        time_out = TIMEOUT;
        ++stim_pkt_count;
        stim_q_t.push_back(stim);
    endfunction
    //----------------------------------------------------------------
    function void write_resp_rx(Resp_rx resp);
        time_out = TIMEOUT;
        ++stim_pkt_count;
        resp_q_r.push_back(resp);
    endfunction
    //----------------------------------------------------------------
    function void write_resp_tx(Resp_tx resp);
        time_out = TIMEOUT;
        ++resp_pkt_count;
        resp_q_t.push_back(resp);
    endfunction
    //----------------------------------------------------------------
    task main_phase(uvm_phase phase);

        forever begin
            #UART_CYCLE;
            if(--time_out == 0) begin
                $display("\n[%t], Scoreboard Responce Port timeout expired\n", $realtime);
                break;
            end
        end
    endtask
    //----------------------------------------------------------------
    function void check_phase(uvm_phase phase);

        string err_msg = "";

        $display("[%t], stim_q_r.size: %0h", $realtime, stim_q_r.size());
        $display("[%t], resp_q_r.size: %0h", $realtime, resp_q_r.size());
        $display("[%t], stim_q_t.size: %0h", $realtime, stim_q_t.size());
        $display("[%t], resp_q_t.size: %0h", $realtime, resp_q_t.size());

        if(!stim_q_r.size() | !stim_q_t.size()) begin
            err_msg = $sformatf("ERROR: no valid stimulus");
        end
        else if((stim_q_r.size() != resp_q_r.size()) | (stim_q_t.size() != resp_q_t.size())) begin
            err_msg = $sformatf("ERROR: stimulus item count [%0d] not equeal responce item count [%0d]",
                               stim_q_r.size(),
                               resp_q_r.size(),
                               stim_q_t.size(),
                               resp_q_t.size());
        end
        else begin
            while(stim_q_r.size()) begin

                Resp_rx stim = stim_q_r.pop_front();
                Resp_rx resp = resp_q_r.pop_front();

                //$display("[%t], stim: %p", $realtime, stim);
                //$display("[%t], resp: %p", $realtime, resp);

                if(!stim.drop_trn) begin
                    err_msg = stim.compare(resp);
                    if(err_msg) begin
                        break;
                    end
                end
            end
            while(stim_q_t.size()) begin

                Resp_tx stim = stim_q_t.pop_front();
                Resp_tx resp = resp_q_t.pop_front();

                //$display("[%t], stim: %p", $realtime, stim);
                //$display("[%t], resp: %p", $realtime, resp);

                err_msg = stim.compare(resp);
                if(err_msg) begin
                    break;
                end
            end
        end

        if(err_msg) begin
            log_print(err_msg, colorRED);
            //log_print(err_msg, colorRED);

            $display("\n");
            log_print("****** TEST FAILED ******", colorRED);
            //log_print("****** TEST FAILED ******", colorRED);
            $display("\n");
            raise_sim_fatal_error();
        end

        $display("\n");
        log_print("****** TEST PASSED ******",colorGREEN);
        //log_print("****** TEST PASSED ******", colorGREEN);
        $display("\n");

    endfunction
    //----------------------------------------------------------------

endclass
//-------------------------------------------------------------------------------
`endif // UART_INTG_SCOREBOARD_SVH


