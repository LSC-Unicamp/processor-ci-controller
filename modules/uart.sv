module UART #(
    parameter CLK_FREQ     = 25000000,
    parameter BIT_RATE     = 9600,
    parameter PAYLOAD_BITS = 8,
    parameter BUFFER_SIZE  = 8,
    parameter WORD_SIZE_BY = 1
) (
    input  logic clk,
    input  logic rst_n,

    output logic uart_rx_empty,
    output logic uart_tx_empty,

    input  logic rx,
    output logic tx,

    input  logic read,
    input  logic write,
    output logic read_response,
    output logic write_response,

    input  logic [31:0] write_data,
    output logic [31:0] read_data
);

logic uart_rx_valid, uart_rx_break, uart_tx_busy, tx_fifo_empty,
    rx_fifo_empty, tx_fifo_full, rx_fifo_full;
logic uart_tx_en, tx_fifo_read, tx_fifo_write, rx_fifo_read, 
    rx_fifo_write;
logic [PAYLOAD_BITS-1:0]  uart_rx_data, tx_fifo_data_out, 
    rx_fifo_data_out;
logic [PAYLOAD_BITS-1:0] uart_tx_data, tx_fifo_data_in, 
    rx_fifo_data_in;

logic [31:0] write_data_buffer;

logic [2:0] counter_write, counter_read;
logic [3:0] state_read, state_write;

assign uart_rx_empty = rx_fifo_empty;
assign uart_tx_empty = tx_fifo_empty;

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

always_ff @(posedge clk ) begin
    rx_fifo_read   <= 1'b0;
    read_response  <= 1'b0;

    if(!rst_n) begin
        state_read   <= IDLE;
        rx_fifo_read <= 1'b0;
        read_data    <= 32'h00000000;
        counter_read <= 3'b000;
    end else begin
        unique case (state_read)
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
                        read_data <= {read_data[23:0], rx_fifo_data_out};
                        counter_read <= counter_read + 1'b1;
                        rx_fifo_read <= 1'b1;
                        state_read <= COPY_READ_BUFFER;
                    end
                end else begin
                    read_data <= {read_data[23:0], rx_fifo_data_out};
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

always_ff @(posedge clk ) begin
    write_response <= 1'b0;
    tx_fifo_write  <= 1'b0;

    if(!rst_n) begin
        state_write        <= IDLE;
        tx_fifo_write      <= 1'b0;
        tx_fifo_data_in <= 8'h00;
        write_data_buffer  <= 32'h00000000;
        counter_write      <= 3'b000;
    end else begin
        unique case (state_write)
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
                        tx_fifo_data_in <= write_data_buffer[31:24];
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


always_ff @(posedge clk) begin
    rx_fifo_write <= 1'b0;

    if(!rst_n) begin
        rx_fifo_data_in <= 8'h00;
        rx_fifo_write   <= 1'b0;
    end else begin
        if(rx_fifo_full == 1'b0 && uart_rx_valid == 1'b1) begin
            rx_fifo_data_in <= uart_rx_data;
            rx_fifo_write      <= 1'b1;
        end
    end 
end

typedef enum logic [1:0] { 
    TX_FIFO_IDLE,
    TX_FIFO_READ_FIFO,
    TX_FIFO_WRITE_TX,
    TX_FIFO_WAIT
} tx_read_fifo_state_t;

tx_read_fifo_state_t tx_read_fifo_state;

always_ff @(posedge clk) begin : UART_TX_READ_FROM_FIFO
    uart_tx_en   <= 1'b0;
    tx_fifo_read <= 1'b0;

    if(!rst_n) begin
        uart_tx_data <= 8'h00;
    end else begin
        unique case (tx_read_fifo_state)
            TX_FIFO_IDLE: begin
                if(!tx_fifo_empty && !uart_tx_busy) begin
                    tx_read_fifo_state <= TX_FIFO_READ_FIFO;
                    tx_fifo_read  <= 1'b1;
                end
            end
            TX_FIFO_READ_FIFO: begin
                tx_read_fifo_state <= TX_FIFO_WRITE_TX;
            end
            TX_FIFO_WRITE_TX: begin
                uart_tx_data       <= tx_fifo_data_out;
                uart_tx_en         <= 1'b1;
                tx_read_fifo_state <= TX_FIFO_WAIT;
            end
            TX_FIFO_WAIT: begin
                tx_read_fifo_state <= TX_FIFO_IDLE;
            end
            default: tx_read_fifo_state <= TX_FIFO_IDLE;
        endcase
    end
end

FIFO #(
    .DEPTH        (BUFFER_SIZE),
    .WIDTH        (PAYLOAD_BITS)
) tx_fifo (
    .clk          (clk),
    .rst_n        (rst_n),

    .wr_en_i      (tx_fifo_write),
    .rd_en_i      (tx_fifo_read),

    .write_data_i (tx_fifo_data_in),
    .full_o       (tx_fifo_full),
    .empty_o      (tx_fifo_empty),
    .read_data_o  (tx_fifo_data_out)
);

FIFO #(
    .DEPTH        (BUFFER_SIZE),
    .WIDTH        (PAYLOAD_BITS)
) rx_fifo (
    .clk          (clk),
    .rst_n        (rst_n),

    .wr_en_i      (rx_fifo_write),
    .rd_en_i      (rx_fifo_read),

    .write_data_i (rx_fifo_data_in),
    .full_o       (rx_fifo_full),
    .empty_o      (rx_fifo_empty),
    .read_data_o  (rx_fifo_data_out)
);


// UART RX
uart_rx #(
    .BIT_RATE     (BIT_RATE),
    .PAYLOAD_BITS (PAYLOAD_BITS),
    .CLK_HZ       (CLK_FREQ)
) i_uart_rx(
    .clk          (clk          ), // Top level system clock input.
    .resetn       (rst_n        ), // Asynchronous active low reset.
    .uart_rxd     (rx           ), // UART Recieve pin.
    .uart_rx_en   (1'b1         ), // Recieve enable
    .uart_rx_break(uart_rx_break), // Did we get a BREAK message?
    .uart_rx_valid(uart_rx_valid), // Valid data recieved and available.
    .uart_rx_data (uart_rx_data )  // The recieved data.
);

//
// UART Transmitter module.
//
uart_tx #(
    .BIT_RATE     (BIT_RATE),
    .PAYLOAD_BITS (PAYLOAD_BITS),
    .CLK_HZ       (CLK_FREQ)
) i_uart_tx(
    .clk          (clk         ),
    .resetn       (rst_n       ),
    .uart_txd     (tx          ), // serial_tx
    .uart_tx_en   (uart_tx_en  ),
    .uart_tx_busy (uart_tx_busy),
    .uart_tx_data (uart_tx_data) 
);
    
endmodule
