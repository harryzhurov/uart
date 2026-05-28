//==================================================
class monitor extends uvm_monitor;
//==================================================
    `uvm_component_utils(monitor)

    virtual dut_if vif;
    
    uvm_analysis_port#(out_transaction) item_collected_port;
    
    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new
    
    function void build_phase (uvm_phase phase);
        super.build_phase(phase);
        item_collected_port = new("item_collected_port", this);
    endfunction
    
    function void connect_phase (uvm_phase phase);
        super.connect_phase(phase);
    endfunction

    virtual task run_phase(uvm_phase phase);
        collect_transactions();
    endtask : run

    virtual protected task collect_transactions();
        forever begin
            @(posedge vif.rx_complete, posedge vif.overrun);
            
            out_transaction trn = out_transaction::type_id::create("trn");
            
            trn.rx_data     = vif.rx_data;
            trn.rx_complete = vif.rx_complete;
            trn.overrun     = vif.overrun;
            trn.frame_error = vif.frame_error;

            item_collected_port.write(trn);
        end
    endtask : collect_transactions
//==================================================
endclass : monitor
//==================================================
