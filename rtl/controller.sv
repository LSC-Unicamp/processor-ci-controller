module Controller #(
    parameter CLK_FREQ           = 100_000_000,
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
    input logic clk,
    input logic rst_n,

    // SPI signals
    input logic sck_i,
    input logic cs_i,
    input logic mosi_i,
    input logic miso_o,

    // SPI callback signals
    input  logic rw_i,
    output logic intr_o,

    // UART signals
    input  logic rx,
    output logic tx,

    //saída de clock para o core, reset, endereço de memória, 
    //barramento de leitura e escrita entre outros.
    output logic clk_core_o,
    output logic rst_core_o,

    `ifndef BUS_TYPE_AXI4_LITE

    input  logic        core_cyc_i,      // Indica uma transação ativa
    input  logic        core_stb_i,      // Indica uma solicitação ativa
    input  logic        core_we_i,       // 1 = Write, 0 = Read

    input  logic [31:0] core_addr_i,     // Endereço
    input  logic [31:0] core_data_i,     // Dados de entrada (para escrita)
    output logic [31:0] core_data_o,     // Dados de saída (para leitura)

    output logic        core_ack_o       // Confirmação da transação

    `else
    // Write Address Channel
    input  logic [ADDR_WIDTH-1:0]  AWADDR,
    input  logic [2:0]             AWPROT,
    input  logic                   AWVALID,
    output logic                   AWREADY,

    // Write Data Channel
    input  logic [DATA_WIDTH-1:0]  WDATA,
    input  logic [(DATA_WIDTH/8)-1:0] WSTRB,
    input  logic                   WVALID,
    output logic                   WREADY,

    // Write Response Channel
    output logic [1:0]             BRESP,
    output logic                   BVALID,
    input  logic                   BREADY,

    // Read Address Channel
    input  logic [ADDR_WIDTH-1:0]  ARADDR,
    input  logic [2:0]             ARPROT,
    input  logic                   ARVALID,
    output logic                   ARREADY,

    // Read Data Channel
    output logic [DATA_WIDTH-1:0]  RDATA,
    output logic [1:0]             RRESP,
    output logic                   RVALID,
    input  logic                   RREADY
    `endif

    `ifdef ENABLE_SECOND_MEMORY
    ,
    // Second memory - data memory
    input  logic        data_mem_cyc_i,      // Indica uma transação ativa
    input  logic        data_mem_stb_i,      // Indica uma solicitação ativa
    input  logic        data_mem_we_i,       // 1 = Write, 0 = Read

    input  logic [31:0] data_mem_addr_i,     // Endereço
    input  logic [31:0] data_mem_data_i,     // Dados de entrada (para escrita)
    output logic [31:0] data_mem_data_o,     // Dados de saída (para leitura)

    output logic        data_mem_ack_o       // Confirmação da transação
    `endif
);

// UART logics
logic communication_read, communication_write, communication_read_response, communication_write_response,
    communication_rx_empty, communication_tx_empty;
logic [31:0] communication_read_data, communication_write_data;

// Clock Divider logics
logic write_pulse, clk_enable;
logic [PULSE_CONTROL_BITS-1:0] num_pulses;

// Memory logics

// Interpreter
logic interpreter_memory_read, interpreter_memory_write, interpreter_memory_response, memory_mux_selector;
logic [31:0] interpreter_memory_read_data, interpreter_memory_write_data, interpreter_memory_address;
logic interpreter_we, interpreter_stb, interpreter_cyc;

assign interpreter_cyc = interpreter_memory_write | interpreter_memory_read;
assign interpreter_we = interpreter_memory_write;
assign interpreter_stb = interpreter_memory_write | interpreter_memory_read;

// Primary Memory
logic memory_cyc, memory_stb, memory_ack, memory_we;
logic [31:0] memory_read_data, memory_address, memory_write_data;

// Data Memory
logic data_memory_cyc, data_memory_stb, data_memory_ack, data_memory_we;
logic [31:0] data_memory_read_data, data_memory_address, data_memory_write_data;

// Bus Logic - Primary Memory
assign memory_cyc = (memory_mux_selector) ?  core_cyc_i : (!interpreter_memory_address[31]) ? interpreter_cyc : 1'b0;
assign memory_stb = (memory_mux_selector) ?  core_stb_i : (!interpreter_memory_address[31]) ? interpreter_stb : 1'b0;
assign memory_we = (memory_mux_selector) ?  core_we_i : (!interpreter_memory_address[31]) ? interpreter_we : 1'b0;
assign memory_address = (memory_mux_selector) ?  core_addr_i : interpreter_memory_address;
assign memory_write_data = (memory_mux_selector) ?  core_data_i : interpreter_memory_write_data;

`ifdef ENABLE_SECOND_MEMORY
// Bus logic - Data Memory
assign data_memory_cyc = (memory_mux_selector) ?  data_mem_cyc_i : (interpreter_memory_address[31]) ? interpreter_cyc : 1'b0;
assign data_memory_stb = (memory_mux_selector) ?  data_mem_stb_i : (interpreter_memory_address[31]) ? interpreter_stb : 1'b0;
assign data_memory_we = (memory_mux_selector) ?  data_mem_we_i : (interpreter_memory_address[31]) ? interpreter_we : 1'b0;
assign data_memory_address = (memory_mux_selector) ?  data_mem_addr_i : interpreter_memory_address;
assign data_memory_write_data = (memory_mux_selector) ?  data_mem_data_i : interpreter_memory_write_data;
`endif

// Bus Logic - Core
assign core_ack_o = (memory_mux_selector) ? memory_ack : 1'b0;
assign core_data_o = (memory_mux_selector) ? memory_read_data : 32'h00000000;
`ifdef ENABLE_SECOND_MEMORY
assign data_mem_ack_o = (memory_mux_selector) ? data_memory_ack : 1'b0;
assign data_mem_data_o = (memory_mux_selector) ? data_memory_read_data : 32'h00000000;
`endif

// Bus Logic - Interpreter
// Interpreter memory response
assign interpreter_memory_response = (!memory_mux_selector) ? (interpreter_memory_address[31]) ? data_memory_ack : memory_ack : 1'b0;
assign interpreter_memory_read = (!memory_mux_selector) ? (interpreter_memory_address[31]) ? data_memory_cyc : memory_cyc : 1'b0;


// Bus internal
logic finish_execution;
logic reset_bus, bus_mode;
logic [23:0] memory_page_number;
logic [31:0] end_position;


always_ff @(posedge clk ) begin
    if(reset_bus)
        finish_execution <= 1'b0;
    else begin 
        if(bus_mode) begin
            if(core_addr_i[5:0] == end_position[5:0])
                finish_execution <= 1'b1;
        end else begin
            if(core_addr_i == end_position 
            `ifdef ENABLE_SECOND_MEMORY
            || data_mem_addr_i == end_position
            `endif
            )
                finish_execution <= 1'b1;
        end
    end
end

ClkDivider #(
    .COUNTER_BITS       (32),
    .PULSE_CONTROL_BITS (PULSE_CONTROL_BITS)
) ClkDivider(
    .clk         (clk),
    .rst_n       (rst_n),
    .write_pulse (write_pulse),
    .option      (1'b0), // 0 - pulse, 1 - auto
    .out_enable  (clk_enable), // 0 not, 1 - yes
    .divider     (),
    .pulse       (num_pulses),
    .clk_o       (clk_core_o)
);

Interpreter #(
    .CLK_FREQ           (CLK_FREQ),
    .PULSE_CONTROL_BITS (PULSE_CONTROL_BITS),
    .BUS_WIDTH          (BUS_WIDTH),
    .ID                 (ID),
    .RESET_CLK_CYCLES   (RESET_CLK_CYCLES)
) Interpreter(
    .clk                          (clk),
    .rst_n                        (rst_n),

    // uart buffer signal
    .communication_rx_empty       (communication_rx_empty),
    .communication_tx_empty       (communication_tx_empty),

    // uart control signal
    .communication_read           (communication_read),
    .communication_write          (communication_write),
    .communication_read_response  (communication_read_response),
    .communication_write_response (communication_write_response),

    // uart data signal
    .communication_read_data      (communication_read_data),
    .communication_write_data     (communication_write_data),

    // core signals
    .core_clk_enable              (clk_enable),
    .core_reset                   (rst_core_o),
    .num_of_cycles_to_pulse       (num_pulses),
    .write_pulse                  (write_pulse),
      
    // BUS signals    
    .finish_execution             (finish_execution),
    .reset_bus                    (reset_bus),
    .bus_mode                     (bus_mode),
    .memory_page_size             (),
    .end_position                 (end_position),
      
    // memory bus signal      
    .memory_response              (interpreter_memory_response),
    .memory_read                  (interpreter_memory_read),
    .memory_write                 (interpreter_memory_write),
    .memory_mux_selector          (memory_mux_selector),
    .memory_page_number           (memory_page_number),
    .write_data                   (interpreter_memory_write_data),
    .address                      (interpreter_memory_address),
    .read_data                    (interpreter_memory_read_data)
);

UART #(
    .CLK_FREQ     (CLK_FREQ),
    .BIT_RATE     (BIT_RATE),
    .PAYLOAD_BITS (PAYLOAD_BITS),
    .BUFFER_SIZE  (BUFFER_SIZE),
    .WORD_SIZE_BY (WORD_SIZE_BY)
) Uart(
    .clk            (clk),
    .rst_n          (rst_n),
    
    .rx             (rx),
    .tx             (tx),

    .uart_rx_empty  (communication_rx_empty),
    .uart_tx_empty  (communication_tx_empty),

    .read           (communication_read),
    .write          (communication_write),
    .read_response  (communication_read_response),
    .write_response (communication_write_response),

    .write_data     (communication_read_data),
    .read_data      (communication_write_data)
);

Memory #(
    .MEMORY_FILE (MEMORY_FILE),
    .MEMORY_SIZE (MEMORY_SIZE)
) Core_Memory (
    .clk    (clk),
    
    .cyc_i  (memory_cyc),
    .stb_i  (memory_stb),
    .we_i   (memory_we),

    .addr_i (memory_address),
    .data_i (memory_write_data),
    .data_o (memory_read_data),

    .ack_o  (memory_ack)
);


`ifdef ENABLE_SECOND_MEMORY
Memory #(
    .MEMORY_FILE (),
    .MEMORY_SIZE (4096)
) Core_Data_Memory (
    .clk    (clk),
    
    .cyc_i  (data_memory_cyc_i),
    .stb_i  (data_memory_stb_i),
    .we_i   (data_memory_we_i),

    .addr_i (data_memory_addr_i),
    .data_i (data_memory_data_i),
    .data_o (data_memory_data_o),

    .ack_o  (data_memory_ack_o)
);
`endif

endmodule
