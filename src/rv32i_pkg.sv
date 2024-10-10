`ifndef  RV32IPKG_SV
`define RV32IPKG_SV

package rv32i_pkg;

    parameter FUNCT3_WIDTH = 3;
    parameter FUNCT7_WIDTH = 7;
    parameter OPCODE_WIDTH = 7;
    parameter REGIDX_WIDTH = 5;

    typedef enum logic[1:0] { 
        A_REG  = 2'd0,
        A_PC   = 2'd1,
        A_ZERO = 2'd2
    } ASel_e;

    typedef enum logic { 
        B_REG  = 1'd0,
        B_IMM  = 1'd1
    } BSel_e;

    typedef enum logic[3:0] { 
        ALU_ADD  = 4'd0,
        ALU_SUB  = 4'd1,
        ALU_XOR  = 4'd2,
        ALU_OR   = 4'd3,
        ALU_AND  = 4'd4,
        ALU_SLL  = 4'd5,
        ALU_SRL  = 4'd6,
        ALU_SRA  = 4'd7,
        ALU_SLT  = 4'd8,
        ALU_SLTU = 4'd9
    } ALUSel_e;

    typedef enum logic [1:0] { 
        WB_ALU = 2'd0,
        WB_MEM = 2'd1,
        WB_PC  = 2'd2
    } WBSel_e;

    typedef enum logic [2:0] { 
        IMM_I = 3'd0,
        IMM_S = 3'd1,
        IMM_B = 3'd2,
        IMM_J = 3'd3,
        IMM_U = 3'd4
    } ImmSel_e;
endpackage

`endif 