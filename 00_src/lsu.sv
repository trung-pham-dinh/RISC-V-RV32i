module lsu 
#(
   parameter IS_BCD = 1 // if 1, we use HEX converter
)(
   // System
   input  logic        i_clk,
   input  logic        i_rst_n,
   // CPU side
/* verilator lint_off UNUSEDSIGNAL */
   input  logic [31:0] i_lsu_addr,
/* verilator lint_off UNUSEDSIGNAL */
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
   logic [31:0] ledr_reg;
   logic [31:0] ledg_reg;
   logic [31:0] seg7_0to3_reg;
   logic [31:0] seg7_4to7_reg;
   logic [31:0] lcd_reg;
   logic        is_data_addr;
   logic        is_ledr_addr;
   logic        is_ledg_addr;
   logic        is_seg7_addr;
   logic        is_lcd_addr ;
   logic        is_sw_addr  ;
   logic        is_btn_addr ;

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

      is_data_addr = (i_lsu_addr[15:13] == DATA_BASE_ADDR[15:13]) && (~|i_lsu_addr[31:16]);
      is_ledr_addr = (i_lsu_addr[15:2]  == LEDR_BASE_ADDR[15:2] ) && (~|i_lsu_addr[31:16]);
      is_ledg_addr = (i_lsu_addr[15:2]  == LEDG_BASE_ADDR[15:2] ) && (~|i_lsu_addr[31:16]);
      is_seg7_addr = (i_lsu_addr[15:3]  == SEG7_BASE_ADDR[15:3] ) && (~|i_lsu_addr[31:16]);
      is_lcd_addr  = (i_lsu_addr[15:2]  == LCD_BASE_ADDR [15:2] ) && (~|i_lsu_addr[31:16]);
      is_sw_addr   = (i_lsu_addr[15:2]  == SW_BASE_ADDR  [15:2] ) && (~|i_lsu_addr[31:16]);
      is_btn_addr  = (i_lsu_addr[15:2]  == BTN_BASE_ADDR [15:2] ) && (~|i_lsu_addr[31:16]);
   end

   //---------------------------
   // Data memory - TODO: use SDRAM later on
   //---------------------------
   localparam int
		TOTAL_BYTES = DATA_LAST_ADDR-DATA_BASE_ADDR+1,
	   RAM_DEPTH   = TOTAL_BYTES / 4,
		ADDR_WIDTH  = $clog2(TOTAL_BYTES),
		BYTE_WIDTH  = 8,
		BYTES       = 4;

	logic [BYTES-1:0][BYTE_WIDTH-1:0] ram [0:RAM_DEPTH-1];

   // Write data
	always_ff@(posedge i_clk)	begin
		if(i_lsu_wren && is_data_addr) begin
         for (int i = 0; i < BYTES; i++) begin
            if(i_st_strb[i]) ram[i_lsu_addr[ADDR_WIDTH-1:2]][i] <= i_st_data[BYTE_WIDTH*i+:BYTE_WIDTH];
         end
	   end
	end

   //---------------------------
   //          MMIO
   //---------------------------
   // Write logic
   always_ff @( posedge i_clk ) begin : MMIO_wr
      if (!i_rst_n) begin
         ledr_reg      <= 0;
         ledg_reg      <= 0;
         seg7_0to3_reg <= 0;
         seg7_4to7_reg <= 0;
         lcd_reg       <= 0;
      end
      else begin
         if (i_lsu_wren && is_ledr_addr) begin
            ledr_reg <= (ledr_reg & ~byte_mask) | (i_st_data & byte_mask);
         end

         if (i_lsu_wren && is_ledg_addr) begin
            ledg_reg <= (ledg_reg & ~byte_mask) | (i_st_data & byte_mask);
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
            lcd_reg <= (lcd_reg & ~byte_mask) | (i_st_data & byte_mask);
         end
      end
   end

   // Read logic
   always_ff @( posedge i_clk ) begin : MMIO_rd
      if (!i_rst_n) begin
         o_ld_data  <= 0;
         o_data_vld <= 0;
      end
      else begin
         if (!i_lsu_wren && is_ledr_addr) begin
            o_ld_data  <= ledr_reg;
            o_data_vld <= 1'b1;
         end
         else if (!i_lsu_wren && is_ledg_addr) begin
            o_ld_data  <= ledg_reg;
            o_data_vld <= 1'b1;
         end
         else if (!i_lsu_wren && is_seg7_addr) begin
            if (i_lsu_addr[2]) begin
               o_ld_data <= seg7_4to7_reg;
            end
            else begin
               o_ld_data <= seg7_0to3_reg;
            end
            o_data_vld <= 1'b1;
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
            o_ld_data  <= ram[i_lsu_addr[ADDR_WIDTH-1:2]];
            o_data_vld <= 1'b1;
         end
         else if (!i_lsu_wren && is_btn_addr) begin
            o_ld_data <= {28'd0, i_io_btn};
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
   function [6:0] bcd_to_7seg;
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
      if(IS_BCD) begin
         o_io_hex0 = bcd_to_7seg(seg7_0to3_reg[8*0 +: 4]);
         o_io_hex1 = bcd_to_7seg(seg7_0to3_reg[8*1 +: 4]);
         o_io_hex2 = bcd_to_7seg(seg7_0to3_reg[8*2 +: 4]);
         o_io_hex3 = bcd_to_7seg(seg7_0to3_reg[8*3 +: 4]);
         o_io_hex4 = bcd_to_7seg(seg7_4to7_reg[8*0 +: 4]);
         o_io_hex5 = bcd_to_7seg(seg7_4to7_reg[8*1 +: 4]);
         o_io_hex6 = bcd_to_7seg(seg7_4to7_reg[8*2 +: 4]);
         o_io_hex7 = bcd_to_7seg(seg7_4to7_reg[8*3 +: 4]);
      end
      else begin 
         o_io_hex0 = seg7_0to3_reg[8*0 +: 7];
         o_io_hex1 = seg7_0to3_reg[8*1 +: 7];
         o_io_hex2 = seg7_0to3_reg[8*2 +: 7];
         o_io_hex3 = seg7_0to3_reg[8*3 +: 7];
         o_io_hex4 = seg7_4to7_reg[8*0 +: 7];
         o_io_hex5 = seg7_4to7_reg[8*1 +: 7];
         o_io_hex6 = seg7_4to7_reg[8*2 +: 7];
         o_io_hex7 = seg7_4to7_reg[8*3 +: 7];
      end

      // LCD display
      o_io_lcd = lcd_reg;
   end
endmodule
