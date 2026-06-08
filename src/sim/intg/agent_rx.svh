//-------------------------------------------------------------------------------
//
//     Project: UART AGENT RX
//
//     Purpose: Driver
//
//     Author : Matthew S. Grebnev, 2026
//
//-------------------------------------------------------------------------------

`ifndef UART_RX_AGENT_SVH
`define UART_RX_AGENT_SVH
//-------------------------------------------------------------------------------

`include "uvm_macros.svh"

import uvm_pkg::*;

//-------------------------------------------------------------------------------
class Resp_rx;

    uint8_t  data;
    logic    frame_error;
    logic    drop_trn;

    uint16_t num;

    function new();

    endfunction

    function string compare(Resp_rx resp);

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
class Monitor_rx extends uvm_monitor;

    `uvm_component_utils(Monitor_rx)

    virtual out_if out;

    uint16_t id          = 0;
    uint16_t time_out    = 0;

    uvm_analysis_port #(Resp_rx) resp_port_rx;

    uvm_event rx_trn_done;
    uvm_event error_flags;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        resp_port_rx = new("mon_resp_port_rx", this);
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
            begin : receive_trn_rx

                forever begin

                    Resp_rx resp_rx = new;

                    @(posedge out.rx_complete, posedge out.overrun);

                    resp_rx.data        = out.rx_data;
                    resp_rx.frame_error = out.frame_error;
                    resp_rx.drop_trn    = 0;
                    resp_rx.num         = id;

                    #UART_CYCLE;

                    resp_port_rx.write(resp_rx);
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
class Driver_rx extends uvm_driver #(UartRxTrn);

    `uvm_component_utils(Driver_rx)

    uint16_t time_out;
    uint16_t id = 0;

    virtual inp_if inp;
    virtual out_if out;
    UartRxTrn trn;

    uvm_analysis_port #(Resp_rx) trn_port_rx;

    uvm_event rx_trn_done;
    uvm_event error_flags;

    function new(string name, uvm_component parent);
        super.new(name, parent);

        trn_port_rx = new("trn_port_rx", this);
    endfunction

    function void build_phase(uvm_phase phase);
        if( !uvm_config_db #(virtual inp_if)::get(this, "", "inp", inp) ) begin
            `uvm_error("", "get DUT input interface form config_db failed");
        end
        if( !uvm_config_db #(uvm_event)::get(this, "", "rx_done", rx_trn_done) ) begin
            `uvm_error("", "get rx_done event form config_db failed");
        end
        if( !uvm_config_db #(uvm_event)::get(this, "", "er_flag", error_flags) ) begin
            `uvm_error("", "get er_flag event form config_db failed");
        end
    endfunction


    task main_phase(uvm_phase phase);

        phase.raise_objection(this);

        fork
            //--------------------------------------------------------
            // send_data
            //
            begin

                inp.rxc = 1;

                forever begin

                    int drop_time = 0;

                    Resp_rx out_trn = new();

                    seq_item_port.get_next_item(trn);

                    #(trn.send_delay*CLK_CYCLE);

                    wait(inp.baud_pulse);
                    inp.rxc = 0;

                    drop_time = $time + trn.drop_rx_del;

                    for(int i=0; i<WORD; i++) begin

                        #(UART_CYCLE);

                        if(trn.drop_rx && ($time >= drop_time)) begin

                            inp.rxc = 1;

                            #(UART_CYCLE*10);
                            break;
                        end

                        inp.rxc = trn.data[i];

                        if(i==WORD-1)
                            #(UART_CYCLE) inp.rxc = trn.stop_bit;
                    end



                    #(UART_CYCLE) inp.rxc = 1;

                    out_trn.data        =  trn.data;
                    out_trn.frame_error = !trn.stop_bit;
                    //out_trn.overrun    = ???
                    out_trn.drop_trn    =  trn.drop_rx;
                    out_trn.num         =  id;
                    trn_port_rx.write(out_trn);

                    time_out = 100;

                    ++id;

                    #(UART_CYCLE);

                    seq_item_port.item_done();

                end
            end
            //--------------------------------------------------------
            // send_rden
            //
            begin

                forever begin

                    rx_trn_done.wait_trigger();

                    #(trn.rden_delay*CLK_CYCLE);

                    @(posedge inp.clk) inp.rx_rden = 1;
                    @(posedge inp.clk) inp.rx_rden = 0;

                end
            end
            //--------------------------------------------------------
            // reset_errors
            //
            begin

                forever begin

                    error_flags.wait_trigger();

                    @(posedge inp.clk) inp.rst_err = 1;
                    @(posedge inp.clk) inp.rst_err = 0;

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

        phase.drop_objection(this);
    endtask
endclass
//-------------------------------------------------------------------------------
class Agent_rx extends uvm_agent;

    `uvm_component_utils(Agent_rx)

    uvm_event rx_trn_done;
    uvm_event error_flags;

    Driver_rx                  drv_r;
    Monitor_rx                 mon_r;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        drv_r    = Driver_rx::type_id::create("drv_r", this);
        mon_r    = Monitor_rx::type_id::create("mon_r", this);
        rx_trn_done = new("rx_trn_done");
        error_flags = new("error_flags");
        uvm_config_db #(uvm_event)::set(this, "mon_r", "rx_done", rx_trn_done);
        uvm_config_db #(uvm_event)::set(this, "drv_r", "rx_done", rx_trn_done);
        uvm_config_db #(uvm_event)::set(this, "mon_r", "er_flag", error_flags);
        uvm_config_db #(uvm_event)::set(this, "drv_r", "er_flag", error_flags);
    endfunction

endclass
 //-------------------------------------------------------------------------------
`endif // UART_RX_AGENT_SVH
 //-------------------------------------------------------------------------------
