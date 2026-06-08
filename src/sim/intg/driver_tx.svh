//-------------------------------------------------------------------------------
//
//     Project: UART TX
//
//     Purpose: Driver
//
//     Author : Matthew S. Grebnev, 2026
//
//-------------------------------------------------------------------------------

`ifndef UART_TX_DRIVER_SVH
`define UART_TX_DRIVER_SVH
//-------------------------------------------------------------------------------

`include "uvm_macros.svh"

import uvm_pkg::*;

//-------------------------------------------------------------------------------
class Driver_tx extends uvm_driver #(UartTxTrn);

    `uvm_component_utils(Driver_tx)

    uint16_t time_out;
    uint16_t id = 0;

    virtual inp_if inp;

    UartTxTrn trn;

    uvm_analysis_port #(Resp_tx) trn_port_tx;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        trn_port_tx = new("trn_port_tx", this);
    endfunction

    function void build_phase(uvm_phase phase);
        if( !uvm_config_db #(virtual inp_if)::get(this, "", "inp", inp) ) begin
            `uvm_error("", "get DUT input interface form config_db failed");
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

                    inp.tx_data = trn.data;

                    @(posedge inp.clk) inp.tx_wren = 1;
                    @(posedge inp.clk) inp.tx_wren = 0;

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
`endif // UART_TX_DRIVER_SVH



