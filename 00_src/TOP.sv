module TOP (
      input logic         CLOCK_50
    , input logic  [9:0]  SW
    , input logic  [3:0]  KEY

    , output logic [8:0]  LEDG
    , output logic [17:0] LEDR

    , output logic [6:0]  HEX0
    , output logic [6:0]  HEX1
    , output logic [6:0]  HEX2
    , output logic [6:0]  HEX3
    , output logic [6:0]  HEX4
    , output logic [6:0]  HEX5
    , output logic [6:0]  HEX6
    , output logic [6:0]  HEX7

    , output logic [7:0]  LCD_DATA
    , output logic        LCD_RW
    , output logic        LCD_EN
    , output logic        LCD_RS
    , output logic        LCD_ON
    // , output logic        LCD_BLON // DE2 has no backlight
);

    logic [3:0] KEY_db;

// KEY ///////////////////////////////////////////
    generate
        genvar k;
        for (k = 0; k<4; k++) begin: g_btn_db
            btn_debounce #(
                .STABLE_TIME_MS(40),
                .CLK_PERIOD_NS (20) // clock 50MHz
            ) btn_debounce (
                .i_clk(CLOCK_50 ), 
                .i_rst_n(SW[0]  ),
                .i_btn(KEY[k]   ),
                .o_btn(KEY_db[k])
            ); 
        end
    endgenerate

// LCD ///////////////////////////////////////////
    logic [31:0] io_lcd;
    // assign LCD_BLON = 1'b1; // DE2 has no backlight

    assign LCD_ON   = io_lcd[31];
    assign LCD_EN   = io_lcd[10];
    assign LCD_RS   = io_lcd[9];
    assign LCD_RW   = io_lcd[8];
    assign LCD_DATA = io_lcd[7:0];

/////////////////////////////////////////////////
// RISC-V
////////////////////////////////////////////////

    singlecycle singlecycle(
    .i_clk     (CLOCK_50  ), 
    .i_rst_n   (SW[0]     ),   
    .o_io_ledg (LEDG[8:0] ),
    .o_io_ledr (LEDR[17:0]),
    .o_io_hex0 (HEX0      ),     
    .o_io_hex1 (HEX1      ),     
    .o_io_hex2 (HEX2      ),     
    .o_io_hex3 (HEX3      ),     
    .o_io_hex4 (HEX4      ),     
    .o_io_hex5 (HEX5      ),     
    .o_io_hex6 (HEX6      ),     
    .o_io_hex7 (HEX7      ),     
    .o_io_lcd  (io_lcd    ),
    .i_io_sw   (SW[9:0]   ),   
    .i_io_btn  (KEY_db    )    
    );
endmodule
