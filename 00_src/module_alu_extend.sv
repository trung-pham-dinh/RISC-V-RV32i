module alu 
    import singlecycle_pkg::*;
(
      input  logic [31:0] i_operand_a
    , input  logic [31:0] i_operand_b
    , input  ALUSel_e     i_alu_op
    , output logic [31:0] o_alu_res
    , output logic        o_overflow
);

// Addition (using full-adder with overflow detection)
function logic [32:0] instr_add(input logic [31:0] a, input logic [31:0] b, output logic overflow);
    logic [32:0] sum;
    overflow = 0;
    sum[32] = a + b;
    
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

// Multiplication
function logic [63:0] instr_mul(input logic [31:0] a, input logic [31:0] b, output logic overflow);
    logic [63:0] result;
    logic [63:0] temp_a;
    result = 64'b0;
    temp_a = {32'b0, a};
    
    for (int i = 0; i < 32; i++) begin
        if (b[i]) begin
            // Use repeated addition instead of shift
            logic [63:0] shifted_a;
            shifted_a = temp_a;
            for (int j = 0; j < i; j++) begin
                shifted_a = {shifted_a[62:0], 1'b0}; // Manual bit shifting using concatenation
            end
            result = result + shifted_a;
        end
    end
    
    // Check overflow using bitwise OR reduction
    overflow = |result[63:32];
    return result;
endfunction

// Division
function logic [31:0] instr_div(input logic [31:0] a, input logic [31:0] b, output logic overflow);
    logic [31:0] quotient, remainder;
    logic [31:0] temp_remainder;
    logic [31:0] power_of_two;
    quotient = 32'b0;
    remainder = 32'b0;
    overflow = (b == 32'b0);  // Keep divide-by-zero check
    
    if (!overflow) begin
        // Initialize power_of_two with MSB set
        power_of_two = 32'h80000000;  // This is a constant
        
        for (int i = 31; i >= 0; i--) begin
            // Manual shift using concatenation for remainder
            temp_remainder = {remainder[30:0], a[i]};
            
            // Use subtraction function to compare
            logic temp_overflow;
            logic [32:0] sub_result;
            sub_result = instr_sub(temp_remainder, b, temp_overflow);
            
            // If subtraction doesn't set MSB (meaning temp_remainder >= b)
            if (!sub_result[32]) begin
                remainder = sub_result[31:0];
                quotient = quotient | power_of_two;  // Set the bit using OR
            end else begin
                remainder = temp_remainder;
            end
            
            // Update power_of_two for next iteration using concatenation
            power_of_two = {power_of_two[30:0], 1'b0};
        end
    end
    return quotient;
endfunction

// Modulus
function logic [31:0] instr_exp(input logic [31:0] a, input logic [31:0] b, output logic overflow);
    logic [31:0] result;
    logic [63:0] temp;
    result = 32'b1;
    overflow = 0;
    
    for (int i = 0; i < 32; i++) begin
        if (b[i]) begin
            temp = instr_mul(result, a, overflow);
            if (overflow) break;
            result = temp[31:0];
        end
        // Square a without using multiplication operator
        temp = instr_mul(a, a, overflow);
        if (overflow) break;
        a = temp[31:0];
    end
    return result;
endfunction

// Exponential
function logic [31:0] instr_exp(input logic [31:0] a, input logic [31:0] b, output logic overflow);
    logic [31:0] result;
    logic [63:0] temp;
    result = 32'b1;
    overflow = 0;
    for (int i = 0; i < 32; i++) begin
        if (b[i]) begin
            temp = instr_mul(result, a, overflow);
            if (overflow) break;
            result = temp[31:0];
        end
        temp = instr_mul(a, a, overflow);
        if (overflow) break;
        a = temp[31:0];
    end
    return result;
endfunction

// Floor division (same as regular division for unsigned integers)
function logic [31:0] instr_floor_div(input logic [31:0] a, input logic [31:0] b, output logic overflow);
    return instr_div(a, b, overflow);
endfunction

always_comb begin
    // Default assignments
    o_alu_res = 32'b0;
    o_overflow = 1'b0;

    case (i_alu_op)
        ALU_ADD  : begin
            {o_overflow, o_alu_res} = instr_add(i_operand_a, i_operand_b, o_overflow);
        end
        ALU_SUB  : begin
            {o_overflow, o_alu_res} = instr_sub(i_operand_a, i_operand_b, o_overflow);
        end
        ALU_XOR  : begin
            o_alu_res = i_operand_a ^ i_operand_b;
        end
        ALU_OR   : begin
            o_alu_res = i_operand_a | i_operand_b;
        end
        ALU_AND  : begin
            o_alu_res = i_operand_a & i_operand_b;
        end
        ALU_SLL  : begin
            o_alu_res = instr_sll(i_operand_a, i_operand_b[4:0]);
        end
        ALU_SRL  : begin
            o_alu_res = instr_srl(i_operand_a, i_operand_b[4:0]);
        end
        ALU_SRA  : begin
            o_alu_res = instr_sra(i_operand_a, i_operand_b[4:0]);
        end
        ALU_SLT  : begin
            o_alu_res = instr_slt(i_operand_a, i_operand_b);
        end
        ALU_SLTU : begin
            o_alu_res = instr_sltu(i_operand_a, i_operand_b);
        end
        ALU_MUL  : begin
            o_alu_res = instr_mul(i_operand_a, i_operand_b, o_overflow)[31:0];
        end
        ALU_DIV  : begin
            o_alu_res = instr_div(i_operand_a, i_operand_b, o_overflow);
        end
        ALU_MOD  : begin
            o_alu_res = instr_mod(i_operand_a, i_operand_b, o_overflow);
        end
        ALU_EXP  : begin
            o_alu_res = instr_exp(i_operand_a, i_operand_b, o_overflow);
        end
        ALU_FLOOR_DIV : begin
            o_alu_res = instr_floor_div(i_operand_a, i_operand_b, o_overflow);
        end
        default  : begin
            o_alu_res = 32'b0;
            o_overflow = 1'b0;
        end
    endcase
end

endmodule