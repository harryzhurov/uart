import params_pkg     ::*;
import trn_cfg_pkg    ::*;
import trn_structs_pkg::*;
package tb_components_pkg;

  `include "transactions.sv"
  `include "generator.sv"
  `include "driver.sv"
  `include "monitor.sv"
  `include "scoreboard.sv"
  `include "environment.sv"

endpackage : tb_components_pkg
