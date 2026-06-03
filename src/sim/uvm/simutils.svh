//------------------------------------------------------------------------------
//
//    Project: Any
//
//    Purpose: Simulation Utility Stuff
//
//    Author : Harry E. Zhurov, 2023-2024
//
//------------------------------------------------------------------------------

`ifndef SIM_UTILS_SVH
`define SIM_UTILS_SVH

`ifdef SIMULATOR

`include "common.svh"

//------------------------------------------------------------------------------
//
//   Colorize text strings and prints
//
typedef enum
{
    styleNORMAL    = 1,
    styleBOLD      = 2,
    styleITALIC    = 4,
    styleUNDERLINE = 8
}
text_style_t;

typedef enum
{
    colorBLACK         = 30,
    colorRED           = 31,
    colorGREEN         = 32,
    colorYELLOW        = 33,
    colorBLUE          = 34,
    colorMAGENTA       = 35,
    colorCYAN          = 36,
    colorWHITE         = 37,
    colorLIGHT_RED     = colorRED     + 60,
    colorLIGHT_GREEN   = colorGREEN   + 60,
    colorLIGHT_YELLOW  = colorYELLOW  + 60,
    colorLIGHT_BULE    = colorBLUE    + 60,
    colorLIGHT_MAGENTA = colorMAGENTA + 60,
    colorLIGHT_CYAN    = colorCYAN    + 60,
    colorLIGHT_WHITE

}
text_color_t;

//------------------------------------------------------------------------------
function automatic string colorize(string       s,
                                   text_color_t col,
                                   text_style_t st     = styleNORMAL,
                                   text_color_t bg_col = colorBLACK);
    string style = "";
    int    bg = bg_col == colorBLACK ? 49 : bg_col + 10;

    if (st & styleBOLD)      style = {st, ";1"};
    if (st & styleITALIC)    style = {st, ";3"};
    if (st & styleUNDERLINE) style = {st, ";4"};

    return $sformatf("\033[%s%0d;%0dm%s\033[0m", style, col, bg, s);
    //return $sformatf("\033[%s;38;2;%s;48;2;%sm%s\033[0m", style, "0;255;0", "0;0;0", s);
endfunction

//------------------------------------------------------------------------------
function automatic void log_print(string s, text_color_t col = colorWHITE);
    $display("[%t], %s", $realtime, colorize(s, col));
endfunction
//------------------------------------------------------------------------------
//
//   Raise error function. Force to return error exit code from simulator when test failed
//
function automatic void raise_sim_error(int code = -1);

    $display("***********************************");
    $display("    SV_SEED = %0d", `SV_SEED);
    $display("***********************************");
    __sim_error(code);

endfunction
//------------------------------------------------------------------------------
//
//   Raise error function. Force to return error exit code from simulator when test failed
//
function automatic void raise_sim_fatal_error(int code = -1);

    $display("***********************************");
    $display("    SV_SEED = %0d", `SV_SEED);
    $display("***********************************");
    __sim_fatal_error(code);

endfunction
//------------------------------------------------------------------------------
function void hexdump(logic [7:0] pool[], uint16_t len = 64);

    for(int i = 0; i < len; ++i) begin
        if( (i)%16 == 0) begin
            $write("\n%04x: ", i/16*16);
        end

        $write("%02x ", pool[i]);
        if( (i+1)%8 == 0) begin
            $write(" ");
        end
    end
    $write("\n");

endfunction
//--------------------------------------------------------------------------
`endif //  SIMULATOR
`endif // SIM_UTILS_SVH

