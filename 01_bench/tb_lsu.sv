`timescale 1ps/1ps
module tb_lsu;
   logic        i_clk;
   logic        i_rst;
   logic [31:0] i_lsu_addr;
   logic [31:0] i_st_data;
   logic [3:0]  i_st_strb;  // Byte strobe (used for byte/halfword/word writes)
   logic        i_lsu_wren; // 1 if writing
   logic [31:0] o_ld_data;
   logic        o_data_vld;
   logic [31:0] i_io_sw;
   logic [3:0]  i_io_btn;
   logic [31:0] o_io_ledr;
   logic [31:0] o_io_ledg;
   logic [31:0] o_io_lcd;
   logic [6:0]  o_io_hex0;    // 7-bit output for HEX0
   logic [6:0]  o_io_hex1;    // 7-bit output for HEX1
   logic [6:0]  o_io_hex2;    // 7-bit output for HEX2
   logic [6:0]  o_io_hex3;    // 7-bit output for HEX3
   logic [6:0]  o_io_hex4;    // 7-bit output for HEX4
   logic [6:0]  o_io_hex5;    // 7-bit output for HEX5
   logic [6:0]  o_io_hex6;    // 7-bit output for HEX6
   logic [6:0]  o_io_hex7;     // 7-bit output for HEX7
   // Internal signals
   logic [31:0] reg_addr = 0;
   logic [31:0] reg_wval = 0;
   logic [3:0]  reg_wstb = 0;

   localparam   DATA_BASE_ADDR = 32'h0000_2000;
   localparam   LEDR_BASE_ADDR = 32'h0000_7000;
   localparam   LEDG_BASE_ADDR = 32'h0000_7010;
   localparam   SEG7_BASE_ADDR = 32'h0000_7020;
   localparam   LCD_BASE_ADDR  = 32'h0000_7030;
   localparam   SW_BASE_ADDR   = 32'h0000_7800;
   localparam   BTN_BASE_ADDR  = 32'h0000_7810;

   // DUT
   lsu u_lsu (
      .*
   );

   initial begin
      i_clk = 1;
      forever #5 i_clk = ~i_clk;
   end

   initial begin
      i_rst      = 0;
      i_clk      = 1;
      i_lsu_addr = 0;
      i_st_data  = 0;
      i_st_strb  = 0; 
      i_lsu_wren = 0;
      i_io_sw    = 32'h0000_AAAA;
      i_io_btn   = 4'hA;

      #30 i_rst = 1;

      #120
      /*--- CHOOSE WHICH PERIPHERAL TO OBSERVE ---*/

      // testing_ledr();
      // testing_ledg();
      testing_dmem();
      // testing_7seg();
      // testing_sw();
      
      /*------------------------------------------*/

      #100
      $stop;
   end

   task testing_ledr;
      begin
         $display("Writing LEDR at time:", $time);
         reg_write(LEDR_BASE_ADDR+32'h1, 32'hAA, 0);
         #30
         $display("Reading LEDR at time", $time);
         reg_read(LEDR_BASE_ADDR);
      end
   endtask 

   task testing_ledg;
      begin
         $display("Writing LEDG at time:", $time);
         reg_write(LEDG_BASE_ADDR, 32'hAA, 0);
         #30
         $display("Reading LEDG at time", $time);
         reg_read(LEDG_BASE_ADDR);
      end
   endtask 

   task testing_7seg;
      begin
         // Store words
         reg_write(SEG7_BASE_ADDR, 32'h04030201, 4'hF);
         #30
         reg_write(SEG7_BASE_ADDR+4, 32'h08070605, 4'hF);

         #120
         // Store bytes
         for (int i = 0; i < 4; i++) begin
            reg_write(SEG7_BASE_ADDR + i, 32'h09070605, 1 << i);
         end

         #30
         // Store words
         reg_write(SEG7_BASE_ADDR, 32'h04030201, 4'hF);
         #30
         // Store halves
         for (int i = 0; i < 2; i++) begin
            reg_write(SEG7_BASE_ADDR + (i<<1), 32'h09070605, 4'h3 << (i<<1));
         end
      end
   endtask 

   task testing_sw;
      begin
         reg_read(SW_BASE_ADDR);
      end
   endtask

   task testing_dmem;
      begin
         // Store word
         for (int i = 0; i < 4; i++) begin
            reg_write(DATA_BASE_ADDR + i, 32'h78a4_302f, 4'hF);
         end
         #30
         reg_read(DATA_BASE_ADDR);

         #100
         // Store bytes
         for (int i = 0; i < 4; i++) begin
            reg_write(DATA_BASE_ADDR + i, 32'h04030201, 1 << i);
         end
         #30
         for (int i = 0; i < 4; i++) begin
            reg_read(DATA_BASE_ADDR + i);
         end

         #100
         // Store halves
         for (int i = 0; i < 2; i++) begin
            reg_write(DATA_BASE_ADDR + i, 32'hddccbbaa, 4'h3 << (i<<1));
         end
         #30
         for (int i = 0; i < 2; i++) begin
            reg_read(DATA_BASE_ADDR + i);
         end
      end
   endtask
   

   task reg_write(input [31:0] reg_addr, input [31:0] reg_wval, input [3:0] reg_wstb);
      begin
         @(posedge i_clk);
         i_st_data  = reg_wval;
         i_lsu_addr = reg_addr;
         i_lsu_wren = 1;
         i_st_strb  = reg_wstb;
         @(posedge i_clk);
         i_lsu_wren = 0;
         i_lsu_addr = 0;
      end
   endtask

   task reg_read(input [31:0] reg_addr);
      begin
         @(posedge i_clk);
         i_lsu_addr = reg_addr;
         i_lsu_wren = 0;
      end
   endtask

endmodule