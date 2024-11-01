`include "timescale.svh"

`define RESETPERIOD 55
`define FINISH      115005

module tbench;

// Wave dumping
  initial begin : proc_dump_wave
    $dumpfile("wave.vcd");
    $dumpvars(0, dut);
  end

`ifdef AHAI
// Clock and reset generator
  logic i_clk;
  logic i_rst_n;

/* verilator lint_off UNUSEDSIGNAL */
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
  logic        o_lcd_vld;
  logic [31:0] i_io_sw = 32'h12345678;
  logic [3:0]  i_io_btn= 4'b1010;
/* verilator lint_off UNUSEDSIGNAL */

  initial tsk_clock_gen(i_clk);
  initial tsk_button_gen(i_io_btn);
  initial tsk_reset(i_rst_n, `RESETPERIOD);
  initial tsk_timeout(`FINISH);


singlecycle #(
    .INST_MEM_ADDR_W(10)
) dut (
  .*
);

`else

  logic        CLOCK_50;
  logic [17:0] SW = 18'h1234;
  logic [3:0]  KEY;

/* verilator lint_off UNUSEDSIGNAL */
  logic [8:0]  LEDG;
  logic [17:0] LEDR;

  logic [6:0]  HEX0;
  logic [6:0]  HEX1;
  logic [6:0]  HEX2;
  logic [6:0]  HEX3;
  logic [6:0]  HEX4;
  logic [6:0]  HEX5;
  logic [6:0]  HEX6;
  logic [6:0]  HEX7;

  logic [7:0]  LCD_DATA;
  logic        LCD_RW;
  logic        LCD_EN;
  logic        LCD_RS;
  logic        LCD_ON;
/* verilator lint_off UNUSEDSIGNAL */
  logic        i_rst_n;

  initial tsk_clock_gen(CLOCK_50);
  initial tsk_button_gen(KEY);
  initial tsk_reset(i_rst_n, `RESETPERIOD);
  initial tsk_timeout(`FINISH);

  assign SW[0] = i_rst_n; 
  TOP_SYNTH dut(
    .*      
  );

`endif 

endmodule : tbench

