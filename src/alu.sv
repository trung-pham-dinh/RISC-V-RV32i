module alu 
    import rv32i_pkg::*;
(
      input  logic [31:0] i_operand_a
    , input  logic [31:0] i_operand_b
    , input  ALUSel_e     i_alu_op
    , output logic [31:0] o_alu_res
);
logic [32:0] sign_rs1; // extra sign bit
logic [32:0] sign_rs2; // extra sign bit
logic [32:0] usign_rs1; // extra sign bit
logic [32:0] usign_rs2; // extra sign bit
logic [32:0] negative_usign_rs2; // extra sign bit
logic [32:0] negative_sign_rs2; // extra sign bit
logic [32:0] sub_usign; // extra sign bit
logic [32:0] sub_sign; // extra sign bit

    always_comb begin : blockName
        case (i_alu_op)
            ALU_ADD : o_alu_res = i_operand_a + i_operand_b;
            ALU_SUB : o_alu_res = i_operand_a - i_operand_b;
            ALU_XOR : o_alu_res = i_operand_a ^ i_operand_b;
            ALU_OR  : o_alu_res = i_operand_a | i_operand_b;
            ALU_AND : o_alu_res = i_operand_a & i_operand_b;
            ALU_SLL : o_alu_res = i_operand_a << i_operand_b;
            ALU_SRL : o_alu_res = i_operand_a >> i_operand_b;
            ALU_SRA : o_alu_res = i_operand_a >>> i_operand_b;
            ALU_SLT : begin
                sign_rs1     = {i_operand_a[31], i_operand_a};
                sign_rs2     = {i_operand_b[31], i_operand_b};
                negative_sign_rs2   = 33'((~sign_rs2) + 32'b1); // extra sign bit
                sub_sign  = 33'(sign_rs1  + negative_sign_rs2);
                o_alu_res = sub_sign[32];
            end
            ALU_SLTU: begin
                usign_rs1     = {i_operand_a[31], i_operand_a};
                usign_rs2     = {i_operand_b[31], i_operand_b};
                negative_usign_rs2   = 33'((~usign_rs2) + 32'b1); // extra sign bit
                sub_usign  = 33'(usign_rs1  + negative_usign_rs2);
                o_alu_res = sub_usign[32];
            end
            default: o_alu_res = '0;
        endcase
    end

endmodule