module controller_tb();

reg clk, rx, reset;
wire tx;

initial begin
    $dumpfile("build/controller.vcd");
    $dumpvars;
    clk = 0;
    reset = 1;

    #20 reset = 0;

    #1000;

    $finish;
end
    

always #1 clk = ~clk;


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
    .clk(clk),
    .reset(reset),

    .tx(tx),
    .rx(rx),

    .clk_core(),
    .reset_core(),
    
    .core_memory_response(),
    .core_read_memory(),
    .core_write_memory(),
    .core_address_memory(),
    .core_write_data_memory(),
    .core_read_data_memory()
);

endmodule
