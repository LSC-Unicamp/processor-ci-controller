module top (
    input  wire clk, // 25 mhz
    input  wire reset,
    input  wire rx,
    output wire tx,
    output wire [7:0]led,
    input  wire [5:0]gpios
);

wire clk_core, reset_core, core_memory_response, reset_o,
    memory_read, memory_write, core_memory_write_response;

wire [31:0] core_read_data, core_write_data, address;

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
    .RESET_CLK_CYCLES(20),
    .MEMORY_FILE(""),
    .MEMORY_SIZE(4096)
) Controller(
    .clk(clk),
    .reset(reset_o),

    .tx(tx),
    .rx(rx),

    .clk_core(clk_core),
    .reset_core(reset_core),
    
    .core_memory_response(),
    .core_read_memory(memory_read),
    .core_write_memory(memory_write),
    .core_address_memory(address),
    .core_write_data_memory(core_write_data),
    .core_read_data_memory()

    //sync memory bus
    .core_read_data_memory_sync(core_read_data),
    .core_memory_read_response_sync(core_memory_response),
    .core_memory_write_response_sync(core_memory_response)
);

rvsteel_core #(
    .BOOT_ADDRESS                   (32'h00000000)
) rvsteel_core_instance (

    // Global signals

    .clock                          (clk_core                              ),
    .reset                          (reset_core                              ),
    .halt                           (1'b0                               ),

    // IO interface

    .rw_address                     (address                 ),
    .read_data                      (core_read_data                  ),
    .read_request                   (memory_read               ),
    .read_response                  (core_memory_response              ),
    .write_data                     (core_write_data                 ),
    .write_strobe                   (               ),
    .write_request                  (memory_write              ),
    .write_response                 (core_memory_write_response             ),

    // Interrupt request signals

    .irq_fast                       (0                           ),
    .irq_external                   (0                       ),
    .irq_timer                      (0                          ),
    .irq_software                   (0                       ),

    // Interrupt response signals

    .irq_fast_response              (                  ),
    .irq_external_response          (              ),
    .irq_timer_response             (                 ),
    .irq_software_response          (              ),

    // Real Time Clock

    .real_time_clock                (    0                )

);


    
endmodule
