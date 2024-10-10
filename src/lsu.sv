module lsu 
    import rv32i_pkg::*;
(
      input  logic        i_clk
    , input  logic        i_rst

    , input  logic [31:0] i_addr
    , input  logic [31:0] i_st_data
    , input  logic [3:0]  i_st_strb // each strobe bit is corresponding to each byte
    , input  logic        i_mem_wr
    , output logic [31:0] o_ld_data

    // I/O
    , output logic [31:0] o_io_ledr
    , output logic [31:0] o_io_ledg
    , output logic [6:0]  o_io_hex0
    , output logic [6:0]  o_io_hex1
    , output logic [6:0]  o_io_hex2
    , output logic [6:0]  o_io_hex3
    , output logic [6:0]  o_io_hex4
    , output logic [6:0]  o_io_hex5
    , output logic [6:0]  o_io_hex6
    , output logic [6:0]  o_io_hex7
    , output logic [31:0] o_io_lcd
    , input  logic [31:0] i_io_sw
    , input  logic [3:0]  i_io_btn 
);
    always_comb begin // temporarily assigned, must delete after actually driving
        o_io_ledr = '0;
        o_io_ledg = '0;
        o_io_hex0 = '0;
        o_io_hex1 = '0;
        o_io_hex2 = '0;
        o_io_hex3 = '0;
        o_io_hex4 = '0;
        o_io_hex5 = '0;
        o_io_hex6 = '0;
        o_io_hex7 = '0;
        o_io_lcd  = '0;
    end
endmodule