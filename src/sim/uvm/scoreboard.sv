//==================================================
class scoreboard extends uvm_scoreboard;
//==================================================
    `uvm_component_utils(scoreboard)

    uvm_analysis_export #(in_transaction ) drv2scb;
    uvm_analysis_export #(out_transaction) mnt2scb;
    
    uvm_tlm_analysis_fifo #(in_transaction ) drv2scb_fifo;
    uvm_tlm_analysis_fifo #(out_transaction) mnt2scb_fifo;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    function void build_phase (uvm_phase phase);
        drv2scb_fifo = new("drv2scb_fifo", this);
        mnt2scb_fifo = new("mnt2scb_fifo", this);
        drv2scb      = new("drv2scb"     , this);
        mnt2scb      = new("mnt2scb"     , this);
    endfunction
    
    function void connect_phase(uvm_phase phase);
        drv2scb.connect(drv2scb_fifo.analysis_export);
        mnt2scb.connect(mnt2scb_fifo.analysis_export);
    endfunction

    task run_phase(uvm_phase phase);

        string s;

        in_transaction  in_trn;
        out_transaction out_trn;

        forever begin
            drv2scb_fifo.get(in_trn);
            mnt2scb_fifo.get(out_trn);

            if (drv2scb.data != mnt2scb.data) begin
                uvm_report_error("Comparator Mismatch",
                    $sformatf("0x%0h does not match 0x%0h",
                        in_trn.data,
                        out_trn.data));
            end
        end
    endtask : run
//==================================================
endclass : scoreboard
//==================================================
