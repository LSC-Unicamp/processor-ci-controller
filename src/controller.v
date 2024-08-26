module Controller #(
    parameter CLK_FREQ           = 25000000,
    parameter BIT_RATE           = 9600,
    parameter PAYLOAD_BITS       = 8,
    parameter BUFFER_SIZE        = 8,
    parameter PULSE_CONTROL_BITS = 12,
    parameter BUS_WIDTH          = 32,
    parameter WORD_SIZE_BY       = 4,
    parameter ID                 = 32'h00000001,
    parameter RESET_CLK_CYCLES   = 20,
    parameter MEMORY_FILE        = "",
    parameter MEMORY_SIZE        = 4096
) (
    input wire clk,
    input wire reset,

    // debug
    output wire [3:0] led,

    // saida para serial
    input wire rx,
    output wire tx,

    //saída de clock para o core, reset, endereço de memória, 
    //barramento de leitura e escrita entre outros.
    output wire clk_core,
    output wire reset_core,

    output wire core_memory_response,
    input wire core_read_memory,
    input wire core_write_memory,
    input wire [31:0] core_address_memory,
    input wire [31:0] core_write_data_memory,
    output wire [31:0] core_read_data_memory
);

wire write_pulse, clk_enable, uart_read, uart_write, uart_read_response, uart_write_response,
    uart_rx_empty, uart_tx_empty;
wire [31:0] uart_read_data, uart_write_data;
wire [PULSE_CONTROL_BITS-1:0] num_pulses;

initial begin

end

ClkDivider #(
    .COUNTER_BITS(32),
    .PULSE_CONTROL_BITS(PULSE_CONTROL_BITS)
) ClkDivider(
    .clk(clk),
    .reset(reset),
    .write_pulse(write_pulse),
    .option(1'b0), // 0 - pulse, 1 - auto
    .out_enable(clk_enable), // 0 not, 1 - yes
    .divider(),
    .pulse(num_pulses),
    .clk_o(clk_core)
);

Interpreter #(
    .CLK_FREQ(CLK_FREQ),
    .PULSE_CONTROL_BITS(PULSE_CONTROL_BITS),
    .BUS_WIDTH(BUS_WIDTH),
    .ID(ID),
    .RESET_CLK_CYCLES(RESET_CLK_CYCLES)
) Interpreter(
    .clk(clk),
    .reset(reset),
    //debug
    .led(led),
    // uart buffer signal
    .uart_rx_empty(uart_rx_empty),
    .uart_tx_empty(uart_tx_empty),
    // uart control signal
    .uart_read(uart_read),
    .uart_write(uart_write),
    .uart_read_response(uart_read_response),
    .uart_write_response(uart_write_response),
    // uart data signal
    .uart_read_data(uart_read_data),
    .uart_write_data(uart_write_data),
    // core signals
    .core_clk_enable(clk_enable),
    .core_reset(reset_core),
    .num_of_cycles_to_pulse(num_pulses),
    .write_pulse(write_pulse),
    // memory bus signal
    .memory_response(),
    .memory_read(),
    .memory_write(),
    .memory_mux_selector(),
    .memory_page_number(),
    .write_data(),
    .address(),
    .read_data()
);

UART #(
    .CLK_FREQ(CLK_FREQ),
    .BIT_RATE(BIT_RATE),
    .PAYLOAD_BITS(PAYLOAD_BITS),
    .BUFFER_SIZE(BUFFER_SIZE),
    .WORD_SIZE_BY(WORD_SIZE_BY)
) Uart(
    .clk(clk),
    .reset(reset),

    .uart_rx_empty(uart_rx_empty),
    .uart_tx_empty(uart_tx_empty),
    
    .rx(rx),
    .tx(tx),

    .read(uart_read),
    .write(uart_write),
    .read_response(uart_read_response),
    .write_response(uart_write_response),

    .address(32'h00000000),
    .write_data(uart_write_data),
    .read_data(uart_read_data)
);

Memory #(
    .MEMORY_FILE(MEMORY_FILE),
    .MEMORY_SIZE(MEMORY_SIZE)
) Memory(
    .clk(clk),
    .reset(reset),
    .memory_read(core_read_memory),
    .memory_write(core_write_memory),
    .address(core_address_memory),
    .write_data(core_write_data_memory),
    .read_data(core_read_data_memory)
);
    
endmodule
