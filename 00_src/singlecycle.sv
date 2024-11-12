module singlecycle 
    import singlecycle_pkg::*;
#(
    parameter INST_MEM_ADDR_W = 10, // FIXME: increase memsize 
    parameter MEM_TYPE = MEM_FLOP // 0: flop-based, 1: sram-based
)
(
    // Global clock, acitve on the rising edge
      input  logic        i_clk
    // Global acitve reset
    , input  logic        i_rst_n
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

    // Write request to LCD: only for FPGA
    , output logic        o_lcd_vld
    // SRAM interface
    , output logic [17:0] SRAM_ADDR
    , inout  wire  [15:0] SRAM_DQ  
    , output logic        SRAM_CE_N
    , output logic        SRAM_WE_N
    , output logic        SRAM_LB_N
    , output logic        SRAM_UB_N
    , input  logic        SRAM_OE_N
);
//////////////////////////////////////////////////////////////////////////
// Declaration
//////////////////////////////////////////////////////////////////////////

    // control unit
    ImmSel_e     imm_sel  ;  
    logic        reg_wen  ;   
    logic        br_un    ; 
    BSel_e       b_sel    ; 
    ASel_e       a_sel    ; 
    ALUSel_e     alu_sel  ;  
    logic        st_mem   ;  
    WBSel_e      wb_sel   ;  
    PCSel_e      pc_sel   ;  
    logic        pc_en    ;
    logic        lsu_VALID;
    logic        lsu_READY;

    // Instruction Fetch
    logic [31:0] pc;
    logic [31:0] pc_4;
    logic [31:0] inst;

    // Instruction Decode
    logic [REGIDX_WIDTH-1:0] rs1_addr;
    logic [REGIDX_WIDTH-1:0] rs2_addr;
    logic [REGIDX_WIDTH-1:0] rd_addr;
    logic [31:0]             rs1_data;
    logic [31:0]             rs2_data;
    logic [31:0]             imm;

    // Execution
    logic [31:0] a_operand;
    logic [31:0] b_operand;
    logic [31:0] alu_res;
    logic br_eq;
    logic br_lt;

    // Mem Access
    logic [31:0] ld_data;

    // Write Back
    logic [31:0] wb_res;

    assign o_pc_debug = pc;
//////////////////////////////////////////////////////////////////////////
// Control Unit
//////////////////////////////////////////////////////////////////////////

control control(
    .i_inst    (inst      ),
    .i_br_eq   (br_eq     ),        
    .i_br_lt   (br_lt     ), 
    .o_imm_sel (imm_sel   ),   
    .o_reg_wen (reg_wen   ),   
    .o_br_un   (br_un     ), 
    .o_b_sel   (b_sel     ), 
    .o_a_sel   (a_sel     ), 
    .o_alu_sel (alu_sel   ),   
    .o_st_mem  (st_mem    ),  
    .o_wb_sel  (wb_sel    ),  
    .o_pc_sel  (pc_sel    ),
    .o_inst_vld(o_inst_vld),
    .o_pc_en   (pc_en     ),
    .lsu_VALID (lsu_VALID ),
    .lsu_READY (lsu_READY )
);

//////////////////////////////////////////////////////////////////////////
// Instruction Fetch (IF)
//////////////////////////////////////////////////////////////////////////
assign pc_4 = 32'(pc + 32'('d4));

always_ff @( posedge i_clk ) begin
    if(~i_rst_n) begin 
        pc <= 0;
    end
    else begin
        if(pc_en)
            pc <= (pc_sel==PC_4)? pc_4 : alu_res;
        else 
            pc <= pc;
    end
end

inst_mem #(
    .ADDR_W(INST_MEM_ADDR_W)
) inst_mem (
    .i_addr(INST_MEM_ADDR_W'(pc)),
    .o_inst(inst                )
);

//////////////////////////////////////////////////////////////////////////
// Instruction Decode (ID)
//////////////////////////////////////////////////////////////////////////

assign rd_addr  = inst[11:7];
assign rs1_addr = inst[19:15];
assign rs2_addr = inst[24:20];

regfile regfile(
    .i_clk     (i_clk   ),   
    .i_rst_n   (i_rst_n ),   
              
    .i_rs1_addr(rs1_addr),    
    .i_rs2_addr(rs2_addr),    
    .i_rd_addr (rd_addr ),   
    .i_rd_wen  (reg_wen ),  
    .i_rd_data (wb_res  ),  
              
    .o_rs1_data(rs1_data),  
    .o_rs2_data(rs2_data)   
);

always_comb begin
    case(imm_sel)
        IMM_I: imm = {{21{inst[31]}}, inst[30:20]};
        IMM_S: imm = {{21{inst[31]}}, inst[30:25], inst[11:7]};
        IMM_B: imm = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
        IMM_U: imm = {inst[31], inst[30:20], inst[19:12], {12{1'b0}}};
        IMM_J: imm = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:25], inst[24:21], 1'b0};
        default: imm = '0;
    endcase
end

//////////////////////////////////////////////////////////////////////////
// Execution (EX)
//////////////////////////////////////////////////////////////////////////

assign a_operand = (a_sel == A_REG)? rs1_data : (a_sel == A_PC)? pc : '0;
assign b_operand = (b_sel == B_REG)? rs2_data : imm;

alu alu(
    .i_operand_a(a_operand),   
    .i_operand_b(b_operand),   
    .i_alu_op   (alu_sel  ),
    .o_alu_res  (alu_res  )  
);


branch_comp branch_comp(
    .i_rs1_data(rs1_data), 
    .i_rs2_data(rs2_data), 
    .i_br_un   (br_un   ), 
    .o_br_eq   (br_eq   ),  
    .o_br_lt   (br_lt   )   
);

//////////////////////////////////////////////////////////////////////////
// Memory Access (MEM)
//////////////////////////////////////////////////////////////////////////
logic [3:0] st_strb;
logic [31:0] ld_data_raw;
logic [31:0] st_data;

lsu_dat_handler lsu_dat_handler(
   .i_funct3  (inst[14:12] ), 
   .i_lsb_addr(alu_res[1:0]),

   .i_st_data (rs2_data    ),  
   .o_st_data (st_data     ),  
   .o_st_strb (st_strb     ),  

   .i_ld_data (ld_data_raw ),  
   .o_ld_data (ld_data     )  
);

lsu #(
    .MEM_TYPE(MEM_TYPE)
) lsu (
    .i_clk     (i_clk       ),   
    .i_rst_n   (i_rst_n     ),    

    .i_lsu_addr(alu_res     ),  
    .i_st_data (st_data     ), 
    .i_st_strb (st_strb     ),
    .i_lsu_wren(st_mem      ), 
    .o_ld_data (ld_data_raw ),
    .o_lcd_vld (o_lcd_vld   ),
    .i_VALID   (lsu_VALID   ),
    .o_READY   (lsu_READY   ),
    // .o_data_vld(            ),

    .o_io_ledr (o_io_ledr   ),
    .o_io_ledg (o_io_ledg   ),
    .o_io_hex0 (o_io_hex0   ),
    .o_io_hex1 (o_io_hex1   ),
    .o_io_hex2 (o_io_hex2   ),
    .o_io_hex3 (o_io_hex3   ),
    .o_io_hex4 (o_io_hex4   ),
    .o_io_hex5 (o_io_hex5   ),
    .o_io_hex6 (o_io_hex6   ),
    .o_io_hex7 (o_io_hex7   ),
    .o_io_lcd  (o_io_lcd    ),  
    .i_io_sw   (i_io_sw     ),  
    .i_io_btn  (i_io_btn    ),   

    .SRAM_ADDR (SRAM_ADDR   ),      
    .SRAM_DQ   (SRAM_DQ     ),      
    .SRAM_CE_N (SRAM_CE_N   ),      
    .SRAM_WE_N (SRAM_WE_N   ),      
    .SRAM_LB_N (SRAM_LB_N   ),      
    .SRAM_UB_N (SRAM_UB_N   ),      
    .SRAM_OE_N (SRAM_OE_N   )   
);

//////////////////////////////////////////////////////////////////////////
// Write Back (WB)
//////////////////////////////////////////////////////////////////////////
    always_comb begin 
        case (wb_sel)
            WB_PC:   wb_res = pc_4; 
            WB_ALU:  wb_res = alu_res;
            WB_MEM:  wb_res = ld_data;
            default: wb_res = '0;
        endcase 
    end
endmodule
