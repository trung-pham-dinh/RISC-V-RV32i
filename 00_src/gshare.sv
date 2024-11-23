module gshare #(
    PC_WIDTH     = 32, 
    INST_WIDTH   = 32, 

    BTB_ADDR_W   = 9, // BTB: branch table buffer. Increase this will increase hit rate
    PTH_ADDR_W   = 8, // PTH: pattern history table. Increase this will increase accuracy 
    N_BIT_SCHEME = 2  // N-bit saturated counter
) (
      input  logic i_clk
    , input  logic i_rst_n

    , input  logic [PC_WIDTH-1:0] i_pc
    , output logic                o_hit
    , output logic                o_taken
    , output logic [PC_WIDTH-1:0] o_next_pc

    // update BTB
    , input  logic                i_upd_btb_vld
    /* verilator lint_off UNUSEDSIGNAL */
    , input  logic [PC_WIDTH-1:0] i_upd_btb_pc
    /* verilator lint_off UNUSEDSIGNAL */
    , input  logic [PC_WIDTH-1:0] i_upd_btb_br_addr

    // update PHT
    , input  logic                i_upd_pht_vld
    /* verilator lint_off UNUSEDSIGNAL */
    , input  logic [PC_WIDTH-1:0] i_upd_pht_pc
    /* verilator lint_off UNUSEDSIGNAL */
    , input  logic                i_upd_pht_taken
);
    localparam PC_LOWER_UNUSED = $clog2(INST_WIDTH/8);
    localparam PTH_DEPTH = 2**PTH_ADDR_W;
    localparam BTB_DEPTH = 2**BTB_ADDR_W;
    localparam TAG_WIDTH = PC_WIDTH - BTB_ADDR_W - PC_LOWER_UNUSED;

    typedef struct packed {
        logic [TAG_WIDTH-1:0] tag; 
        logic [PC_WIDTH-1:0]  br_addr; 
        logic                 vld; 
    } BtbEntry_s;

//////////////////////////////////////////////////////////////////////////
// Branch table buffer
//////////////////////////////////////////////////////////////////////////   
    BtbEntry_s             btb       [BTB_DEPTH-1:0];
    BtbEntry_s             btb_entry;
    logic [BTB_ADDR_W-1:0] pc_btb_idx;
    logic [BTB_ADDR_W-1:0] pc_btb_upd_idx;
    logic [TAG_WIDTH-1:0]  pc_btb_tag;
    logic [TAG_WIDTH-1:0]  pc_btb_upd_tag;
    logic                  predict_taken;

    assign pc_btb_idx = i_pc[PC_LOWER_UNUSED +: BTB_ADDR_W];
    assign pc_btb_tag = i_pc[PC_WIDTH-1      -: TAG_WIDTH];

    assign pc_btb_upd_idx = i_upd_btb_pc[PC_LOWER_UNUSED +: BTB_ADDR_W];
    assign pc_btb_upd_tag = i_upd_btb_pc[PC_WIDTH-1      -: TAG_WIDTH];
    always_ff @( posedge i_clk ) begin
       if(~i_rst_n) begin
        for(int i=0; i<BTB_DEPTH; i++) begin
            btb[i] <= '0; 
        end
       end 
       else begin
        if(i_upd_btb_vld) begin
            btb[pc_btb_upd_idx].tag     <= pc_btb_upd_tag;
            btb[pc_btb_upd_idx].br_addr <= i_upd_btb_br_addr;
            btb[pc_btb_upd_idx].vld     <= 1'b1;
        end
       end
    end

    always_comb begin
        // access branch table buffer entry
        btb_entry = btb[pc_btb_idx];
        // see if it is a hit
        o_hit     = (btb_entry.tag == pc_btb_tag) & btb_entry.vld;
        // select next pc based on hit and predict
        o_taken   = o_hit & predict_taken;
        o_next_pc = (o_taken)? btb_entry.br_addr : PC_WIDTH'(i_pc + 4);
    end

//////////////////////////////////////////////////////////////////////////
// Pattern history buffer
//////////////////////////////////////////////////////////////////////////   
    logic [PTH_ADDR_W-1:0]   ghr; // global history register
    logic [N_BIT_SCHEME-1:0] pht [PTH_DEPTH-1:0];
    logic [N_BIT_SCHEME-1:0] pht_entry;
    logic [N_BIT_SCHEME-1:0] pht_entry_curr, pht_entry_next;
    logic [PTH_ADDR_W-1:0]   pht_idx;
    logic [PTH_ADDR_W-1:0]   pht_upd_idx;

   // Global history register 
    always_ff @( posedge i_clk ) begin
        if(~i_rst_n) begin
           ghr <= '0;
        end
        else begin
           if(i_upd_pht_vld)  begin
            ghr <= {ghr[PTH_ADDR_W-2:0], i_upd_pht_taken};
           end
        end
    end

    assign pht_idx = ghr ^ i_pc[2 +: PTH_ADDR_W];
    always_comb begin
        pht_entry     = pht[pht_idx];
        predict_taken = pht_entry[N_BIT_SCHEME-1]; // just need to MSB to determine branch or not
    end

        
    assign pht_upd_idx = ghr ^ i_upd_pht_pc[2 +: PTH_ADDR_W];
    always_ff @( posedge i_clk ) begin
        if(~i_rst_n) begin
            for(int i=0; i<PTH_DEPTH; i++) begin
                pht[i] <= '1; 
            end
        end    
        else begin
           if(i_upd_pht_vld) begin
            pht[pht_upd_idx] <= pht_entry_next;
           end
        end
    end

    always_comb begin
        pht_entry_curr = pht[pht_upd_idx];
        if(i_upd_pht_taken)
            pht_entry_next =  (pht_entry_curr != '1)? pht_entry_curr +  N_BIT_SCHEME'('d1)  : pht_entry_curr;
        else
            pht_entry_next =  (pht_entry_curr != '0)? pht_entry_curr + {N_BIT_SCHEME{1'b1}} : pht_entry_curr; // minus 1
    end
endmodule
