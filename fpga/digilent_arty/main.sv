module top (
    input  logic clk,
    input  logic reset,

    input  logic rx,
    output logic tx,

    output logic [3:0]led,
    
    input  logic cs,
    input  logic mosi,
    input  logic sck,
    output logic miso,

    input  logic rw,
    output logic intr
);

logic clk_o, rst_n;

initial begin
    clk_o = 1'b0; // 50mhz
end

logic clk_core, rst_core;

// Fios do barramento entre Controller e Processor
logic core_cyc;
logic core_stb;
logic core_we;
logic [31:0] core_addr;
logic [31:0] core_data_out;
logic [31:0] core_data_in;
logic        core_ack;

Controller #(
    .CLK_FREQ           (50_000_000),
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
    .rst_n              (rst_n),
    
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
    .core_cyc_i         (core_cyc),
    .core_stb_i         (core_stb),
    .core_we_i          (core_we),
    .core_addr_i        (core_addr),
    .core_data_i        (core_data_out),
    .core_data_o        (core_data_in),
    .core_ack_o         (core_ack)
);

Grande_Risco5 #(
    .BOOT_ADDRESS           (32'h00000000),
    .I_CACHE_SIZE           (256),
    .D_CACHE_SIZE           (256),
    .DATA_WIDTH             (32),
    .ADDR_WIDTH             (32),
    .BRANCH_PREDICTION_SIZE (128)
) Processor (
    .clk    (clk_core),
    .rst_n  (~rst_core),
    .halt   (1'b0),

    .cyc_o  (core_cyc),
    .stb_o  (core_stb),
    .we_o   (core_we),

    .addr_o (core_addr),
    .data_o (core_data_out),

    .ack_i  (core_ack),
    .data_i (core_data_in),

    .interruption (1'b0)
);

always_ff @(posedge clk) begin : CLOCK_DIVIDER
    clk_o <= ~clk_o;
end

ResetBootSystem #(
    .CYCLES(20)
) ResetBootSystem(
    .clk     (clk_o),
    
    .rst_n_o (rst_n)
);
    

endmodule
