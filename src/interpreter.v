module Interpreter #(
    parameter CLK_FREQ = 25000000,
    parameter PULSE_CONTROL_BITS = 32,
    parameter BUS_WIDTH = 32,
    parameter ID = 32'h00000001,
    parameter RESET_CLK_CYCLES = 20
) (
    //  Control signals
    input wire clk,
    input wire reset,

    // UART 
    input wire uart_rx_empty,
    input wire uart_tx_empty,

    output reg uart_read,
    output reg uart_write,
    input wire uart_response,

    input wire [31:0] uart_read_data,
    output reg [31:0] uart_write_data,

    // Core signals
    output reg core_clk_enable,
    output reg core_reset,
    output reg [PULSE_CONTROL_BITS - 1:0] num_of_cycles_to_pulse,
    output reg write_pulse,

    // Memory BUS signal
    input wire memory_response,
    output reg memory_read,
    output reg memory_write,
    output reg memory_mux_selector, // 0 - controler, 1 - core
    output reg [7:0] memory_page_number,
    output reg [BUS_WIDTH - 1:0] write_data,
    output reg [BUS_WIDTH - 1:0] address,
    input wire [BUS_WIDTH - 1:0] read_data
);

localparam TIMEOUT_CLK_CYCLES = 'd360;
localparam DELAY_CYCLES = 'd30;

reg [7:0] state, counter;
reg [23:0] memory_page_size;
reg [31:0] uart_buffer, read_buffer, timeout, end_position;
reg [63:0] accumulator;

localparam IDLE                                = 8'b00000000;
localparam FETCH                               = 8'b00000001;
localparam DECODE                              = 8'b00000010;
localparam SEND_READ_BUFFER                    = 8'b00000011;
localparam WAIT_WRITE_RESPONSE                 = 8'b00000100;
localparam WRITE_CLK                           = 8'b01000011; // C
localparam STOP_CLK                            = 8'b01010011; // S
localparam RESUME_CLK                          = 8'b01110010; // r
localparam RESET_CORE                          = 8'b01010010; // R
localparam WRITE_IN_MEMORY                     = 8'b01010111; // W
localparam READ_FROM_MEMORY                    = 8'b01001100; // L
localparam LOAD_UPPER_ACUMULATOR               = 8'b01010101; // U
localparam LOAD_LOWER_ACUMULATOR               = 8'b01101100; // l
localparam ADD_N_TO_ACUMULATOR                 = 8'b01000001; // A
localparam WRITE_ACUMULATOR_IN_POS_N           = 8'b01110111; // w
localparam WRITE_N_IN_POS_ACUMULATOR           = 8'b01110011; // s
localparam READ_ACUMULATOR_POS_IN_MEMORY       = 8'b01110010; // r
localparam SET_TIMEOUT                         = 8'b01010100; // T
localparam SET_MEMORY_PAGE_SIZE                = 8'b01010000; // P
localparam RUN_TESTS                           = 8'b01000101; // E
localparam PING                                = 8'b01110000; // p
localparam DEFINE_N_AS_PROGRAM_FINISH_POSITION = 8'b01000100; // D
localparam DEFINE_ACUMULATOR_AS_PROGRAM_FINISH_POSITION = 8'b01100100; // d



initial begin
    state = IDLE;
    counter = 8'h00;
    uart_buffer = 32'h0;
    read_buffer = 32'h0;
    timeout = 32'h0;
    accumulator = 64'h0;
end

always @(posedge clk) begin
    if(reset == 1'b1) begin
        state <= IDLE;
        uart_buffer <= 32'h0;
        accumulator <= 32'h0;
        counter <= 8'h00;
    end else begin
        case (state)
            IDLE: begin
                counter <= 8'h00;
                if(uart_rx_empty == 1'b0) begin
                    state <= FETCH;
                end
                else begin
                    state <= IDLE;
                end
                //state <= PING;
            end 

            FETCH: begin
                if(uart_response == 1'b1) begin
                    state <= DECODE;
                end else begin
                    state <= FETCH;
                end
            end

            DECODE: begin
                case (uart_buffer[7:0])
                    WRITE_CLK: state <= WRITE_CLK;
                    STOP_CLK: state <= STOP_CLK;
                    RESUME_CLK: state <= RESUME_CLK;
                    RESET_CORE: state <= RESET_CORE;
                    WRITE_IN_MEMORY: state <= WRITE_IN_MEMORY;
                    READ_FROM_MEMORY: state <= READ_FROM_MEMORY;
                    LOAD_UPPER_ACUMULATOR: state <= LOAD_UPPER_ACUMULATOR;
                    LOAD_LOWER_ACUMULATOR: state <= LOAD_LOWER_ACUMULATOR;
                    ADD_N_TO_ACUMULATOR: state <= ADD_N_TO_ACUMULATOR;
                    WRITE_ACUMULATOR_IN_POS_N: state <= WRITE_ACUMULATOR_IN_POS_N;
                    WRITE_N_IN_POS_ACUMULATOR: state <= WRITE_N_IN_POS_ACUMULATOR;
                    READ_ACUMULATOR_POS_IN_MEMORY: state <= READ_ACUMULATOR_POS_IN_MEMORY;
                    SET_TIMEOUT: state <= SET_TIMEOUT;
                    SET_MEMORY_PAGE_SIZE: state <= SET_MEMORY_PAGE_SIZE;
                    RUN_TESTS: state <= RUN_TESTS;
                    PING: state <= PING;
                    DEFINE_N_AS_PROGRAM_FINISH_POSITION: state <= DEFINE_N_AS_PROGRAM_FINISH_POSITION;
                    DEFINE_ACUMULATOR_AS_PROGRAM_FINISH_POSITION: state <= DEFINE_ACUMULATOR_AS_PROGRAM_FINISH_POSITION;
                    default: state <= IDLE;
                endcase
            end

            WRITE_CLK: state <= IDLE;
            STOP_CLK: state <= IDLE;
            RESUME_CLK: state <= IDLE;

            RESET_CORE: begin
                if(counter == RESET_CLK_CYCLES) begin
                    state <= IDLE;
                end else begin
                    state <= RESET_CORE;
                end
            end

            WRITE_IN_MEMORY: begin
                
            end

            READ_FROM_MEMORY: begin

            end

            LOAD_UPPER_ACUMULATOR: state <= IDLE;
            LOAD_LOWER_ACUMULATOR: state <= IDLE;
            ADD_N_TO_ACUMULATOR: state <= IDLE;

            WRITE_ACUMULATOR_IN_POS_N: begin

            end

            WRITE_N_IN_POS_ACUMULATOR: begin

            end

            READ_ACUMULATOR_POS_IN_MEMORY: begin

            end

            SET_TIMEOUT: state <= IDLE;
            SET_MEMORY_PAGE_SIZE: state <= IDLE;
            RUN_TESTS: begin
                
            end

            PING: state <= SEND_READ_BUFFER;

            DEFINE_N_AS_PROGRAM_FINISH_POSITION: state <= IDLE;
            DEFINE_ACUMULATOR_AS_PROGRAM_FINISH_POSITION: state <= IDLE;

            SEND_READ_BUFFER: state <= WAIT_WRITE_RESPONSE;

            WAIT_WRITE_RESPONSE: begin
                if(uart_response == 1'b1) begin
                    state <= IDLE;
                end else begin
                    state <= WAIT_WRITE_RESPONSE;
                end
            end

            default: begin
                state <= IDLE;
            end
        endcase
    end
end

always @(posedge clk) begin
    uart_read       <= 1'b0;
    uart_write      <= 1'b0;
    core_clk_enable <= 1'b0;
    core_reset      <= 1'b0;
    write_pulse     <= 1'b0;
    memory_read     <= 1'b0;
    memory_write    <= 1'b0;
    //memory_mux_selector <= 1'b1;

    case (state)
        IDLE: begin
            
        end

        FETCH: begin
            uart_read <= 1'b1;
            uart_buffer <= uart_read_data;
        end 

        DECODE: begin
            
        end

        WRITE_CLK: begin
            core_clk_enable <= 1'b1;
            num_of_cycles_to_pulse <= {8'h00, uart_buffer[31:8]};
            write_pulse <= 1'b1;
        end

        STOP_CLK: begin
            core_clk_enable <= 1'b0;
        end

        RESUME_CLK: begin
            core_clk_enable <= 1'b1;
        end

        RESET_CORE: begin
            core_reset <= 1'b1;
        end

        WRITE_IN_MEMORY: begin
            memory_mux_selector <= 1'b0;
            address <= {8'h0, uart_buffer[31:8]};
        end

        READ_FROM_MEMORY: begin
            memory_mux_selector <= 1'b0;
            address <= uart_buffer[31:8];
            read_buffer <= read_data;
            memory_read <= 1'b1;
        end

        LOAD_UPPER_ACUMULATOR: begin
            accumulator <= {32'h0, uart_buffer[31:8], accumulator[7:0]};
        end

        LOAD_LOWER_ACUMULATOR: begin
            accumulator <= {accumulator[63:8], uart_buffer[7:0]};
        end

        ADD_N_TO_ACUMULATOR: begin
            accumulator <= accumulator + {40'h0, uart_buffer[31:8]};
        end

        WRITE_ACUMULATOR_IN_POS_N: begin
            address <= {8'h0, uart_buffer[31:8]}; // ver alinhamento depois
            write_data <= accumulator[31:0];
            memory_write <= 1'b1;
        end

        WRITE_N_IN_POS_ACUMULATOR: begin
            address <= accumulator[31:0]; // ver alinhamento depois
            write_data <= {8'h0, uart_buffer[31:8]};
            memory_write <= 1'b1;
        end

        READ_ACUMULATOR_POS_IN_MEMORY: begin
            address <= accumulator[31:0]; // ver alinhamento depois
            memory_read <= 1'b1;
            read_buffer <= read_data;
        end

        SET_TIMEOUT: begin
            timeout <= {8'h0, uart_buffer[31:8]};
        end

        SET_MEMORY_PAGE_SIZE: begin
            memory_page_size <= uart_buffer[31:8];
        end

        RUN_TESTS: begin

        end

        PING: begin
            read_buffer <= ID;
        end

        DEFINE_N_AS_PROGRAM_FINISH_POSITION: begin
            end_position <= {8'h0, uart_buffer[31:8]};
        end

        DEFINE_ACUMULATOR_AS_PROGRAM_FINISH_POSITION: begin
            end_position <= accumulator[31:0];
        end

        SEND_READ_BUFFER: begin
            uart_write_data <= read_buffer;
            uart_write <= 1'b1;
        end

        WAIT_WRITE_RESPONSE: begin
            
        end

    endcase
end
    
endmodule
