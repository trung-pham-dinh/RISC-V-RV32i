module evaluation 
#(
      parameter BR_THRSH_EVAL  = 1000 // Branch instructions before evaluation
    , parameter IPC_THRSH_EVAL = 1000 // Cycles before evaluation 

    , localparam BR_CNT_W  = $clog2(BR_THRSH_EVAL+1)
    , localparam IPC_CNT_W = $clog2(IPC_THRSH_EVAL+1)
)
(
     input  logic                 i_clk
    ,input  logic                 i_rst_n

    ,input  logic                 i_is_br_inst
    ,input  logic                 i_is_br_pred_correct
    ,output logic [BR_CNT_W-1:0]  o_br_correct_eval

    ,input  logic                 i_is_inst_vld  // all valid instructions except NOP
    ,input  logic                 i_is_inst_done 
    ,output logic [IPC_CNT_W-1:0] o_ipc_eval
);
//////////////////////////////////////////////////////////////////////////
// Branch prediction evaluation
//////////////////////////////////////////////////////////////////////////
    logic [BR_CNT_W-1:0] br_correct_cnt;
    logic [BR_CNT_W-1:0] br_inst_cnt;
    logic [BR_CNT_W-1:0] br_correct_cnt_next;

    assign br_correct_cnt_next = (i_is_br_pred_correct)? br_correct_cnt+1 : br_correct_cnt;
    always_ff @( posedge i_clk ) begin
        if(~i_rst_n) begin
            o_br_correct_eval <= '0;
            br_inst_cnt       <= '0;
            br_correct_cnt    <= '0;
        end        
        else begin
            if(i_is_br_inst) begin
                if(br_inst_cnt==BR_THRSH_EVAL-1) begin
                    o_br_correct_eval <= br_correct_cnt_next;
                    br_inst_cnt       <= '0;
                    br_correct_cnt    <= '0;
                    `ifdef DV
                        $display("Branch Prediction Scoreboard: @%05d n_br_inst=%10d, n_correct=%10d", $time, BR_THRSH_EVAL, br_correct_cnt_next);
                    `endif
                end
                else begin
                    o_br_correct_eval <= o_br_correct_eval;
                    br_inst_cnt       <= br_inst_cnt+1;
                    br_correct_cnt    <= br_correct_cnt_next;
                end
            end
        end
    end
    
//////////////////////////////////////////////////////////////////////////
// IPC: Instructions per cycle
//////////////////////////////////////////////////////////////////////////
    logic [IPC_CNT_W-1:0] cycle_cnt;
    logic [IPC_CNT_W-1:0] inst_cnt;
    logic [IPC_CNT_W-1:0] inst_cnt_next;

    assign inst_cnt_next = (i_is_inst_vld & i_is_inst_done)? inst_cnt+1 : inst_cnt;
    always_ff @( posedge i_clk ) begin
        if(~i_rst_n) begin
            o_ipc_eval <= '0;
            cycle_cnt  <= '0;
            inst_cnt   <= '0;
        end
        else begin
            if(cycle_cnt==IPC_THRSH_EVAL-1) begin
                o_ipc_eval <= inst_cnt_next;
                cycle_cnt  <= '0;
                inst_cnt   <= '0;
                `ifdef DV
                    $display("IPC: @%05d n_cycles=%10d, instrucions=%10d", $time, IPC_THRSH_EVAL, inst_cnt_next);
                `endif
            end
            else begin
                o_ipc_eval <= o_ipc_eval;
                cycle_cnt  <= cycle_cnt + 1;
                inst_cnt   <= inst_cnt_next;
            end
        end
    end

endmodule
