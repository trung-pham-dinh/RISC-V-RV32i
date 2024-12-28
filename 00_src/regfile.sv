module regfile
    import rv32i_pkg::*;
(
      input  logic i_clk
    , input  logic i_rst_n

    , input  logic [REGIDX_WIDTH-1:0] i_rs1_addr
    , input  logic [REGIDX_WIDTH-1:0] i_rs2_addr
    , input  logic [REGIDX_WIDTH-1:0] i_rd_addr
    , input  logic                    i_rd_wen
    , input  logic [31:0]             i_rd_data

    , output logic [31:0]             o_rs1_data
    , output logic [31:0]             o_rs2_data
);
    logic [31:0] regs [0:31];

    // read the write value: resolve hazard at ID-WB stage
    assign o_rs1_data = ((i_rs1_addr == i_rd_addr) & i_rd_wen & |i_rd_addr)? i_rd_data : regs[i_rs1_addr];
    assign o_rs2_data = ((i_rs2_addr == i_rd_addr) & i_rd_wen & |i_rd_addr)? i_rd_data : regs[i_rs2_addr];

    assign regs[0] = '0;
    generate
		genvar i;
        for(i=1; i<32; i++) begin: g_regfile
            always_ff @( posedge i_clk ) begin
                if(~i_rst_n) begin
                    regs[i] <= '0; 
                end
                else begin
                    regs[i] <= (i_rd_wen & (REGIDX_WIDTH'(i)==i_rd_addr)) ? i_rd_data : regs[i]; 
                end
            end
        end        
    endgenerate
endmodule
