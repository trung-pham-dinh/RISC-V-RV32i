module alu 
    import rv32i_pkg::*;
(
      input  logic [31:0] i_operand_a,
      input  logic [31:0] i_operand_b,
      input  ALUSel_e     i_alu_op,
      output logic [31:0] o_alu_res
);

logic [32:0] sign_rs1;            // extra sign bit for signed operands
logic [32:0] sign_rs2;            // extra sign bit for signed operands
logic [32:0] usign_rs1;           // extra sign bit for unsigned operands
logic [32:0] usign_rs2;           // extra sign bit for unsigned operands
logic [32:0] negative_usign_rs2;  // extra sign bit for unsigned subtraction
logic [32:0] negative_sign_rs2;   // extra sign bit for signed subtraction
logic [32:0] sub_usign;           // result of unsigned subtraction
logic [32:0] sub_sign;            // result of signed subtraction
logic [31:0] resultinstr_sll, resultinstr_srl, result_sra;

//  Addition (using a full-adder)
function logic [32:0] instr_add(input logic [31:0] a, input logic [31:0] b);
    logic carry;
    logic [32:0] sum;
    carry = 0;
    for (int i = 0; i < 32; i++) begin
        sum[i] = a[i] ^ b[i] ^ carry;
        carry = (a[i] & b[i]) | ((a[i] ^ b[i]) & carry);
    end
    sum[32] = carry;
    return sum;
endfunction

//  Two's complement subtraction (by adding the negated operand)
function logic [32:0] instr_sub(input logic [31:0] a, input logic [31:0] b);
    return instr_add(a, ~b + 1); 
endfunction

//  Shift left logical (SLL)
function logic [31:0] instr_sll(input logic [31:0] a, input logic [31:0] shamt);
    logic [31:0] result;
    result = a;
    for (int i = 0; i < shamt; i++) begin
        result = result << 1;
    end
    return result;
endfunction

//  Shift right logical (SRL)
function logic [31:0] instr_srl(input logic [31:0] a, input logic [31:0] shamt);
    logic [31:0] result;
    result = a;
    for (int i = 0; i < shamt; i++) begin
        result = result >> 1;
    end
    return result;
endfunction

//  Shift right arithmetic (SRA)
function logic [31:0] instr_sra(input logic signed [31:0] a, input logic [31:0] shamt);
    logic signed [31:0] result;
    result = a;
    for (int i = 0; i < shamt; i++) begin
        result = result >>> 1; // preserves the sign bit
    end
    return result;
endfunction

always_comb begin
    case (i_alu_op)
        ALUinstr_add : o_alu_res = instr_add(i_operand_a, i_operand_b)[31:0];     //  ADD
        ALUinstr_sub : o_alu_res = instr_sub(i_operand_a, i_operand_b)[31:0];     //  SUB
        ALU_XOR : o_alu_res = i_operand_a ^ i_operand_b;                          //  XOR
        ALU_OR  : o_alu_res = i_operand_a | i_operand_b;                          //  OR
        ALU_AND : o_alu_res = i_operand_a & i_operand_b;                          //  AND
        
        //  SLL (Shift Left Logical)
        ALU_SLL : o_alu_res = instr_sll(i_operand_a, i_operand_b[4:0]);
        
        //  SRL (Shift Right Logical)
        ALU_SRL : o_alu_res = instr_srl(i_operand_a, i_operand_b[4:0]);
        
        //  SRA (Shift Right Arithmetic)
        ALU_SRA : o_alu_res = instr_sra(i_operand_a, i_operand_b[4:0]);
        
        // SLT (Set Less Than) using signed comparison
        ALU_SLT : begin
            sign_rs1 = {i_operand_a[31], i_operand_a};
            sign_rs2 = {i_operand_b[31], i_operand_b};
            negative_sign_rs2 = instr_sub(32'b0, sign_rs2); // 0 - sign_rs2
            sub_sign = instr_add(sign_rs1, negative_sign_rs2);
            o_alu_res = sub_sign[32];  // MSB is set if a < b (signed)
        end
        
        // SLTU (Set Less Than Unsigned) using unsigned comparison
        ALU_SLTU: begin
            usign_rs1 = {1'b0, i_operand_a};
            usign_rs2 = {1'b0, i_operand_b};
            negative_usign_rs2 = instr_sub(32'b0, usign_rs2); // 0 - usign_rs2
            sub_usign = instr_add(usign_rs1, negative_usign_rs2);
            o_alu_res = sub_usign[32];  // MSB is set if a < b (unsigned)
        end
        
        default: o_alu_res = '0;  // Default case
    endcase
end

endmodule
