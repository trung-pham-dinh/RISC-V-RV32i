module alu 
    import singlecycle_pkg::*;
(
      input  logic [31:0] i_operand_a
    , input  logic [31:0] i_operand_b
    , input  ALUSel_e     i_alu_op
    , output logic [31:0] o_alu_res
);

// Addition (using full-adder with overflow detection)
function logic [32:0] instr_add(input logic [31:0] a, input logic [31:0] b, output logic overflow);
    logic carry;
    logic [32:0] sum;
    carry = 0;
    overflow = 0;
    for (int i = 0; i < 32; i++) begin
        sum[i] = a[i] ^ b[i] ^ carry;
        carry = (a[i] & b[i]) | ((a[i] ^ b[i]) & carry);
    end
    sum[32] = carry;
    
    // Check for overflow: if both operands have the same sign, and the result has a different sign
    overflow = (a[31] == b[31]) && (sum[31] != a[31]);
    return sum;
endfunction

// Subtraction (with overflow detection)
function logic [32:0] instr_sub(input logic [31:0] a, input logic [31:0] b, output logic overflow);
    return instr_add(a, ~b + 1, overflow);  // equivalent to a - b, use two's complement of b
endfunction

// Shift Left Logical (SLL)
function logic [31:0] instr_sll(input logic [31:0] a, input logic [4:0] shamt);
    logic [31:0] result;
    result = a;
    
    // Shift 1 bit at a time using MUX logic
    if (shamt[0]) result = {result[30:0], 1'b0};
    if (shamt[1]) result = {result[29:0], 2'b00};
    if (shamt[2]) result = {result[27:0], 4'b0000};
    if (shamt[3]) result = {result[23:0], 8'b00000000};
    if (shamt[4]) result = {result[15:0], 16'b0000000000000000};

    return result;
endfunction

// Shift Right Logical (SRL)
function logic [31:0] instr_srl(input logic [31:0] a, input logic [4:0] shamt);
    logic [31:0] result;
    result = a;
    
    // Shift 1 bit at a time using MUX logic
    if (shamt[0]) result = {1'b0, result[31:1]};
    if (shamt[1]) result = {2'b00, result[31:2]};
    if (shamt[2]) result = {4'b0000, result[31:4]};
    if (shamt[3]) result = {8'b00000000, result[31:8]};
    if (shamt[4]) result = {16'b0000000000000000, result[31:16]};

    return result;
endfunction

// Shift Right Arithmetic (SRA)
function logic [31:0] instr_sra(input logic [31:0] a, input logic [4:0] shamt);
    logic signed [31:0] result;
    result = a;
    
    // Sign extend and shift using MUX logic
    if (shamt[0]) result = {{1{result[31]}}, result[31:1]};
    if (shamt[1]) result = {{2{result[31]}}, result[31:2]};
    if (shamt[2]) result = {{4{result[31]}}, result[31:4]};
    if (shamt[3]) result = {{8{result[31]}}, result[31:8]};
    if (shamt[4]) result = {{16{result[31]}}, result[31:16]};

    return result;
endfunction

// Function for SLT (Set Less Than - Signed comparison)
function logic [31:0] instr_slt(input logic [31:0] a, input logic [31:0] b);
    logic [32:0] sign_rs1;
    logic [32:0] sign_rs2;
    logic [32:0] negative_sign_rs2;
    logic [32:0] sub_sign;

    sign_rs1 = {a[31], a};  // Sign extend for signed comparison
    sign_rs2 = {b[31], b};  // Sign extend for signed comparison
    negative_sign_rs2 = 33'((~sign_rs2) + 33'b1); // Two's complement of usign_rs2
    sub_sign  = 33'(sign_rs1  + negative_sign_rs2); // Perform subtraction
    return {31'b0,sub_sign[32]};  // MSB indicates result of comparison
endfunction

// Function for SLTU (Set Less Than Unsigned comparison)
function logic [31:0] instr_sltu(input logic [31:0] a, input logic [31:0] b);
    logic [32:0] usign_rs1;
    logic [32:0] usign_rs2;
    logic [32:0] negative_usign_rs2;
    logic [32:0] sub_usign;

    usign_rs1 = {1'b0, a};  // Zero extend for unsigned comparison
    usign_rs2 = {1'b0, b};  // Zero extend for unsigned comparison
    negative_usign_rs2 = 33'((~usign_rs2) + 33'b1); // Two's complement of usign_rs2
    sub_usign = 33'(usign_rs1 + negative_usign_rs2); // Perform subtraction
    return {31'b0,sub_usign[32]};  // MSB indicates result of comparison
endfunction

logic overflow_flag;  // Internal signal for detecting overflow

always_comb begin
    // Ensure `o_overflow` is always assigned a value
    o_overflow = 1'b0;  // Default: no overflow

    case (i_alu_op)
        ALU_ADD  : begin
            o_alu_res = instr_add(i_operand_a, i_operand_b, overflow_flag)[31:0];  // ADD
            o_overflow = overflow_flag;  
        end
        ALU_SUB  : begin
            o_alu_res = instr_sub(i_operand_a, i_operand_b, overflow_flag)[31:0];  // SUB
            o_overflow = overflow_flag;  
        end
        ALU_XOR  : begin
            o_alu_res = i_operand_a ^ i_operand_b;  // XOR
            o_overflow = 1'b0;  // No overflow for XOR
        end
        ALU_OR   : begin
            o_alu_res = i_operand_a | i_operand_b;  // OR
            o_overflow = 1'b0;  // No overflow for OR
        end
        ALU_AND  : begin
            o_alu_res = i_operand_a & i_operand_b;  // AND
            o_overflow = 1'b0;  // No overflow for AND
        end
        ALU_SLL  : begin
            o_alu_res = instr_sll(i_operand_a, i_operand_b[4:0]);  // SLL
            o_overflow = 1'b0;  // No overflow for SLL
        end
        ALU_SRL  : begin
            o_alu_res = instr_srl(i_operand_a, i_operand_b[4:0]);  // SRL
            o_overflow = 1'b0;  // No overflow for SRL
        end
        ALU_SRA  : begin
            o_alu_res = instr_sra(i_operand_a, i_operand_b[4:0]);  // SRA
            o_overflow = 1'b0;  // No overflow for SRA
        end
        ALU_SLT  : begin
            o_alu_res = instr_slt(i_operand_a, i_operand_b);  // SLT
            o_overflow = 1'b0;  // No overflow for SLT
        end
        ALU_SLTU : begin
            o_alu_res = instr_sltu(i_operand_a, i_operand_b);  // SLTU
            o_overflow = 1'b0;  // No overflow for SLTU
        end
        default  : begin
            o_alu_res = 32'b0;  // Default case
            o_overflow = 1'b0;  // Default: no overflow
        end
    endcase
end

endmodule