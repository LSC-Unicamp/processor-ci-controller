module top (
    input  wire clk, // 25 mhz
    input  wire reset,
    input  wire rx,
    output wire tx,
    output wire [7:0]led,
    input  wire [5:0]gpios
);

wire clk_core, reset_core, core_memory_response, reset_o;

ResetBootSystem #(
    .CYCLES(20)
) ResetBootSystem(
    .clk(clk),
    .reset_o(reset_o)
);

Controller #(
    .CLK_FREQ(25000000),
    .BIT_RATE(115200),
    .PAYLOAD_BITS(8),
    .BUFFER_SIZE(8),
    .PULSE_CONTROL_BITS(32),
    .BUS_WIDTH(32),
    .WORD_SIZE_BY(4),
    .ID(32'h0000004A),
    .RESET_CLK_CYCLES(20)
) Controller(
    .clk(clk),
    .reset(reset_o),

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

assign led = ~(8'b01010111);
    
endmodule
