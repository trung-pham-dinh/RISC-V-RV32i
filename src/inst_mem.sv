module inst_mem #(
    parameter ADDR_W = 32
)(
      input  logic [ADDR_W-1:0] i_addr
    , output logic [31:0]       o_inst
);
    localparam N_WORDS = (2**ADDR_W) / 4;

    logic [31:0] mem [0:N_WORDS-1];
    
    assign o_inst = mem[i_addr[ADDR_W-1:2]];


    // Init mem
    initial begin
        $readmemh("../SingleCycle/mem/lui.mem", mem);
    end
endmodule