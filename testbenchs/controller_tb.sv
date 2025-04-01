`timescale 1ns / 1ns

module controller_tb();

reg clk, rx, rst_n;
wire tx;

initial begin
    $dumpfile("build/controller.vcd");
    $dumpvars;
    clk = 0;
    rst_n = 0;

    #20 rst_n = 1;

    #1000;

    $finish;
end
    

always #1 clk = ~clk;


Controller #(
    .CLK_FREQ           (50000000),
    .BIT_RATE           (115200),
    .PAYLOAD_BITS       (8),
    .BUFFER_SIZE        (8),
    .PULSE_CONTROL_BITS (32),
    .BUS_WIDTH          (32),
    .WORD_SIZE_BY       (4),
    .ID                 (32'h7700006A),
    .RESET_CLK_CYCLES   (20),
    .MEMORY_FILE        (""),
    .MEMORY_SIZE        (4096)
) u_Controller (
    .clk                (clk),
    .rst_n              (rst_n),
    
    // SPI signals
    .sck_i              (),
    .cs_i               (),
    .mosi_i             (),
    .miso_o             (),
    
    // SPI callback signals
    .rw_i               (),
    .intr_o             (),
    
    // UART signals
    .rx                 (rx),
    .tx                 (tx),
    
    // Clock, reset, and bus signals
    .clk_core_o         (),
    .rst_core_o         (),
    
    // Barramento padrão (não AXI4-Lite)
    .core_cyc_i         (),
    .core_stb_i         (),
    .core_we_i          (),
    .core_addr_i        (),
    .core_data_i        (),
    .core_data_o        (),
    .core_ack_o         ()
);

endmodule
