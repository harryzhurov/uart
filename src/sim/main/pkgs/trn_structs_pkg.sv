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

typedef struct 
{ 
    logic [WORD-1:0] data;
    int              rden_delay;
    int              send_delay;
    int              id;
    bit              stop_bit;
    bit              drop_rx;
    int              drop_rx_del;
} 
rx_trn_t;

typedef struct
{
    int rden_delay;
    int send_delay;
}
mnt_dels_t;

typedef struct
{

    logic [WORD-1:0] data;
    bit              frame_error;
    bit              overrun;

}
mnt_rcvd_t;

typedef logic [WORD-1:0] data_t;
//===================================================================================
endpackage
//===================================================================================
