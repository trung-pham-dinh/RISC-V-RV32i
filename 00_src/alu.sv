module alu 
    import singlecycle_pkg::*;
(
      input  logic [31:0] i_operand_a
    , input  logic [31:0] i_operand_b
    , input  ALUSel_e     i_alu_op
    , output logic [31:0] o_alu_res
);

    always_comb begin
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
                o_alu_res = '0; // FIXME: remove previous operation for lint clean
            end
            ALU_SLTU: begin
                o_alu_res = '0; // FIXME: remove previous operation for lint clean
            end
            default: o_alu_res = '0;
        endcase
    end

endmodule
