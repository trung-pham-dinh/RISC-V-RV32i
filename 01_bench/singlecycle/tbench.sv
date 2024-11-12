`include "timescale.svh"

`define RESETPERIOD 55
`define FINISH      115000

module tbench
  import singlecycle_pkg::*;
();

// Wave dumping
  initial begin : proc_dump_wave
    $dumpfile("wave.vcd");
    $dumpvars(0, dut);
  end

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
  logic [17:0] SRAM_ADDR;
  logic [15:0] SRAM_DQ  ;
  logic        SRAM_CE_N;
  logic        SRAM_WE_N;
  logic        SRAM_LB_N;
  logic        SRAM_UB_N;
  logic        SRAM_OE_N=0;
  logic [31:0] i_io_sw = 32'h12345678;
  logic [3:0]  i_io_btn;

/* verilator lint_off UNUSEDSIGNAL */

  initial tsk_clock_gen(i_clk);
  initial tsk_reset(i_rst_n, `RESETPERIOD);
  initial tsk_timeout(`FINISH);
  initial tsk_button_gen(i_io_btn);
  initial tsk_switch_gen(i_io_sw);

  singlecycle #(
      .INST_MEM_ADDR_W(10),
      .MEM_TYPE(MEM_FLOP)
  ) dut (
  .*
  );

  scoreboard_alu scoreboard_alu
  (
    .i_clk        (i_clk              ),  
    .i_rst_n      (i_rst_n            ),  
    .act_alu_res  (dut.alu.o_alu_res  ),  
    .drv_operand_a(dut.alu.i_operand_a),    
    .drv_operand_b(dut.alu.i_operand_b),    
    .drv_alu_op   (dut.alu.i_alu_op   ) 
  );

  scoreboard_pc scoreboard_pc(
    .i_clk      (i_clk                ),    
    .i_rst_n    (i_rst_n              ),    
    .act_pc     (dut.pc               ), 
    .drv_pc_sel (dut.control.o_pc_sel ),       
    .drv_pc_en  (dut.pc_en            ),    
    .drv_alu_res(dut.alu.o_alu_res    )      
  );

  scoreboard_branch_comp scoreboard_branch_comp
  (
    .i_clk       (i_clk                    ),    
    .i_rst_n     (i_rst_n                  ),    
    .drv_rs1_data(dut.regfile.o_rs1_data   ),    
    .drv_rs2_data(dut.regfile.o_rs2_data   ),    
    .drv_br_un   (dut.control.o_br_un      ),  
    .act_br_eq   (dut.branch_comp.o_br_eq  ), 
    .act_br_lt   (dut.branch_comp.o_br_lt  ) 
  );

  scoreboard_lsu_dat_handler scoreboard_lsu_dat_handler
  (
    .i_clk       (i_clk                        ), 
    .i_rst_n     (i_rst_n                      ), 
                  
    .drv_funct3  (dut.inst_mem.o_inst[14:12]   ),  
    .drv_lsb_addr(dut.alu.o_alu_res[1:0]       ),    
    .drv_ld_data (dut.lsu.o_ld_data            ),   
    .drv_st_data (dut.regfile.o_rs2_data       ),   
                  
    .act_st_data (dut.lsu_dat_handler.o_st_data),   
    .act_st_strb (dut.lsu_dat_handler.o_st_strb),   
    .act_ld_data (dut.lsu_dat_handler.o_ld_data)   
  );

  logic [31:0] [31:0] drv_regs;
  generate
      genvar i;
      for (i = 0; i < 32; i++) begin
         assign drv_regs[i] = dut.regfile.regs[i];
      end
  endgenerate
  scoreboard_regfile scoreboard_regfile 
  (
    .i_clk   (i_clk   ), 
    .i_rst_n (i_rst_n ), 
    .drv_regs(drv_regs)
  );

  scoreboard_lsu scoreboard_lsu(
    .i_clk           (i_clk                ),   
    .i_rst_n         (i_rst_n              ),   
                      
    .drv_VALID       (dut.control.lsu_VALID),   
    .drv_lsu_addr    (dut.alu.o_alu_res    ),      
                      
    .act_vld_data_mem(dut.lsu.vld_data_mem),          
    .act_vld_ledr    (dut.lsu.vld_ledr    ),          
    .act_vld_ledg    (dut.lsu.vld_ledg    ),          
    .act_vld_seg7    (dut.lsu.vld_seg7    ),          
    .act_vld_lcd     (dut.lsu.vld_lcd     ),          
    .act_vld_sw      (dut.lsu.vld_sw      ),          
    .act_vld_btn     (dut.lsu.vld_btn     ),          
    .act_vld_timer   (dut.lsu.vld_timer   )
  );

endmodule : tbench

