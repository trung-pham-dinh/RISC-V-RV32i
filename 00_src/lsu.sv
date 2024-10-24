module lsu 
    import singlecycle_pkg::*;
#(
    parameter ADDR_W = 7 
)
(
      input  logic        i_clk
    , input  logic        i_rst_n

    , input  logic [ADDR_W-1:0] i_addr
    , input  logic [31:0]       i_st_data
    , input  logic [3:0]        i_st_strb // each strobe bit is corresponding to each byte
    , input  logic              i_st_mem
    , output logic [31:0]       o_ld_data

    // I/O
    , output logic [31:0] o_io_ledr
    , output logic [31:0] o_io_ledg
    , output logic [6:0]  o_io_hex0
    , output logic [6:0]  o_io_hex1
    , output logic [6:0]  o_io_hex2
    , output logic [6:0]  o_io_hex3
    , output logic [6:0]  o_io_hex4
    , output logic [6:0]  o_io_hex5
    , output logic [6:0]  o_io_hex6
    , output logic [6:0]  o_io_hex7
    , output logic [31:0] o_io_lcd
    , input  logic [31:0] i_io_sw
    , input  logic [3:0]  i_io_btn 
);
    always_comb begin // temporarily assigned, must delete after actually driving
        o_io_ledr = mem[0];
        o_io_ledg = mem[1];
        o_io_hex0 = mem[2][6:0];
        o_io_hex1 = mem[3][6:0];
        o_io_hex2 = mem[4][6:0];
        o_io_hex3 = mem[5][6:0];
        o_io_hex4 = mem[6][6:0];
        o_io_hex5 = mem[7][6:0];
        o_io_hex6 = mem[8][6:0];
        o_io_hex7 = mem[9][6:0];
        o_io_lcd  = '0;
    end

    localparam MEM_DEPTH = (2**ADDR_W)/4;
    logic [31:0] mem [0:MEM_DEPTH-1];

    assign o_ld_data = mem[i_addr[ADDR_W-1:2]];
    generate
        genvar i;
        for(i=0; i< MEM_DEPTH; i++) begin: g_mem
            always_ff @( posedge i_clk ) begin
                if(i_st_mem & (i_addr[ADDR_W-1:2]==(ADDR_W-2)'(i))) begin
                    for(int b=0; b<4; b++) begin
                        mem[i][b*8+:8] <= (i_st_strb[b])? i_st_data[b*8+:8] : mem[i][b*8+:8];
                    end
                end
                else begin
                    mem[i] <= mem[i];
                end
            end
        end
    endgenerate
endmodule
