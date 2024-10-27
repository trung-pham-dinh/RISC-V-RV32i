module lsu (
   // System
   input  logic        i_clk,
   input  logic        i_rst,
   // CPU side
   input  logic [31:0] i_lsu_addr,
   input  logic [31:0] i_st_data,
   input  logic [3:0]  i_st_strb,  // Byte strobe (used for byte/halfword/word writes)
   input  logic        i_lsu_wren, // 1 if writing
   output logic [31:0] o_ld_data,
   output logic        o_data_vld,
   // Peripherals
   input  logic [31:0] i_io_sw,
   input  logic [3:0]  i_io_btn,
   output logic [31:0] o_io_ledr,
   output logic [31:0] o_io_ledg,
   output logic [31:0] o_io_lcd,
   output logic [6:0]  o_io_hex0,    // 7-bit output for HEX0
   output logic [6:0]  o_io_hex1,    // 7-bit output for HEX1
   output logic [6:0]  o_io_hex2,    // 7-bit output for HEX2
   output logic [6:0]  o_io_hex3,    // 7-bit output for HEX3
   output logic [6:0]  o_io_hex4,    // 7-bit output for HEX4
   output logic [6:0]  o_io_hex5,    // 7-bit output for HEX5
   output logic [6:0]  o_io_hex6,    // 7-bit output for HEX6
   output logic [6:0]  o_io_hex7     // 7-bit output for HEX7

);
   
   // Internal signals
   logic [31:0] byte_mask;
   logic [31:0] data_mem_reg;
   logic [31:0] ledr_reg;
   logic [31:0] ledg_reg;
   logic [31:0] seg7_reg;
   logic [31:0] seg7_0to3_reg;
   logic [31:0] seg7_4to7_reg;
   logic [31:0] lcd_reg;
   logic [31:0] sw_reg;
   logic [31:0] btn_reg;
   logic [31:0] rd_data_mem;
   logic        is_data_addr;
   logic        is_ledr_addr;
   logic        is_ledg_addr;
   logic        is_seg7_addr;
   logic        is_lcd_addr ;
   logic        is_sw_addr  ;
   logic        is_btn_addr  ;

   // Base addresses
   localparam DATA_BASE_ADDR = 32'h0000_2000;
   localparam DATA_LAST_ADDR = 32'h0000_3FFF;
   localparam LEDR_BASE_ADDR = 32'h0000_7000;
   localparam LEDG_BASE_ADDR = 32'h0000_7010;
   localparam SEG7_BASE_ADDR = 32'h0000_7020;
   localparam LCD_BASE_ADDR  = 32'h0000_7030;
   localparam SW_BASE_ADDR   = 32'h0000_7800;
   localparam BTN_BASE_ADDR  = 32'h0000_7810;

   always_comb begin
      // Generate a byte-wise mask for 32-bit data 
      byte_mask = {{8{i_st_strb[3]}}, {8{i_st_strb[2]}}, {8{i_st_strb[1]}}, {8{i_st_strb[0]}}};

      is_data_addr = i_lsu_addr[15:13]       == 3'd1; 
      is_ledr_addr = {i_lsu_addr[31:4],4'b0} == LEDR_BASE_ADDR;
      is_ledg_addr = i_lsu_addr              == LEDG_BASE_ADDR;
      is_seg7_addr = {i_lsu_addr[31:4],4'b0} == SEG7_BASE_ADDR;
      is_lcd_addr  = i_lsu_addr              == LCD_BASE_ADDR;
      is_sw_addr   = i_lsu_addr              == SW_BASE_ADDR;
      is_btn_addr  = i_lsu_addr              == BTN_BASE_ADDR;
   end

   //---------------------------
   // Data memory - TODO: use SDRAM later on
   //---------------------------
   localparam int
		ADDR_WIDTH = DATA_LAST_ADDR-DATA_BASE_ADDR,
		BYTE_WIDTH = 8,
		BYTES      = 4;

	logic [BYTES-1:0][BYTE_WIDTH-1:0] ram[0:ADDR_WIDTH-1];

   // Write data
	always_ff@(posedge i_clk)	begin
		if(i_lsu_wren && is_data_addr) begin
         for (int i = 0; i < BYTES; i++) begin
            if(i_st_strb[i]) ram[i_lsu_addr-DATA_BASE_ADDR][i] <= i_st_data[BYTE_WIDTH*i+:BYTE_WIDTH];
         end
	   end
	end

   //---------------------------
   //          MMIO
   //---------------------------
   // Write logic
   always_ff @( posedge i_clk or negedge i_rst ) begin : MMIO_wr
      if (!i_rst) begin
         ledr_reg      <= 0;
         ledg_reg      <= 0;
         seg7_0to3_reg <= 0;
         seg7_4to7_reg <= 0;
         lcd_reg       <= 0;
      end
      else begin
         if (i_lsu_wren && is_ledr_addr) begin
            ledr_reg <= i_st_data;
         end

         if (i_lsu_wren && is_ledg_addr) begin
            ledg_reg <= i_st_data;
         end

         if (i_lsu_wren && is_seg7_addr) begin
            if (i_lsu_addr[2]) begin
               seg7_4to7_reg <= (seg7_4to7_reg & ~byte_mask) | (i_st_data & byte_mask);
            end
            else begin
               seg7_0to3_reg <= (seg7_0to3_reg & ~byte_mask) | (i_st_data & byte_mask);
            end
         end
         
         if (i_lsu_wren && is_lcd_addr) begin
            lcd_reg <= i_st_data;
         end
      end
   end

   // Read logic
   always_ff @( posedge i_clk or negedge i_rst ) begin : MMIO_rd
      if (!i_rst) begin
         o_ld_data  <= 0;
         o_data_vld <= 0;
      end
      else begin
         if (!i_lsu_wren && is_ledr_addr) begin
            o_ld_data  <= i_st_data;
            o_data_vld <= 1'b1;
         end
         else if (!i_lsu_wren && is_ledg_addr) begin
            o_ld_data  <= ledg_reg;
            o_data_vld <= 1'b1;
         end
         else if (!i_lsu_wren && is_seg7_addr) begin
            if (i_lsu_addr[3]) begin
               o_ld_data <= seg7_4to7_reg;
            end
            else begin
               o_ld_data <= seg7_0to3_reg;
            end
         end
         else if (!i_lsu_wren && is_lcd_addr) begin
            o_ld_data <= lcd_reg;
            o_data_vld <= 1'b1;
         end
         else if (!i_lsu_wren && is_sw_addr) begin
            o_ld_data <= i_io_sw;
            o_data_vld <= 1'b1;
         end
         else if (!i_lsu_wren && is_data_addr) begin
            o_ld_data  <= ram[i_lsu_addr-DATA_BASE_ADDR];
            o_data_vld <= 1'b1;
         end
         else if (!i_lsu_wren && is_btn_addr) begin
            o_ld_data <= btn_reg;
            o_data_vld <= 1'b1;
         end
         else begin
            o_data_vld <= 0;
         end
      end
   end


   //---------------------------
   // 7-SEG display control
   //---------------------------
   function [7:0] bcd_to_7seg;
      input [3:0] bcd;
      // when bcd = 0, seg = 7'b1000000	
      // when bcd = 1, seg = 7'b1111001	
      // when bcd = 2, seg = 7'b0100100	
      // when bcd = 3, seg = 7'b0110000	
      // when bcd = 4, seg = 7'b0011001	
      // when bcd = 5, seg = 7'b0010010	
      // when bcd = 6, seg = 7'b0000010	
      // when bcd = 7, seg = 7'b1111000	
      // when bcd = 8, seg = 7'b0000000	
      // when bcd = 9, seg = 7'b0010000	

      bcd_to_7seg[0] = ((~bcd[3])&(~bcd[2])&(~bcd[1])&bcd[0]) | 
                       ((~bcd[3])&bcd[2]&(~bcd[1])&(~bcd[0]));

      bcd_to_7seg[1] = ((~bcd[3])&bcd[2]&(~bcd[1])&bcd[0]) | 
                       ((~bcd[3])&bcd[2]&bcd[1]&(~bcd[0]));    

      bcd_to_7seg[2] = ((~bcd[3])&(~bcd[2])&bcd[1]&(~bcd[0]));
      
      bcd_to_7seg[3] = ((~bcd[3])&(~bcd[2])&(~bcd[1])&bcd[0]) | 
                       ((~bcd[3])&bcd[2]&(~bcd[1])&(~bcd[0])) | 
                       ((~bcd[3])&bcd[2]&bcd[1]&bcd[0]);
      
      bcd_to_7seg[4] = ((~bcd[3])&bcd[0])           | 
                       ((~bcd[3])&bcd[2]&(~bcd[1])) | 
                       (~(bcd[2])&(~bcd[1])&bcd[0]);
      
      bcd_to_7seg[5] = ((~bcd[3])&(~bcd[2])&bcd[0]) | 
                       ((~bcd[3])&(~bcd[2])&bcd[1]) | 
                       ((~bcd[3])&bcd[1]&bcd[0]);

      bcd_to_7seg[6] = ((~bcd[3])&(~bcd[2])&(~bcd[1])) |
                       ((~bcd[3])&bcd[2]&bcd[1]&bcd[0]);
   endfunction // End 7-SEG display control


   always_comb begin : peripherals_output
      // LEDG/LEDR output
      o_io_ledg = ledg_reg;
      o_io_ledr = ledr_reg;

      // 7-segment display
      o_io_hex0 = bcd_to_7seg(seg7_0to3_reg[6:0])  ;
      o_io_hex1 = bcd_to_7seg(seg7_0to3_reg[14:8]) ;
      o_io_hex2 = bcd_to_7seg(seg7_0to3_reg[22:16]);
      o_io_hex3 = bcd_to_7seg(seg7_0to3_reg[30:24]);
      o_io_hex4 = bcd_to_7seg(seg7_4to7_reg[6:0])  ;
      o_io_hex5 = bcd_to_7seg(seg7_4to7_reg[14:8]) ;
      o_io_hex6 = bcd_to_7seg(seg7_4to7_reg[22:16]);
      o_io_hex7 = bcd_to_7seg(seg7_4to7_reg[30:24]);

      // LCD display
      o_io_lcd = lcd_reg;
   end
endmodule
