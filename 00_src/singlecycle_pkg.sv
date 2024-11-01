`ifndef  SINGLECYCLEPKG_SV
`define SINGLECYCLEPKG_SV
`timescale 1ns/1ps

package singlecycle_pkg;

    /* verilator lint_off UNUSEDPARAM */
    localparam FUNCT3_WIDTH = 3;
    localparam FUNCT7_WIDTH = 7;
    localparam OPCODE_WIDTH = 7;
    localparam REGIDX_WIDTH = 5;
    localparam IMM_WIDTH    = 5;

    typedef enum logic[1:0] { 
        A_REG  = 2'd0,
        A_PC   = 2'd1,
        A_ZERO = 2'd2
    } ASel_e;
    localparam ASEL_W = $bits(ASel_e);

    typedef enum logic { 
        B_REG  = 1'd0,
        B_IMM  = 1'd1
    } BSel_e;
    localparam BSEL_W = $bits(BSel_e);

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
    localparam ALUSEL_W = $bits(ALUSel_e);

    typedef enum logic [1:0] { 
        WB_ALU = 2'd0,
        WB_MEM = 2'd1,
        WB_PC  = 2'd2
    } WBSel_e;
    localparam WBSEL_W = $bits(WBSel_e);

    typedef enum logic [2:0] { 
        IMM_I = 3'd0,
        IMM_S = 3'd1,
        IMM_B = 3'd2,
        IMM_J = 3'd3,
        IMM_U = 3'd4
    } ImmSel_e;
    localparam IMMSEL_W = $bits(ImmSel_e);

    typedef enum logic { 
        PC_4   = 1'd0,
        PC_ALU = 1'd1
    } PCSel_e;
    localparam PCSEL_W = $bits(PCSel_e);

   //---------------------------
   // 7-SEG display control
   //---------------------------
   function [6:0] bcd_to_7seg;
      input [3:0] bcd;

      case(bcd)
         4'h0: bcd_to_7seg = 7'b1000000;
         4'h1: bcd_to_7seg = 7'b1111001;	
         4'h2: bcd_to_7seg = 7'b0100100; 	
         4'h3: bcd_to_7seg = 7'b0110000; 	
         4'h4: bcd_to_7seg = 7'b0011001; 	
         4'h5: bcd_to_7seg = 7'b0010010; 	
         4'h6: bcd_to_7seg = 7'b0000010; 	
         4'h7: bcd_to_7seg = 7'b1111000; 	
         4'h8: bcd_to_7seg = 7'b0000000; 	
         4'h9: bcd_to_7seg = 7'b0011000; 	
         4'ha: bcd_to_7seg = 7'b0001000;
         4'hb: bcd_to_7seg = 7'b0000011;
         4'hc: bcd_to_7seg = 7'b1000110;
         4'hd: bcd_to_7seg = 7'b0100001;
         4'he: bcd_to_7seg = 7'b0000110;
         4'hf: bcd_to_7seg = 7'b0001110;
         default: bcd_to_7seg = '0; // No benefit if adding this line, just to make sure it will not generate latch if not enough cases. Safety first :)
      endcase      
   endfunction // End 7-SEG display control

    /* verilator lint_off UNUSEDPARAM */
endpackage

`endif 
