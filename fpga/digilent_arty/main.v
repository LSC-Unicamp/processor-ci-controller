module top (
    input  wire clk,
    input  wire reset,

    input  wire rx,
    output wire tx,

    output wire [3:0]led,
    
    input wire cs,
    input wire mosi,
    input wire sck,
    output wire miso,

    input wire rw,
    output wire intr
);

reg clk_o;

initial begin
    clk_o = 1'b0; // 50mhz
end

wire clk_core, reset_core, core_memory_response, reset_o;

ResetBootSystem #(
    .CYCLES(20)
) ResetBootSystem(
    .clk(clk_o),
    .reset_o(reset_o)
);

Controller #(
    .CLK_FREQ          (50000000),
    .BIT_RATE          (115200),
    .PAYLOAD_BITS      (8),
    .BUFFER_SIZE       (8),
    .PULSE_CONTROL_BITS(32),
    .BUS_WIDTH         (32),
    .WORD_SIZE_BY      (4),
    .ID                (32'h7700006A),
    .RESET_CLK_CYCLES  (20),
    .MEMORY_FILE       (""),
    .MEMORY_SIZE       (4096)
) Controller(
    .clk  (clk),
    .reset(reset_o),

    .tx(tx),
    .rx(rx),

    .sck (sck),
    .cs  (cs),
    .mosi(mosi),
    .miso(miso),

    .rw  (rw),
    .intr(intr),

    .clk_core  (clk_core),
    .reset_core(reset_core),
    
    .core_memory_response  (core_memory_response),
    .core_read_memory      (memory_read),
    .core_write_memory     (memory_write),
    .core_address_memory   (address),
    .core_write_data_memory(core_write_data),
    .core_read_data_memory (core_read_data),

    //sync memory bus
    .core_read_data_memory_sync     (),
    .core_memory_read_response_sync (),
    .core_memory_write_response_sync(),

    // Data memory
    .core_memory_response_data  (),
    .core_read_memory_data      (1'b0),
    .core_write_memory_data     (1'b0),
    .core_address_memory_data   (32'h00000000),
    .core_write_data_memory_data(32'h00000000),
    .core_read_data_memory_data ()
);

Core #(
    .BOOT_ADDRESS(32'h00000000)
) Core(
    .clk            (clk_core),
    .reset          (reset_core),
    .option         (),
    .memory_response(core_memory_response),
    .memory_read    (memory_read),
    .memory_write   (memory_write),
    .write_data     (core_write_data),
    .read_data      (core_read_data),
    .address        (address)
);


always @(posedge clk) begin
    clk_o = ~clk_o;
end

endmodule
