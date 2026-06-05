//******************************************************************************
//*
//*      Project:     Any
//*
//*      Description: Common code definitions file
//*
//*      Version 2.0
//*
//*      Copyright (c) 2008-2024, Harry E. Zhurov
//*
//------------------------------------------------------------------------------

`ifndef COMMON_SVH
`define COMMON_SVH

//------------------------------------------------------------------------------
package common;

//------------------------------------------------------------------------------
    
typedef int unsigned uint;    
    
typedef byte     unsigned uint8_t;
typedef shortint unsigned uint16_t;
typedef int      unsigned uint32_t;
typedef longint  unsigned uint64_t;

//------------------------------------------------------------------------------
function automatic int clog2 (input int n); // this function calculates ceil(log2(n))
begin
    int num = n;
    int res;
    num = num - 1;                          // without this statement clog2(32) will be 6 but must be 5
    for (res = 0; num > 0; res = res + 1)
        num = num >> 1;

    return res;
end
endfunction
//------------------------------------------------------------------------------
function automatic int max(input int x, input int y);
    return x > y ? x : y;
endfunction
//------------------------------------------------------------------------------
function automatic int min(input int x, input int y);
    return x < y ? x : y;
endfunction
//------------------------------------------------------------------------------
function automatic int bits(input int x);
    int n = clog2(x);
    return  ( x == (1 << n) ) ? n + 1 : n;
endfunction
//------------------------------------------------------------------------------
function automatic void __write_error_staus_code(int code);
    int fd = $fopen("sim_error_status_code", "w");
    $fwrite(fd, code);
    $fclose(fd);
endfunction
//------------------------------------------------------------------------------
function automatic void __sim_error(int code = -1);
    __write_error_staus_code(code);
    $display("\n==============================================================================");
    $error(">>>>  SIMULATION ERROR <<<<");
    $stacktrace(100);
    $display("==============================================================================\n");
endfunction
//------------------------------------------------------------------------------
function automatic void __sim_fatal_error(int code = -1);
    __write_error_staus_code(code);
    $display("\n******************************************************************************");
    $display("** Error: >>>>>>>> FATAL SIMULATION ERROR <<<<<<<<");
    $display("   Time: %t", $realtime);
    $stacktrace(100);
    $display("\n******************************************************************************");
    $fatal();
endfunction
//------------------------------------------------------------------------------

endpackage

import common::*;

//------------------------------------------------------------------------------
`define PRINT_MACRO_STATUS(x,y = "")                \
        `ifdef x                                    \
            $write("%-50s - ON  %s\n", `"x`", y);   \
        `else                                       \
            $write("%-50s - OFF %s\n", `"x`", y);   \
        `endif

//------------------------------------------------------------------------------
`define CONSTRUCT_DIR(path1,path2) { path1, "/", path2 }
`define JOIN_PATH(path1, path2) { path1, "/", path2 }

`define SV_RAND_CHECK(r) \
    do begin \
        if(!r) begin \
            $display("[%t], %s:%d: randomization failed \"%s\"", $realtime, `__FILE__, `__LINE__, `"r`"); \
            $stop(); \
        end \
    end while(0)
//------------------------------------------------------------------------------
`endif // COMMON_SVH

