module Controller #(
    parameter CLK_FREQ           = 25000000,
    parameter BIT_RATE           = 9600,
    parameter PAYLOAD_BITS       = 8,
    parameter BUFFER_SIZE        = 8,
    parameter PULSE_CONTROL_BITS = 12,
    parameter BUS_WIDTH          = 32
) (
    input wire clk,
    input wire reset,

    // saida para serial
    input wire rx,
    output wire tx,

    //saída de clock para o core, reset, endereço de memória, 
    //barramento de leitura e escrita entre outros.
    output wire clk_core,
    output wire reset_core,

    input wire read_memory,
    input wire write_memory,
    input wire [31:0] address_memory,
    input wire [31:0] write_data_memory,
    output wire [31:0] read_data_memory,

    //RISC-V FORMAL INTERFACE(RVFI)
    
    //INSTRUCTION METADATA (check: https://github.com/YosysHQ/riscv-formal/blob/main/cores/nerv/nerv.sv)
    input wire        rvfi_valid,
    input wire [63:0] rvfi_order,
    input wire [31:0] rvfi_insn,
    input wire        rvfi_trap,
    input wire        rvfi_halt,
    input wire        rvfi_intr,
    input wire [ 1:0] rvfi_mode,
    input wire [ 1:0] rvfi_ixl,
    
    //INTEGER wireISTER READ/WRITE
    input wire [ 4:0] rvfi_rs1_addr,
    input wire [ 4:0] rvfi_rs2_addr,
    input wire [31:0] rvfi_rs1_rdata,
    input wire [31:0] rvfi_rs2_rdata,
    input wire [ 4:0] rvfi_rd_addr,
    input wire [31:0] rvfi_rd_wdata,

    //PROGRAM COUNTER
    input wire [31:0] rvfi_pc_rdata,
    input wire [31:0] rvfi_pc_wdata,

    //MEMORY ACCESS
    input wire [31:0] rvfi_mem_addr,
    input wire [ 3:0] rvfi_mem_rmask,
    input wire [ 3:0] rvfi_mem_wmask,
    input wire [31:0] rvfi_mem_rdata,
    input wire [31:0] rvfi_mem_wd,
);

wire write_pulse, clk_enable, uart_read, uart_write, uart_response;
wire [31:0] uart_read_data, uart_write_data;
wire [PULSE_CONTROL_BITS-1:0] num_pulses;

initial begin

end

ResetBootSystem #(
    .CYCLES(20)
) ResetBootSystem(
    .clk(clk),
    .reset_o(reset_o)
);

ClkDivider #(
    .COUNTER_BITS(32),
    .PULSE_CONTROL_BITS(PULSE_CONTROL_BITS)
) ClkDivider(
    .clk(clk),
    .reset(reset),
    .write_pulse(write_pulse),
    .option(0), // 0 - pulse, 1 - auto
    .out_enable(clk_enable), // 0 not, 1 - yes
    .divider(),
    .pulse(num_pulses),
    .clk_o(clk_core)
);

Interpreter #(
    .CLK_FREQ(CLK_FREQ),
    .NUM_PAGES(17),
    .PULSE_CONTROL_BITS(PULSE_CONTROL_BITS),
    .BUS_WIDTH(BUS_WIDTH),
) Interpreter(
    .clk(clk),
    .reset(reset),
    // uart control signal
    .uart_read(uart_read),
    .uart_write(uart_write),
    .uart_response(uart_response),
    // uart data signal
    .uart_read_data(uart_read_data),
    .uart_write_data(uart_write_data),
    // core signals
    .core_clk_enable(clk_enable),
    .core_reset(reset_core),
    .num_of_cycles_to_pulse(num_pulses),
    .write_pulse(write_pulse),
    // memory bus signal
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
    .WORD_SIZE_BY(4)
) Uart(
    .clk(clk),
    .reset(reset),

    .rx(rx),
    .tx(tx),

    .read(uart_read),
    .write(uart_write),
    .response(uart_response),

    .write_data(uart_write_data),
    .read_data(uart_read_data)
);
    
endmodule
