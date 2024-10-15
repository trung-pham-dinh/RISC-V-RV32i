`include "timescale.svh"

`define RESETPERIOD 55
`define FINISH      1005

module tbench;

// Clock and reset generator
  logic i_clk;
  logic i_rst_n;

  logic [31:0] o_pc_debug;
  logic        o_inst_vld;
  logic [31:0] o_io_ledr;
  logic [31:0] o_io_ledg;
  logic [6:0]  o_io_hex0;
  logic [6:0]  o_io_hex1;
  logic [6:0]  o_io_hex2;
  logic [6:0]  o_io_hex3;
  logic [6:0]  o_io_hex4;
  logic [6:0]  o_io_hex5;
  logic [6:0]  o_io_hex6;
  logic [6:0]  o_io_hex7;
  logic [31:0] o_io_lcd;
  logic [31:0] i_io_sw = 0;
  logic [3:0]  i_io_btn = 0;

  initial tsk_clock_gen(i_clk);
  initial tsk_reset(i_rst_n, `RESETPERIOD);
  initial tsk_timeout(`FINISH);


// Wave dumping
  initial begin : proc_dump_wave
    $dumpfile("wave.vcd");
    $dumpvars(0, dut);
  end

singlecycle #(
    .INST_MEM_ADDR_W(10)
) dut (
  .*
);
endmodule : tbench
