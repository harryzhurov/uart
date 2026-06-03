//-------------------------------------------------------------------------------
//
//     Project: UART RX
//
//     Purpose: Driver
//
//     Author : Matthew S. Grebnev, 2026
//
//-------------------------------------------------------------------------------

`ifndef UART_RX_DRIVER_SVH
`define UART_RX_DRIVER_SVH
//-------------------------------------------------------------------------------

`include "uvm_macros.svh"

import uvm_pkg   ::*;
import params_pkg::*;

//-------------------------------------------------------------------------------
class Driver extends uvm_driver #(UartTrn);

    `uvm_component_utils(Driver)

    virtual inp_if inp;
    UartTrn trn;
    Resp    out_trn;

    uvm_analysis_port #(Resp) trn_port;

    function new(string name, uvm_component parent);
        super.new(name, parent);

        trn_port = new("trn_port", this);
    endfunction

    function void build_phase(uvm_phase phase);
        if( !uvm_config_db #(virtual inp_if)::get(this, "", "inp", inp) ) begin
            `uvm_error("", "get DUT input interface form config_db failed");
        end

    endfunction


    task main_phase(uvm_phase phase);

        fork
            //--------------------------------------------------------
            begin : send_data

                forever begin

                    seq_item_port.get_next_item(trn);

                    int drop_time;

                    #(trn.send_delay*CLK_CYCLE);

                    wait(inp.baud_pulse);
                    ip.rxc = 0;

                    drop_time = $time + trn.drop_rx_del;

                    for(int i=0; i<WORD; i++) begin

                        #(UART_CYCLE);

                        if(trn.drop_rx && ($time >= drop_time)) begin

                            inp.rxc = 1;

                            #(UART_CYCLE*10);
                            break;
                        end

                        inp.rxc = trn.data[i];
                    end

                    #(UART_CYCLE) inp.rxc = trn.stop_bit;

                    #(UART_CYCLE) inp.rxc = 1;

                    out_trn.data        =  trn.data;
                    out_trn.frame_error = !trn.stop_bit;
                    out_trn.overrun     = (inp.rx_complete) ? 1 : 0;
                    out_trn.drop        =  trn.drop_rx;
                    trn_port.write(out_trn);

                    #(UART_CYCLE);

                end
            //--------------------------------------------------------
            begin : send_rden

                forever begin

                    @(trn.rx_rden_en);

                    #(trn.rden_delay*CLK_CYCLE);

                    @(posedge inp.clk) inp.rx_rden = 1;
                    @(posedge inp.clk) inp.rx_rden = 0;

                end
            end
            //--------------------------------------------------------
            begin : reset_errors

                forever begin

                    @(inp.reset_err);
                    @(posedge inp.clk) inp.rst_err = 1;
                    @(posedge inp.clk) inp.rst_err = 0;

                end
            end
            //--------------------------------------------------------
            begin : stop_dirver

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
`endif // UART_RX_DRIVER_SVH


