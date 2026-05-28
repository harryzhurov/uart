//==================================================
class driver extends uvm_driver #(transaction);
//==================================================
    `uvm_component_utils(driver)
    
    seq_item s_item;
    
    virtual dut_if vif;
    
    function new (tring name = "driver", uvm_component parent = uvm_driver;
        super.new(name, parent);
        //`uvm_info("driver",  $sformatf("%s consturted", name), UVM_LOW);
    endfunction
    
    function void build_phase (uvm_phase phase);
        super.build_pase(phase);
        if(!uvm_config_db#(virtual dut_if)::get(this,"","vif",vif))
            `uvm_datal("NOVIF", {"virtual interface must be set for: ",get_full_name(), "vif"});
    endfunction : build_phase
    
    virtual task run_phase (uvm_phase phase);
        forever begin
            seq_item_port.get_next_item(req);
            repeat (req.send_delay) @(posedge vif.clk);
            drive_transaction(req);
            seq_item_port.item_done();
        end
    endtask : run
    
    task drive_transaction (transaction trn);

        @(posedge vif.baud_pulse);
        
        vif.rxc = 0;
        
        int drop_time = $time + trn.drop_rx_del;
        
        for(int i=0; i<WORD; i++) begin

            #(UART_CYCLE);

            if(trn.drop_rx && ($time >= drop_time)) begin

                vif.rxc = 1;

                #(UART_CYCLE*10);
                return;
            end

            vif.rxc = trn.data[i];
        end

        #(UART_CYCLE) vif.rxc = trn.stop_bit;

        #(UART_CYCLE) vif.rxc = 1;
        #(UART_CYCLE);

    endtask : drive_transaction
    
    task rx_rden_send();

        forever begin

            @(vif.rx_rden_en);

            #(trn.rden_delay*CLK_CYCLE);

            @(posedge vif.clk) vif.rx_rden = 1;
            @(posedge vif.clk) vif.rx_rden = 0;

        end

    endtask : rx_rden_send
    
    task reset_error();
        forever begin
            @(vif.reset_err);
            @(posedge vif.clk) vif.rst_err = 1;
            @(posedge vif.clk) vif.rst_err = 0;
        end
    endtask : reset_error
//==================================================
endclass : driver
//==================================================
