module alu 
    import rv32i_pkg::*;
(
      input  logic [31:0] i_operand_a
    , input  logic [31:0] i_operand_b
    , input  ALUSel_e     i_alu_op
    , output logic [31:0] o_alu_data
);

   assign o_alu_data ='0; 
endmodule