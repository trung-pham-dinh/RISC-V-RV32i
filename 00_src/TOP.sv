module TOP (
      input logic         CLOCK_50
    , input logic  [9:0]  SW
    , output logic [8:0]  LEDG
    , output logic [17:0] LEDR
    , output logic [6:0]  HEX0
    , output logic [6:0]  HEX1
    , output logic [6:0]  HEX2
    , output logic [6:0]  HEX3
    , output logic [6:0]  HEX4
    , output logic [6:0]  HEX5
    , output logic [6:0]  HEX6
    , output logic [6:0]  HEX7
);
    singlecycle singlecycle(
    .i_clk     (CLOCK_50), 
    .i_rst_n   (SW[0]),   
    .o_io_ledg (LEDG[8:0]),
    .o_io_ledr (LEDR[17:0]),
    .o_io_hex0 (HEX0),     
    .o_io_hex1 (HEX1),     
    .o_io_hex2 (HEX2),     
    .o_io_hex3 (HEX3),     
    .o_io_hex4 (HEX4),     
    .o_io_hex5 (HEX5),     
    .o_io_hex6 (HEX6),     
    .o_io_hex7 (HEX7),     
    .i_io_sw   (SW[9:0]),   
    .i_io_btn  ('0)    
    );
endmodule