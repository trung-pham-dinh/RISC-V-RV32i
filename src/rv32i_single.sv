module rv32i_single 
    import rv32i_pkg::*;
(
    // Global clock, acitve on the rising edge
      input  logic        i_clk
    // Global acitve reset
    , input  logic        i_rst
    // Debug program counter
    , output logic [31:0] o_pc_debug
    // Instruction valid
    , output logic        o_inst_vld
    // Output for driving red LEDs
    , output logic [31:0] o_io_ledr
    // Output for driving green LEDs
    , output logic [31:0] o_io_ledg
    // Output for driving 7-segment LED displays
    , output logic [6:0]  o_io_hex0
    , output logic [6:0]  o_io_hex1
    , output logic [6:0]  o_io_hex2
    , output logic [6:0]  o_io_hex3
    , output logic [6:0]  o_io_hex4
    , output logic [6:0]  o_io_hex5
    , output logic [6:0]  o_io_hex6
    , output logic [6:0]  o_io_hex7
    // Output for driving the LCD register
    , output logic [31:0] o_io_lcd
    // Input for switches
    , input  logic [31:0] i_io_sw
    // Input for buttons
    , input  logic [3:0]  i_io_btn
);
//////////////////////////////////////////////////////////////////////////
// Declaration
//////////////////////////////////////////////////////////////////////////
    logic [31:0] alu_data;


//////////////////////////////////////////////////////////////////////////
// Instruction Fetch (IF)
//////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////
// Instruction Decode (ID)
//////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////
// Execution (EX)
//////////////////////////////////////////////////////////////////////////

alu (
    .i_operand_a('0      ),   
    .i_operand_b('0      ),   
    .i_alu_op   ('0      ),
    .o_alu_data (alu_data)  
);

//////////////////////////////////////////////////////////////////////////
// Memory Access (MEM)
//////////////////////////////////////////////////////////////////////////

lsu (
    .i_clk    (i_clk    ),   
    .i_rst    (i_rst    ),    

    .i_addr   (alu_data ),  
    .i_st_data('0       ), 
    .i_st_strb('0       ),
    .i_mem_wr ('0       ), 

    .o_ld_data(o_ld_data),
    .o_io_ledr(o_io_ledr),
    .o_io_ledg(o_io_ledg),
    .o_io_hex0(o_io_hex0),
    .o_io_hex1(o_io_hex1),
    .o_io_hex2(o_io_hex2),
    .o_io_hex3(o_io_hex3),
    .o_io_hex4(o_io_hex4),
    .o_io_hex5(o_io_hex5),
    .o_io_hex6(o_io_hex6),
    .o_io_hex7(o_io_hex7),
    .o_io_lcd (o_io_lcd ),  
    .i_io_sw  (i_io_sw  ),  
    .i_io_btn (i_io_btn )   
);

//////////////////////////////////////////////////////////////////////////
// Write Back (WB)
//////////////////////////////////////////////////////////////////////////
    
endmodule