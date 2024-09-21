module SPI #(
    parameter BUFFER_SIZE  = 32,
    parameter PAYLOAD_BITS = 8,
    parameter WORD_SIZE_BY = 4
)(
    // Timing signals
    input clk,
    input reset,

    // SPI Signals
    input wire sck,
    input wire cs,
    input wire mosi,
    input wire miso,

    // SPI callback signals
    input wire rw,
    output wire intr,

    // FIFOs signals
    output wire tx_fifo_empty,
    output wire rx_fifo_empty,

    // BUS control signals
    input wire read,
    input wire write,
    output reg read_response,
    output reg write_response,

    // BUS signals
    input wire [31:0] write_data,
    output reg [31:0] read_data
);

wire tx_fifo_empty, rx_fifo_empty, tx_fifo_full, rx_fifo_full;

reg tx_fifo_read, tx_fifo_write, rx_fifo_read, rx_fifo_write;

wire [PAYLOAD_BITS-1:0] data_out, tx_fifo_read_data, rx_fifo_read_data;

reg [PAYLOAD_BITS-1:0] data_in, tx_fifo_write_data, rx_fifo_write_data, data_to_send;

reg [31:0] write_data_buffer;

reg [2:0] counter_write, counter_read;
reg [3:0] state_read, state_write;

reg [2:0] busy_sync;
reg data_in_valid, rw_bausing, reload, readed, readed_trash;
wire rst, busy, data_out_valid, busy_posedge;

assign busy_posedge = (busy_sync[2:1] == 2'b01) ? 1'b1 : 1'b0;

reg [1:0] read_state_machine, write_state_machine;

localparam IDLE              = 3'b000;
localparam READ              = 3'b001;
localparam WRITE             = 3'b001;
localparam WB                = 3'b010;
localparam FINISH            = 3'b011;
localparam COPY_WRITE_BUFFER = 3'b100;
localparam COPY_READ_BUFFER  = 3'b100;

/*
Read state machine:
    IDLE -> READ -> WB -> FINISH
*/
always @(posedge clk ) begin
    rx_fifo_read   <= 1'b0;
    read_response  <= 1'b0;

    if(reset == 1'b1) begin
        read_state_machine <= IDLE;
    end else begin
        case (read_state_machine)
            IDLE: begin
                if(read) begin
                    read_state_machine <= READ;
                end else begin
                    read_state_machine <= IDLE;
                end
            end

            READ: begin
                if(counter_read < (WORD_SIZE_BY)) begin
                    if(rx_fifo_empty == 1'b0) begin
                        read_data <= {read_data[23:0], rx_fifo_read_data};
                        counter_read <= counter_read + 1'b1;
                        rx_fifo_read <= 1'b1;
                        read_state_machine <= COPY_READ_BUFFER;
                    end
                end else begin
                    read_data <= {read_data[23:0], rx_fifo_read_data};
                    read_state_machine <= WB;
                end
            end

            COPY_READ_BUFFER: begin
                read_state_machine <= READ;
            end

            WB: begin
                read_response      <= 1'b1;
                read_state_machine <= FINISH;
            end

            FINISH: begin
                read_response      <= 1'b1;
                read_state_machine <= IDLE;
            end

            default: read_state_machine <= IDLE;
        endcase  
    end 
end

/*
Write state machine:
    IDLE -> COPY_WRITE_BUFFER -> WRITE -> WB -> FINISH
*/

always @(posedge clk ) begin
    tx_fifo_write  <= 1'b0;
    read_response  <= 1'b0;
    
    if(reset == 1'b1) begin
        write_state_machine <= IDLE;
    end else begin
        case (write_state_machine)
            IDLE: begin
                if(write) begin
                    write_state_machine <= COPY_WRITE_BUFFER;
                    data_to_send        <= write_data;
                end else begin
                    write_state_machine <= IDLE;
                end
            end

            COPY_WRITE_BUFFER: begin
                write_data_buffer   <= write_data;
                write_state_machine <= WRITE;
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
                    write_state_machine <= WB;
                end
            end

            WB: begin
                write_response      <= 1'b1;
                write_state_machine <= FINISH;
            end

            FINISH: begin
                write_response      <= 1'b1;
                write_state_machine <= IDLE;
            end

            default: write_state_machine <= IDLE;
        endcase   
    end
end

// sync busy and make rw anti bausing
always @(posedge clk ) begin
    busy_sync <= {busy_sync[1:0], busy};
    rw_bausing <= rw;

    if(reset == 1'b1) begin
        busy_sync <= 3'b000;
    end
end

reg read_state;

// read from TX queue and insert in uart
always @(posedge clk ) begin
    if(reset == 1'b1) begin
        reload        <= 1'b1;
        read_state    <= 1'b0;
        data_in_valid <= 1'b1;
        readed        <= 1'b0;
        data_in       <= 8'h00;
        readed_trash  <= 1'b1;
    end else begin
        if(busy_posedge == 1'b1 || reload == 1'b1) begin
            data_in_valid <= 1'b1;
            reload        <= 1'b0;
            if(rw_bausing == 1'b0) begin  // apenas faço logica se estiver no momento de ler
               if(readed == 1'b0) begin
                    readed <= 1'b1;
                end else begin
                    readed_trash <= 1'b1;
                end 
            end
        end else begin
            data_in_valid <= 1'b0;
        end

        case (read_state)
            1'b0: begin
                if(tx_fifo_empty == 1'b0 && readed == 1'b1) begin
                    tx_fifo_read <= 1'b1;
                    read_state   <= 1'b1;
                end 
            end
            1'b1: begin
                read_state <= 1'b0;
                readed     <= 1'b0;
                data_in    <= tx_fifo_read_data;

                if(zero == 1'b1) begin
                    zero   <= 1'b0;
                    reload <= 1'b1;
                end
            end 
        endcase
    end
end

// Read from uart and insert in RX queue
always @(posedge clk ) begin
    rx_fifo_write <= 1'b0;

    if(reset == 1'b1) begin
        rx_fifo_write      <= 1'b0;
        rx_fifo_write_data <= 8'h00;
    end else begin
        if(data_out_valid == 1'b1 && rw_bausing == 1'b1 // apenas escrevo se for momento de escrever
            && rx_fifo_full == 1'b0) begin
            
            rx_fifo_write      <= 1'b1;
            rx_fifo_write_data <= data_out;
        end
    end
end

SPI_Slave #(
    .SPI_BITS_PER_WORD(PAYLOAD_BITS)
) U1 (
    .clk(clk),
    .rst(reset),

    .sck (sck),
    .cs  (cs),
    .mosi(mosi),
    .miso(miso),

    .data_in_valid (data_in_valid),
    .data_out_valid(data_out_valid),
    .busy          (busy),

    .data_in (data_in),
    .data_out(data_out)
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


endmodule

