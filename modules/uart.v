module UART #(
    parameter CLK_FREQ     = 25000000,
    parameter BIT_RATE     = 9600,
    parameter PAYLOAD_BITS = 8,
    parameter BUFFER_SIZE  = 8,
    parameter WORD_SIZE_BY = 1
) (
    input wire clk,
    input wire reset,

    output wire uart_rx_empty,
    output wire uart_tx_empty,

    input wire rx,
    output wire tx,

    input wire read,
    input wire write,
    output reg read_response,
    output reg write_response,

    input wire [31:0] write_data,
    output reg [31:0] read_data
);

wire uart_rx_valid, uart_rx_break, uart_tx_busy, tx_fifo_empty,
    rx_fifo_empty, tx_fifo_full, rx_fifo_full;
reg uart_tx_en, tx_fifo_read, tx_fifo_write, rx_fifo_read, 
    rx_fifo_write;
wire [PAYLOAD_BITS-1:0]  uart_rx_data, tx_fifo_read_data, 
    rx_fifo_read_data;
reg [PAYLOAD_BITS-1:0] uart_tx_data, tx_fifo_write_data, 
    rx_fifo_write_data;

reg [31:0] write_data_buffer;

reg [2:0] counter_write, counter_read;
reg [3:0] state_read, state_write;

assign uart_rx_empty = rx_fifo_empty;
assign uart_tx_empty = tx_fifo_empty;

initial begin
    read_response      = 1'b0;
    write_response     = 1'b0;
    uart_tx_en         = 1'b0;
    tx_fifo_read       = 1'b0;
    tx_fifo_write      = 1'b0;
    rx_fifo_read       = 1'b0;
    rx_fifo_write      = 1'b0;
    counter_read       = 2'b00;
    state_read         = 3'b00;
    counter_write      = 2'b00;
    state_write        = 3'b00;
    uart_tx_data       = 8'h00;
    tx_fifo_write_data = 8'h00;
    rx_fifo_write_data = 8'h00;
    read_data          = 32'h00000000;
end

localparam IDLE               = 4'b0000;
localparam READ               = 4'b0001;
localparam WRITE              = 4'b0001;
localparam WB                 = 4'b0010;
localparam FINISH             = 4'b0011;
localparam COPY_WRITE_BUFFER  = 4'b0100;
localparam COPY_READ_BUFFER   = 4'b0100;

/*
Read state machine:
    IDLE -> READ -> WB -> FINISH
*/

always @(posedge clk ) begin
    rx_fifo_read   <= 1'b0;
    read_response  <= 1'b0;

    if(reset == 1'b1) begin
        state_read         <= IDLE;
        rx_fifo_read       <= 1'b0;
        read_data          <= 32'h00000000;
        counter_read       <= 3'b000;
    end else begin
        case (state_read)
            IDLE: begin
                counter_read <= 3'b000;
                if(read) begin
                    state_read <= READ;
                end else begin
                    state_read <= IDLE;
                end
            end

            READ: begin
                if(counter_read < (WORD_SIZE_BY)) begin
                    if(rx_fifo_empty == 1'b0) begin
                        read_data <= {read_data[23:0], rx_fifo_read_data};
                        counter_read <= counter_read + 1'b1;
                        rx_fifo_read <= 1'b1;
                        state_read <= COPY_READ_BUFFER;
                    end
                end else begin
                    read_data <= {read_data[23:0], rx_fifo_read_data};
                    state_read <= WB;
                end
            end

            COPY_READ_BUFFER: begin
                state_read <= READ;
            end

            WB: begin
                read_response <= 1'b1;
                state_read <= FINISH;
            end

            FINISH: begin
                read_response  <= 1'b1;
                state_read <= IDLE;
            end

            default: state_read <= IDLE;
        endcase
    end
end

/*
Write state machine:
    IDLE -> COPY_WRITE_BUFFER -> WRITE -> WB -> FINISH
*/

always @(posedge clk ) begin
    write_response <= 1'b0;
    tx_fifo_write  <= 1'b0;

    if(reset == 1'b1) begin
        state_write        <= IDLE;
        tx_fifo_write      <= 1'b0;
        tx_fifo_write_data <= 8'h00;
        write_data_buffer  <= 32'h00000000;
        counter_write      <= 3'b000;
    end else begin
        case (state_write)
            IDLE: begin
                counter_write <= 3'b000;
                if(write) begin
                    state_write <= COPY_WRITE_BUFFER;
                end else begin
                    state_write <= IDLE;
                end
            end

            COPY_WRITE_BUFFER: begin
                write_data_buffer <= write_data;
                state_write       <= WRITE;
            end

            WRITE: begin
                if(counter_write < WORD_SIZE_BY) begin
                    if(tx_fifo_full == 1'b0) begin
                        tx_fifo_write_data <= write_data_buffer[31:24];
                        write_data_buffer  <= {write_data_buffer[23:0], 8'h00};
                        counter_write      <= counter_write + 1'b1;
                        tx_fifo_write      <= 1'b1;
                    end
                end else begin
                    state_write <= WB;
                end
            end

            WB: begin
                write_response <= 1'b1;
                state_write    <= FINISH;
            end

            FINISH: begin
                write_response <= 1'b1;
                state_write    <= IDLE;
            end

            default: state_write <= IDLE;
        endcase
    end
end


always @(posedge clk) begin
    rx_fifo_write <= 1'b0;

    if(reset == 1'b1) begin
        rx_fifo_write_data <= 8'h00;
        rx_fifo_write      <= 1'b0;
    end else begin
        if(rx_fifo_full == 1'b0 && uart_rx_valid == 1'b1) begin
            rx_fifo_write_data <= uart_rx_data;
            rx_fifo_write      <= 1'b1;
        end
    end 
end

reg [1:0] tx_fifo_read_state;

always @(posedge clk ) begin
    uart_tx_en <= 1'b0;
    tx_fifo_read <= 1'b0;

    if(reset == 1'b1) begin
        uart_tx_en         <= 1'b0;
        tx_fifo_read       <= 1'b0;
        uart_tx_data       <= 8'h00;
        tx_fifo_read_state <= 2'b00;
    end else begin
        case (tx_fifo_read_state)
            2'b00: begin
                if(uart_tx_busy == 1'b0 && tx_fifo_empty == 1'b0) begin
                    tx_fifo_read <= 1'b1;
                    tx_fifo_read_state <= 2'b01;
                end
            end

            2'b01: begin
                tx_fifo_read_state <= 2'b10; // estado para transição dos  dados
            end

            2'b10: begin
                uart_tx_en   <= 1'b1;
                uart_tx_data <= tx_fifo_read_data;
                tx_fifo_read_state <= 2'b11;
            end

            2'b11: begin
                tx_fifo_read_state <= 2'b00; // estado para transição dos  dados
            end

            default: tx_fifo_read_state <= 2'b00;
        endcase
    end 
end

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
uart_rx #(
    .BIT_RATE(BIT_RATE),
    .PAYLOAD_BITS(PAYLOAD_BITS),
    .CLK_HZ(CLK_FREQ)
) i_uart_rx(
    .clk          (clk          ), // Top level system clock input.
    .resetn       (~reset       ), // Asynchronous active low reset.
    .uart_rxd     (rx    ), // UART Recieve pin.
    .uart_rx_en   (1'b1         ), // Recieve enable
    .uart_rx_break(uart_rx_break), // Did we get a BREAK message?
    .uart_rx_valid(uart_rx_valid), // Valid data recieved and available.
    .uart_rx_data (uart_rx_data )  // The recieved data.
);

//
// UART Transmitter module.
//
uart_tx #(
    .BIT_RATE(BIT_RATE),
    .PAYLOAD_BITS(PAYLOAD_BITS),
    .CLK_HZ(CLK_FREQ)
) i_uart_tx(
    .clk          (clk          ),
    .resetn       (~reset       ),
    .uart_txd     (tx    ), // serial_tx
    .uart_tx_en   (uart_tx_en   ),
    .uart_tx_busy (uart_tx_busy ),
    .uart_tx_data (uart_tx_data ) 
);
    
endmodule
