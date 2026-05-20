//===================================================================================
package trn_structs_pkg;
//===================================================================================
//
//      Structs
//

import params_pkg::*;

typedef struct 
{ 
    logic [WORD-1:0] data;
    int              data_delay;  
    bit              drop_tx;
    int              drop_tx_del;
    int              id;
} 
tx_trn_t;

typedef logic [WORD-1:0] data_t;
//===================================================================================
endpackage
