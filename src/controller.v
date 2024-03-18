module Controller #(
    parameter CLK_FREQ = 25000000,
    parameter BIT_RATE =   9600,
    parameter PAYLOAD_BITS = 8,
    parameter BUFFER_SIZE = 8
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

    input wire memory_read_memory,
    input wire memory_write_memory,
    input wire [31:0] address_memory,
    input wire [31:0] write_data_memory,
    output wire [31:0]read_data_memory,

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
    input wire [31:0] rvfi_mem_wd
);


wire [PAYLOAD_BITS-1:0]  uart_rx_data, tx_fifo_read_data, 
    rx_fifo_read_data;
wire uart_rx_valid, uart_rx_break, uart_tx_busy, tx_fifo_empty,
    rx_fifo_empty, tx_fifo_full, rx_fifo_full;
reg uart_tx_en, tx_fifo_read, tx_fifo_write, rx_fifo_read, 
    rx_fifo_write, buffer_full;
reg [PAYLOAD_BITS-1:0] uart_tx_data, tx_fifo_write_data, 
    rx_fifo_write_data, read_buffer;

initial begin
    buffer_full = 1'b0;
    uart_tx_en = 1'b0;
    tx_fifo_read = 1'b0;
    tx_fifo_write = 1'b0;
    rx_fifo_read = 1'b0;
    rx_fifo_write = 1'b0;
    uart_tx_data = 8'h00;
    tx_fifo_write_data = 8'h00;
    rx_fifo_write_data = 8'h00;
    read_buffer = 8'h00;
end

always @(posedge clk) begin
    uart_tx_en <= 1'b0;
    tx_fifo_read <= 1'b0;
    tx_fifo_write <= 1'b0;
    rx_fifo_read <= 1'b0;
    rx_fifo_write <= 1'b0;

    if(reset == 1'b1) begin
        read_buffer <= 8'h00;
        buffer_full <= 1'b0;
        uart_tx_data <= 8'h00;
        tx_fifo_write_data <= 8'h00;
        rx_fifo_write_data <= 8'h00;
    end else begin
        if(uart_tx_busy == 1'b0 && tx_fifo_empty == 1'b0) begin
            uart_tx_en <= 1'b1;
            uart_tx_data <= tx_fifo_read_data;
            tx_fifo_read <= 1'b1;
        end

        if(rx_fifo_full == 1'b0 && uart_rx_valid == 1'b1) begin
            rx_fifo_write_data <= uart_rx_data;
            rx_fifo_write <= 1'b1;
        end
    end
end


ResetBootSystem #(
    .CYCLES(20)
) ResetBootSystem(
    .clk(clk),
    .reset_o(reset_o)
);

ClkDivider #(
    .COUNTER_BITS(32),
    .PULSE_BITS(32)
) ClkDivider(
    .clk(clk),
    .reset(reset),
    .write_pulse(),
    .option(), // 0 - pulse, 1 - auto
    .out_enable(), // 0 not, 1 - yes
    .divider(),
    .pulse(),
    .clk_o(clk_core)
);

Interpreter #(
    .CLK_FREQ(CLK_FREQ)
) Interpreter(
    .clk(clk),
    .reset(reset),
    .processor_alu_result(),
    .processor_reg_data(),
    .uart_rx_empty(rx_fifo_empty),
    .uart_tx_empty(tx_fifo_empty),
    .uart_rx_full(rx_fifo_full),
    .uart_tx_full(tx_fifo_full),
    .uart_in(rx_fifo_read_data),
    .write_uart(tx_fifo_write),
    .read_uart(rx_fifo_read),
    .uart_out(tx_fifo_write),
    .processor_reset(reset_core),
    .processor_reg_number(),
    .processor_reg_write_data()
);

FIFO #(
    .DEPTH(BUFFER_SIZE),
    .WIDTH(PAYLOAD_BITS)
) TX_FIFO (
    .clk(clk),
    .reset(reset),
    .write(tx_fifo_write),
    .read(tx_fifo_read),
    .write_data(tx_fifo_write_data),
    .full(tx_fifo_full),
    .empty(tx_fifo_empty),
    .read_data(tx_fifo_read_data)
);

FIFO #(
    .DEPTH(BUFFER_SIZE),
    .WIDTH(PAYLOAD_BITS)
) RX_FIFO (
    .clk(clk),
    .reset(reset),
    .write(rx_fifo_write),
    .read(rx_fifo_read),
    .write_data(rx_fifo_write_data),
    .full(rx_fifo_full),
    .empty(rx_fifo_empty),
    .read_data(rx_fifo_read_data)
);

// UART RX
uart_tool_rx #(
    .BIT_RATE(BIT_RATE),
    .PAYLOAD_BITS(PAYLOAD_BITS),
    .CLK_HZ(CLK_FREQ)
) i_uart_rx(
    .clk          (clk          ), // Top level system clock input.
    .resetn       (~reset           ), // Asynchronous active low reset.
    .uart_rxd     (rx    ), // UART Recieve pin.
    .uart_rx_en   (1'b1         ), // Recieve enable
    .uart_rx_break(uart_rx_break), // Did we get a BREAK message?
    .uart_rx_valid(uart_rx_valid), // Valid data recieved and available.
    .uart_rx_data (uart_rx_data )  // The recieved data.
);

//
// UART Transmitter module.
//
uart_tool_tx #(
    .BIT_RATE(BIT_RATE),
    .PAYLOAD_BITS(PAYLOAD_BITS),
    .CLK_HZ(CLK_FREQ)
) i_uart_tx(
    .clk          (clk          ),
    .resetn       (~reset             ),
    .uart_txd     (tx    ), // serial_tx
    .uart_tx_en   (uart_tx_en   ),
    .uart_tx_busy (uart_tx_busy ),
    .uart_tx_data (uart_tx_data ) 
);
    
endmodule
