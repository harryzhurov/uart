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
    int              id;
} 
tx_trn_t;

typedef struct
{
    logic [WORD-1:0] data;
    int              id;
}
tx_pak_t;

typedef logic [WORD-1:0] data_t;
//===================================================================================
endpackage
