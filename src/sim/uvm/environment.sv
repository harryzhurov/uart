//==================================================
class environment extends uvm_env;
//==================================================
    `uvm_component_utils(environment)
    
    driver     drv;
    monitor    mnt;
    scoreboard scb;
    sequencer  seq;
  
    function new(string name, uvm_component parent);
        super.new(name,parent);
    endfunction


    function void build_phase(uvm_phase phase);
        super.buid_phase(phase);
        drv = driver    ::type_id::create("drv", this);
        mnt = monitor   ::type_id::create("mnt", this);
        scb = scoreboard::type_id::create("scb", this);
        seq = sequancer ::type_id::create("seq", this);
    endfunction: build_phase

    function void connect_phase(uvm_phase phase);
        drv.seq_item_port.connect(seq.seq_item_export);
        mnt.out_port.connect(seq.seq_item_export);
    endfunction: connect_phase
//==================================================
endclass
//==================================================
