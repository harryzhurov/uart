//-------------------------------------------------------------------------------
//
//     Project: UART AGENT TX
//
//     Purpose: Driver
//
//     Author : Matthew S. Grebnev, 2026
//
//-------------------------------------------------------------------------------

`ifndef UART_TX_AGENT_SVH
`define UART_TX_AGENT_SVH
//-------------------------------------------------------------------------------

`include "uvm_macros.svh"

import uvm_pkg::*;

//-------------------------------------------------------------------------------
class Resp_tx;

    uint8_t  data;
    uint16_t num;

    function new();

    endfunction

    function string compare(Resp_tx resp);

        string msg = "";

        if(data !== resp.data) begin
            msg = $sformatf("ERROR: (scb) : stim data (%x) mismatch with resp data (%x)", data, resp.data);
            return msg;
        end

    endfunction

endclass
//-------------------------------------------------------------------------------
class Monitor_tx extends uvm_monitor;

    `uvm_component_utils(Monitor_tx)

    virtual uart_if pld;

    uint8_t  tx_data_pre = 0;
    uint16_t id          = 0;
    uint16_t time_out    = 0;

    uvm_analysis_port #(Resp_tx) resp_port_tx;

    uvm_event empty_e;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        resp_port_tx = new("mon_resp_port_tx", this);
    endfunction


    function void build_phase(uvm_phase phase);
        if( !uvm_config_db #(virtual uart_if)::get(this, "", "pld", pld) ) begin
            `uvm_error("", "get DUT output interface from config_db failed");
        end
        if( !uvm_config_db #(uvm_event)::get(this, "", "empty_e", empty_e) ) begin
            `uvm_error("", "get tx_empty_event from config_db failed");
        end
    endfunction

    task main_phase(uvm_phase phase);

        fork
            //--------------------------------------------------------
            begin : receive_trn_tx

                forever begin

                    Resp_tx resp_tx = new;

                    @(negedge pld.txc);

                    #(UART_CYCLE+UART_CYCLE/2);

                    for(int i = 0; i < WORD; i++) begin
                        tx_data_pre = {tx_data_pre[WORD-2:0],pld.txc};
                        #UART_CYCLE;
                    end

                    resp_tx.data = tx_data_pre;
                    resp_tx.num  = id;

                    resp_port_tx.write(resp_tx);
                    ++id;
                    time_out = 50;

                end
            end
            //--------------------------------------------------------
            begin : trigg_tx_empty
                forever begin
                    #(CLK_CYCLE);
                    if(pld.tx_empty) begin
                        empty_e.trigger();
                    end
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
class Driver_tx extends uvm_driver #(UartTxTrn);

    `uvm_component_utils(Driver_tx)

    uint16_t time_out;
    uint16_t id = 0;

    virtual uart_if pld;
    virtual clk_if cv;

    UartTxTrn trn;

    uvm_analysis_port #(Resp_tx) trn_port_tx;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        trn_port_tx = new("trn_port_tx", this);
    endfunction

    function void build_phase(uvm_phase phase);
        if( !uvm_config_db #(virtual uart_if)::get(this, "", "pld", pld) ) begin
            `uvm_error("", "get DUT input interface form config_db failed");
        end
        if( !uvm_config_db #(virtual clk_if)::get(this, "", "cv", cv) ) begin
            `uvm_error("", "get TB clk interface form config_db failed");
        end
    endfunction


    task main_phase(uvm_phase phase);

        fork
            //--------------------------------------------------------
            // send_data
            //
            begin

                forever begin

                    Resp_tx out_trn = new();

                    seq_item_port.get_next_item(trn);

                    #(trn.data_delay*CLK_CYCLE);

                    pld.tx_data = trn.data;

                    @(posedge cv.clk) pld.tx_wren = 1;
                    @(posedge cv.clk) pld.tx_wren = 0;

                    out_trn.data = trn.data;
                    out_trn.num  = id;

                    #20ns;

                    out_trn.data =  trn.data;
                    out_trn.num  =  id;
                    trn_port_tx.write(out_trn);

                    time_out = 100;

                    ++id;

                    seq_item_port.item_done();

                end
            end
            //--------------------------------------------------------
            begin : stop_driver

                forever begin

                    #UART_CYCLE;
                    if(--time_out == 0) begin
                        break;
                    end
                end
            end
            //--------------------------------------------------------
        join_any

    endtask
endclass
//-------------------------------------------------------------------------------
class Agent_tx extends uvm_agent;

    `uvm_component_utils(Agent_tx)

    Driver_tx                  drv_t;
    Monitor_tx                 mon_t;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        drv_t    = Driver_tx ::type_id::create("drv_t", this);
        mon_t    = Monitor_tx::type_id::create("mon_t", this);
    endfunction

endclass
 //-------------------------------------------------------------------------------
`endif // UART_TX_AGENT_SVH
 //-------------------------------------------------------------------------------
