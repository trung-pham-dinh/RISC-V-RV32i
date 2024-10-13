module regfile
    import rv32i_pkg::*;
(
      input  logic i_clk
    , input  logic i_rst

    , input  logic [REGIDX_WIDTH-1:0] i_rs1_addr
    , input  logic [REGIDX_WIDTH-1:0] i_rs2_addr
    , input  logic [REGIDX_WIDTH-1:0] i_rd_addr
    , input  logic                    i_rd_wen
    , input  logic [31:0]             i_rd_data

    , output logic [31:0]             o_rs1_data
    , output logic [31:0]             o_rs2_data
);
    logic [31:0] regs [0:31];


    assign o_rs1_data = regs[i_rs1_addr];
    assign o_rs2_data = regs[i_rs2_addr];

    assign regs[0] = '0;
    generate
        for(genvar i=1; i<32; i++) begin
            always_ff @( posedge i_clk ) begin
                if(i_rst) begin
                    regs[i] <= '0; 
                end
                else begin
                    regs[i] <= (i_rd_wen & (REGIDX_WIDTH'(i)==i_rd_addr)) ? i_rd_data : regs[i]; 
                end
            end
        end        
    endgenerate
endmodule