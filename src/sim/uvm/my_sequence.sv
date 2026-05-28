//==================================================
class my_sequence extends uvm_sequence #(transaction);
//==================================================

    `uvm_object_utils(my_sequence)

    function new(string name = "my_sequence");
        super.new(name);
    endfunction

    virtual task body();
        transaction trn;
        repeat (trn_cfg_pkg::rx_num_test) begin
            trn = my_transaction::type_id::create("trn");
            if (!trn.randomize())
                `uvm_error("SEQ", "Randomization failed");
            start_item(trn);
            finish_item(trn);
        end
    endtask
//==================================================
endclass : my_sequence
//==================================================
