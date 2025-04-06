module top (
    input  logic clk,
    input  logic CPU_RESETN,

    input  logic rx,
    output logic tx,

    output logic [15:0]LED,

    input  logic mosi,
    output logic miso,
    input  logic sck,
    input  logic cs,

    input  logic [15:0] SW,

    output logic [3:0] VGA_R,
    output logic [3:0] VGA_G,
    output logic [3:0] VGA_B,
    output logic VGA_HS,
    output logic VGA_VS,

    output logic M_CLK,      // Clock do microfone
    output logic M_LRSEL,    // Left/Right Select (Escolha do canal)

    input  logic M_DATA      // Dados do microfone
);


logic clk_o;

logic clk_core, rst_core;


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
    .clk                (clk_o),
    .rst_n              (CPU_RESETN),
    
    // SPI signals
    .sck_i              (sck),
    .cs_i               (cs),
    .mosi_i             (mosi),
    .miso_o             (miso),
    
    // SPI callback signals
    .rw_i               (),
    .intr_o             (),
    
    // UART signals
    .rx                 (rx),
    .tx                 (tx),
    
    // Clock, reset, and bus signals
    .clk_core_o         (clk_core),
    .rst_core_o         (rst_core),
    
    // Barramento padrão (não AXI4-Lite)
    .core_cyc_i         (),
    .core_stb_i         (),
    .core_we_i          (),
    .core_addr_i        (),
    .core_data_i        (),
    .core_data_o        (),
    .core_ack_o         ()
    
    `ifdef ENABLE_SECOND_MEMORY
    ,
    // Segunda memória - memória de dados
    .data_mem_cyc_i     (data_mem_cyc_i),
    .data_mem_stb_i     (data_mem_stb_i),
    .data_mem_we_i      (data_mem_we_i),
    .data_mem_addr_i    (data_mem_addr_i),
    .data_mem_data_i    (data_mem_data_i),
    .data_mem_data_o    (data_mem_data_o),
    .data_mem_ack_o     (data_mem_ack_o)
    `endif
);


always_ff @(posedge clk) begin
    if(!CPU_RESETN)
        clk_o <= 1'b0;
    else
        clk_o <= ~clk_o;
end

endmodule
