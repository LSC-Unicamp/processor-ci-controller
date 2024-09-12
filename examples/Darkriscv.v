module top (
    input  wire clk, // 25 mhz
    input  wire reset,
    input  wire rx,
    output wire tx,
    output wire [7:0]led,
    input  wire [5:0]gpios
);

wire clk_core, reset_core, reset_o,
    memory_read, memory_write;

wire [31:0] core_read_data, core_write_data, address,
    data_address, data_read, data_write;

ResetBootSystem #(
    .CYCLES(20)
) ResetBootSystem(
    .clk    (clk),
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
    .RESET_CLK_CYCLES(20),
    .MEMORY_FILE(""),
    .MEMORY_SIZE(4096)
) Controller(
    .clk  (clk),
    .reset(reset_o),

    .tx(tx),
    .rx(rx),

    .clk_core  (clk_core),
    .reset_core(reset_core),
    
    // main memory - instruction memory
    .core_memory_response  (),
    .core_read_memory      (memory_read),
    .core_write_memory     (1'b0),
    .core_address_memory   (address),
    .core_write_data_memory(32'h00000000),
    .core_read_data_memory (1'b1)

    //sync main memory bus
    .core_read_data_memory_sync     (),
    .core_memory_read_response_sync (),
    .core_memory_write_response_sync(),

    // Data memory
    .core_memory_response_data  (),
    .core_read_memory_data      (memory_read),
    .core_write_memory_data     (memory_write),
    .core_address_memory_data   (data_address),
    .core_write_data_memory_data(data_write),
    .core_read_data_memory_data (data_read)
);

darkriscv #(
    .CPTR(0)
) Core (
    .CLK(clk_core),
    .RES(reset_core),
    .HLT(1'b0),

    .IRQ(1'b0),

    .IDATA(core_read_data),
    .IADDR(address),

    .DATAI(data_read),
    .DATAO(data_write),
    .DADDR(data_address),

    .DLEN(), // data length
    .DRW (), // memory read write
    .DRD (memory_read),
    .DWR (memory_write),
    .DAS () // memory address strobe
);
    
endmodule
