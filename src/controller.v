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

    // SPI signals
    input wire sck,
    input wire cs,
    input wire mosi,
    input wire miso,

    // SPI callback signals
    input wire rw,
    output wire intr,


    // UART signals
    input wire rx,
    output wire tx,

    //saída de clock para o core, reset, endereço de memória, 
    //barramento de leitura e escrita entre outros.
    output wire clk_core,
    output wire reset_core,

    // Memoria principal - memoria de instruções
    output wire core_memory_response,
    input wire core_read_memory,
    input wire core_write_memory,
    input wire [31:0] core_address_memory,
    input wire [31:0] core_write_data_memory,
    output wire [31:0] core_read_data_memory,

    output wire [31:0] core_read_data_memory_sync,
    output wire core_memory_read_response_sync,
    output wire core_memory_write_response_sync,

    // Memoria de dados - sete como zero para não ser usada
    output wire core_memory_response_data,
    input wire core_read_memory_data,
    input wire core_write_memory_data,
    input wire [31:0] core_address_memory_data,
    input wire [31:0] core_write_data_memory_data,
    output wire [31:0] core_read_data_memory_data

);

// UART Wires
wire communication_read, communication_write, communication_read_response, communication_write_response,
    communication_rx_empty, communication_tx_empty;
wire [31:0] communication_read_data, communication_write_data;

// Clock Divider Wires
wire write_pulse, clk_enable;
wire [PULSE_CONTROL_BITS-1:0] num_pulses;

// Memory Wires
wire memory_read, memory_write, memory_response;
wire [31:0] memory_read_data, memory_write_data, memory_address;

// Data Memory Wires
wire data_memory_read, data_memory_write, data_memory_response;
wire [31:0] data_memory_read_data, data_memory_write_data, data_memory_address;

// Memory Interpreter Wires
wire interpreter_memory_read, interpreter_memory_write, interpreter_memory_response, memory_mux_selector;
wire [31:0] interpreter_memory_read_data, interpreter_memory_write_data, interpreter_memory_address;

// Bus Logic
assign memory_read = (memory_mux_selector == 1'b1) ? core_read_memory : (interpreter_memory_address[31] == 1'b0) ? interpreter_memory_read : 1'b0;
assign memory_write = (memory_mux_selector == 1'b1) ? core_write_memory : (interpreter_memory_address[31] == 1'b0) ? interpreter_memory_write : 1'b0;

assign memory_address = (memory_mux_selector == 1'b1) ? (bus_mode == 1'b1) ? {
    memory_page_number, core_address_memory[5:0]}: core_address_memory : interpreter_memory_address;
assign memory_write_data = (memory_mux_selector == 1'b1) ? core_write_data_memory : interpreter_memory_write_data;

// core memory instruction response
assign core_memory_response = (memory_mux_selector == 1'b1) ? memory_response : 1'b0;
assign core_read_data_memory = (memory_mux_selector == 1'b1) ? memory_read_data : 32'h00000000;

// Bus Logic - Data Memory
assign data_memory_read = (memory_mux_selector == 1'b1) ? core_read_memory_data : (interpreter_memory_address[31] == 1'b1) ? interpreter_memory_read : 1'b0;
assign data_memory_write = (memory_mux_selector == 1'b1) ? core_write_memory_data : (interpreter_memory_address[31] == 1'b1) ? interpreter_memory_write : 1'b0;

assign data_memory_address = (memory_mux_selector == 1'b1) ? core_address_memory_data : {1'b0, interpreter_memory_address[30:0]};
assign data_memory_write_data = (memory_mux_selector == 1'b1) ? core_write_data_memory_data : interpreter_memory_write_data;

// core memory data response
assign core_memory_response_data = (memory_mux_selector == 1'b1) ? data_memory_response : 1'b0;
assign core_read_data_memory_data = (memory_mux_selector == 1'b1) ? data_memory_read_data : 32'h00000000;

// Bus Logic - Interpreter
// Interpreter memory response
assign interpreter_memory_response = (memory_mux_selector == 1'b0) ? (interpreter_memory_address[31] == 1'b1) ? data_memory_response : memory_response : 1'b0;
assign interpreter_memory_read_data = (memory_mux_selector == 1'b0) ? (interpreter_memory_address[31] == 1'b1) ? data_memory_read_data: memory_read_data : 32'h00000000;

reg finish_execution;
wire reset_bus, bus_mode;
wire [23:0] memory_page_number;
wire [31:0] end_position;

always @(posedge clk ) begin
    if(reset_bus)
        finish_execution <= 1'b0;
    else begin 
        if(bus_mode == 1'b1) begin
            if(core_address_memory[5:0] == end_position[5:0])
                finish_execution <= 1'b1;
        end else begin
            if(core_address_memory == end_position || core_address_memory_data == end_position)
                finish_execution <= 1'b1;
        end
    end
end


ClkDivider #(
    .COUNTER_BITS      (32),
    .PULSE_CONTROL_BITS(PULSE_CONTROL_BITS)
) ClkDivider(
    .clk  (clk),
    .reset(reset),
    .write_pulse(write_pulse),
    .option(1'b0), // 0 - pulse, 1 - auto
    .out_enable(clk_enable), // 0 not, 1 - yes
    .divider(),
    .pulse(num_pulses),
    .clk_o(clk_core)
);

Interpreter #(
    .CLK_FREQ          (CLK_FREQ),
    .PULSE_CONTROL_BITS(PULSE_CONTROL_BITS),
    .BUS_WIDTH         (BUS_WIDTH),
    .ID                (ID),
    .RESET_CLK_CYCLES  (RESET_CLK_CYCLES)
) Interpreter(
    .clk  (clk),
    .reset(reset),

    // uart buffer signal
    .communication_rx_empty(communication_rx_empty),
    .communication_tx_empty(communication_tx_empty),

    // uart control signal
    .communication_read (communication_read),
    .communication_write(communication_write),
    .communication_read_response (communication_read_response),
    .communication_write_response(communication_write_response),

    // uart data signal
    .communication_read_data (communication_read_data),
    .communication_write_data(communication_write_data),

    // core signals
    .core_clk_enable(clk_enable),
    .core_reset(reset_core),
    .num_of_cycles_to_pulse(num_pulses),
    .write_pulse(write_pulse),

    // BUS signals
    .finish_execution(finish_execution),
    .reset_bus       (reset_bus),
    .bus_mode        (bus_mode),
    .memory_page_size(),
    .end_position    (end_position),

    // memory bus signal
    .memory_response(interpreter_memory_response),
    .memory_read(interpreter_memory_read),
    .memory_write(interpreter_memory_write),
    .memory_mux_selector(memory_mux_selector),
    .memory_page_number(memory_page_number),
    .write_data(interpreter_memory_write_data),
    .address(interpreter_memory_address),
    .read_data(interpreter_memory_read_data)
);

UART #(
    .CLK_FREQ    (CLK_FREQ),
    .BIT_RATE    (BIT_RATE),
    .PAYLOAD_BITS(PAYLOAD_BITS),
    .BUFFER_SIZE (BUFFER_SIZE),
    .WORD_SIZE_BY(WORD_SIZE_BY)
) Uart(
    .clk  (clk),
    .reset(reset),

    .uart_rx_empty(communication_rx_empty),
    .uart_tx_empty(communication_tx_empty),
    
    .rx(rx),
    .tx(tx),

    .read (communication_read),
    .write(communication_write),
    .read_response (communication_read_response),
    .write_response(communication_write_response),

    .write_data(communication_write_data),
    .read_data (communication_read_data)
);
/*
SPI #(
    .PAYLOAD_BITS(PAYLOAD_BITS),
    .BUFFER_SIZE (BUFFER_SIZE),
    .WORD_SIZE_BY(WORD_SIZE_BY)
) Spi(
    .clk  (clk),
    .reset(reset),

    .sck (sck),
    .cs  (cs),
    .mosi(mosi),
    .miso(miso),

    .rw  (rx),
    .intr(intr),

    .rx_fifo_empty(communication_rx_empty),
    .tx_fifo_empty(communication_tx_empty),

    .read (communication_read),
    .write(communication_write),
    .read_response (communication_read_response),
    .write_response(communication_write_response),

    .write_data(communication_write_data),
    .read_data (communication_read_data)
);
*/
Memory #(
    .MEMORY_FILE(MEMORY_FILE),
    .MEMORY_SIZE(MEMORY_SIZE)
) Memory(
    .clk  (clk),
    .reset(reset),

    .memory_read (memory_read),
    .memory_write(memory_write),
    .address     (memory_address),

    .write_data(memory_write_data),
    .read_data (memory_read_data),
    .response  (memory_response),

    // sync sinals

    .read_sync          (core_read_data_memory_sync),
    .sync_write_response(core_memory_read_response_sync),
    .sync_read_response (core_memory_write_response_sync)
);

Memory #(
    .MEMORY_FILE(""),
    .MEMORY_SIZE(4096)
) Data_Memory(
    .clk  (clk),
    .reset(reset),

    .memory_read (data_memory_read),
    .memory_write(data_memory_write),
    .address     (data_memory_address),

    .write_data(data_memory_write_data),
    .read_data (data_memory_read_data),
    .response  (data_memory_response)
);
    
endmodule
