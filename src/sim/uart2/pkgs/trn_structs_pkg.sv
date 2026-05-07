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
    int              rden_delay;
    int              send_delay;
    int              id;
    bit              stop_bit;
} 
rx_trn_t;

typedef struct
{
    int rden_delay;
    int send_delay;
}
mnt_dels_t;
//===================================================================================
endpackage
