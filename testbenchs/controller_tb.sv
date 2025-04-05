`timescale 1ns / 1ns

module controller_tb();

logic clk, rx, rst_n, tx;

initial begin
    $dumpfile("build/controller.vcd");
    $dumpvars;
    clk = 0;
    rst_n = 0;

    #20 rst_n = 1;

    #3000;

    $finish;
end

logic [7:0] uart_rx_data;

always #1 clk = ~clk;

parameter BIT_RATE     = 115200;
parameter PAYLOAD_BITS = 8;
parameter CLK_FREQ     = 50000000;

uart_rx #(
    .BIT_RATE     (BIT_RATE),
    .PAYLOAD_BITS (PAYLOAD_BITS),
    .CLK_HZ       (CLK_FREQ)
) i_uart_rx(
    .clk          (clk          ), // Top level system clock input.
    .resetn       (rst_n        ), // Asynchronous active low reset.
    .uart_rxd     (tx           ), // UART Recieve pin.
    .uart_rx_en   (1'b1         ), // Recieve enable
    .uart_rx_break(             ), // Did we get a BREAK message?
    .uart_rx_valid(             ), // Valid data recieved and available.
    .uart_rx_data (uart_rx_data )  // The recieved data.
);

uart_tx #(
    .BIT_RATE     (BIT_RATE),
    .PAYLOAD_BITS (PAYLOAD_BITS),
    .CLK_HZ       (CLK_FREQ)
) tx_tb (
    .clk          (clk    ),
    .resetn       (rst_n  ),
    .uart_txd     (rx     ), // serial_tx
    .uart_tx_en   (tx_en  ),
    .uart_tx_busy (tx_busy),
    .uart_tx_data (tx_data) 
);

logic [7:0] tx_data;
logic tx_en;
logic tx_busy;


Controller #(
    .CLK_FREQ           (50000000),
    .BIT_RATE           (115200),
    .PAYLOAD_BITS       (8),
    .BUFFER_SIZE        (8),
    .PULSE_CONTROL_BITS (32),
    .BUS_WIDTH          (32),
    .WORD_SIZE_BY       (4),
    .ID                 (32'h7700006A),
    .RESET_CLK_CYCLES   (20),
    .MEMORY_FILE        (""),
    .MEMORY_SIZE        (4096)
) u_Controller (
    .clk                (clk),
    .rst_n              (rst_n),
    
    // SPI signals
    .sck_i              (),
    .cs_i               (),
    .mosi_i             (),
    .miso_o             (),
    
    // SPI callback signals
    .rw_i               (),
    .intr_o             (),
    
    // UART signals
    .rx                 (rx),
    .tx                 (tx),
    
    // Clock, reset, and bus signals
    .clk_core_o         (),
    .rst_core_o         (),
    
    // Barramento padrão (não AXI4-Lite)
    .core_cyc_i         (),
    .core_stb_i         (),
    .core_we_i          (),
    .core_addr_i        (),
    .core_data_i        (),
    .core_data_o        (),
    .core_ack_o         ()
);


logic [7:0] tx_data_memory [0:16];
logic [3:0] pointer;

initial begin
    tx_data_memory[0] = 8'h00;
    tx_data_memory[1] = 8'h00;
    tx_data_memory[2] = 8'h00;
    tx_data_memory[3] = 8'h70;
    tx_data_memory[4] = 8'h00;
    tx_data_memory[5] = 8'h00;
    tx_data_memory[6] = 8'h00;
    tx_data_memory[7] = 8'h57;
    tx_data_memory[8] = 8'h73;
    tx_data_memory[9] = 8'h75;
    tx_data_memory[10]= 8'h6E;
    tx_data_memory[11]= 8'h67;
    tx_data_memory[12]= 8'h00;
    tx_data_memory[13]= 8'h00;
    tx_data_memory[14]= 8'h00;
    tx_data_memory[15]= 8'h4C;
end


always_ff @( posedge clk ) begin : TX_DATA_SEND
    if (rst_n) begin
        tx_data <= 8'h00;
        pointer <= 0;
    end else begin
        if (!tx_busy && ~(&pointer)) begin
            tx_data <= tx_data_memory[pointer];
            pointer <= pointer + 1;
            tx_en   <= 1'b1;
        end else begin
            tx_en   <= 1'b0;
        end
    end
    
end

endmodule
