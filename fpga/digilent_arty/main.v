module top (
    input  wire clk,
    input  wire rx,
    output wire tx,
    output wire [3:0]led,
    input  wire [3:0]btn
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
    .CLK_FREQ(50000000),
    .BIT_RATE(115200),
    .PAYLOAD_BITS(8),
    .BUFFER_SIZE(8),
    .PULSE_CONTROL_BITS(32),
    .BUS_WIDTH(32),
    .WORD_SIZE_BY(4),
    .ID(32'h7700006A),
    .RESET_CLK_CYCLES(20),
    .MEMORY_FILE(""),
    .MEMORY_SIZE(4096)
) Controller(
    .clk(clk_o),
    .reset(reset_o),

    .led(led),

    .tx(tx),
    .rx(rx),

    .clk_core(clk_core),
    .reset_core(reset_core),
    
    .core_memory_response(core_memory_response),
    .core_read_memory(),
    .core_write_memory(),
    .core_address_memory(),
    .core_write_data_memory(),
    .core_read_data_memory()
);

always @(posedge clk) begin
    clk_o = ~clk_o;
end

endmodule
