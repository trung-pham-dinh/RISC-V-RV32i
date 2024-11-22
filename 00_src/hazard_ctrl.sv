module hazard_ctrl 
  import singlecycle_pkg::*;
(
  /* verilator lint_off UNUSEDSIGNAL */
    input  logic i_is_pred_need_br
  , input  logic i_is_jal_inst
  , input  logic i_lsu_VALID
  , input  logic i_lsu_READY
  , input  logic i_is_depend_load
  , input  logic i_is_pred_wrong
  , input  logic i_is_jalr_inst
  /* verilator lint_off UNUSEDSIGNAL */

  // hazard controls
  , output logic o_pc_en

  , output logic o_IF_ID_dreg_en
  , output logic o_IF_ID_creg_en
  , output logic o_IF_ID_flush

  , output logic o_ID_EX_dreg_en
  , output logic o_ID_EX_creg_en
  , output logic o_ID_EX_flush

  , output logic o_EX_MEM_dreg_en
  , output logic o_EX_MEM_creg_en
  , output logic o_EX_MEM_flush

  , output logic o_MEM_WB_dreg_en
  , output logic o_MEM_WB_creg_en
  , output logic o_MEM_WB_flush
);

// predict that need to branch at ID

logic [4:0] is_pred_need_br_EN;
logic [4:0] is_pred_need_br_FLUSH;

always_comb begin
  if(i_is_pred_need_br) begin
    //                       PC   ,IF/ID ,ID/EX ,EX/ME ,ME/WB
    is_pred_need_br_EN    = {1'b1 ,1'b1  ,1'b1  ,1'b1  ,1'b1}; 
    is_pred_need_br_FLUSH = {1'b0 ,1'b1  ,1'b0  ,1'b0  ,1'b0}; 
  end
  else begin
    //                      
    is_pred_need_br_EN    = '1; 
    is_pred_need_br_FLUSH = '0; 
  end
end

// jump instruction at ID

logic [4:0] is_jal_inst_EN;
logic [4:0] is_jal_inst_FLUSH;

always_comb begin
  if(i_is_jal_inst) begin
    //                   PC   ,IF/ID ,ID/EX ,EX/ME ,ME/WB
    is_jal_inst_EN    = {1'b1 ,1'b1  ,1'b1  ,1'b1  ,1'b1}; 
    is_jal_inst_FLUSH = {1'b0 ,1'b1  ,1'b0  ,1'b0  ,1'b0}; 
  end
  else begin
    is_jal_inst_EN    = '1; 
    is_jal_inst_FLUSH = '0; 
  end
end

// request LSU at MEM

logic [4:0] is_lsu_VALID_EN;
logic [4:0] is_lsu_VALID_FLUSH;

always_comb begin
  if(i_lsu_VALID & ~i_lsu_READY) begin
    //                    PC   ,IF/ID ,ID/EX ,EX/ME ,ME/WB
    is_lsu_VALID_EN    = {1'b0 ,1'b0  ,1'b0  ,1'b0  ,1'b1}; 
    is_lsu_VALID_FLUSH = {1'b0 ,1'b0  ,1'b0  ,1'b0  ,1'b1}; 
  end
  else begin
    is_lsu_VALID_EN    = '1; 
    is_lsu_VALID_FLUSH = '0; 
  end
end

// Load followed by instruction depend on read result

logic [4:0] is_depend_load_EN;
logic [4:0] is_depend_load_FLUSH;

always_comb begin
  if(i_is_depend_load) begin
    //                      PC   ,IF/ID ,ID/EX ,EX/ME ,ME/WB
    is_depend_load_EN    = {1'b0 ,1'b0  ,1'b1  ,1'b1  ,1'b1}; 
    is_depend_load_FLUSH = {1'b0 ,1'b0  ,1'b1  ,1'b0  ,1'b0}; 
  end
  else begin
    is_depend_load_EN    = '1; 
    is_depend_load_FLUSH = '0; 
  end
end

// branch prediction wrong

logic [4:0] is_pred_wrong_EN;
logic [4:0] is_pred_wrong_FLUSH;

always_comb begin
  if(i_is_pred_wrong) begin
    //                     PC   ,IF/ID ,ID/EX ,EX/ME ,ME/WB
    is_pred_wrong_EN    = {1'b1 ,1'b1  ,1'b1  ,1'b1  ,1'b1}; 
    is_pred_wrong_FLUSH = {1'b0 ,1'b1  ,1'b1  ,1'b0  ,1'b0}; 
  end
  else begin
    is_pred_wrong_EN    = '1; 
    is_pred_wrong_FLUSH = '0; 
  end
end

// JALR

logic [4:0] is_jalr_inst_EN;
logic [4:0] is_jalr_inst_FLUSH;

always_comb begin
  if(i_is_jalr_inst) begin
    //                    PC   ,IF/ID ,ID/EX ,EX/ME ,ME/WB
    is_jalr_inst_EN    = {1'b1 ,1'b1  ,1'b1  ,1'b1  ,1'b1}; 
    is_jalr_inst_FLUSH = {1'b0 ,1'b1  ,1'b1  ,1'b0  ,1'b0}; 
  end
  else begin
    is_jalr_inst_EN    = '1; 
    is_jalr_inst_FLUSH = '0; 
  end
end

// Combine all
logic dump_c, dump_pc;
always_comb begin
  {dump_c, o_IF_ID_creg_en, o_ID_EX_creg_en, o_EX_MEM_creg_en, o_MEM_WB_creg_en} 
    = ( is_pred_need_br_EN 
      & is_jal_inst_EN
      & is_lsu_VALID_EN
      & is_depend_load_EN
      & is_pred_wrong_EN
      & is_jalr_inst_EN );
  {o_pc_en, o_IF_ID_dreg_en, o_ID_EX_dreg_en, o_EX_MEM_dreg_en, o_MEM_WB_dreg_en} 
    = ( is_pred_need_br_EN 
      & is_jal_inst_EN
      & is_lsu_VALID_EN
      & is_depend_load_EN
      & is_pred_wrong_EN
      & is_jalr_inst_EN );
  {dump_pc, o_IF_ID_flush, o_ID_EX_flush, o_EX_MEM_flush, o_MEM_WB_flush} 
    = ( is_pred_need_br_FLUSH 
      | is_jal_inst_FLUSH
      | is_lsu_VALID_FLUSH
      | is_depend_load_FLUSH
      | is_pred_wrong_FLUSH
      | is_jalr_inst_FLUSH );
end

endmodule

