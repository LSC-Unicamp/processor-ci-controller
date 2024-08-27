module Interpreter #(
    parameter CLK_FREQ = 25000000,
    parameter PULSE_CONTROL_BITS = 32,
    parameter BUS_WIDTH = 32,
    parameter ID = 32'h7700006A,
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
    input wire uart_read_response,
    input wire uart_write_response,

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

reg [7:0] state, counter, return_state;
reg [23:0] memory_page_size, num_of_positions;
reg [31:0] uart_buffer, read_buffer, timeout, end_position;
reg [63:0] accumulator, temp_buffer;

localparam IDLE                                = 8'b00000000;
localparam FETCH                               = 8'b00000001;
localparam DECODE                              = 8'b00000010;
localparam SEND_READ_BUFFER                    = 8'b00000011;
localparam WAIT_WRITE_RESPONSE                 = 8'b00000100;
localparam MEMORY_READ                         = 8'b00000101;
localparam READ_SECOND_PAGE_FROM_SERIAL        = 8'b00000110;
localparam SAVE_SECOND_WORD_IN_MEMORY          = 8'b00000111;
localparam MEMORY_WRITE_LOOP                   = 8'b00001000;
localparam READ_WORD_FROM_SERIAL               = 8'b00001001;
localparam SAVE_WORD                           = 8'b00001010;
localparam MEMORY_READ_LOOP                    = 8'b00001011;
localparam READ_WORD_FROM_MEMORY               = 8'b00001100;
localparam WRITE_CLK                           = 8'b01000011; // C - 0x43
localparam STOP_CLK                            = 8'b01010011; // S - 0x53
localparam RESUME_CLK                          = 8'b01110010; // r - 0x72
localparam RESET_CORE                          = 8'b01010010; // R - 0x52
localparam WRITE_IN_MEMORY                     = 8'b01010111; // W - 0x57
localparam READ_FROM_MEMORY                    = 8'b01001100; // L - 0x4C
localparam LOAD_UPPER_ACUMULATOR               = 8'b01010101; // U - 0x55
localparam LOAD_LOWER_ACUMULATOR               = 8'b01101100; // l - 0x6C
localparam ADD_N_TO_ACUMULATOR                 = 8'b01000001; // A - 0x41
localparam WRITE_ACUMULATOR_IN_POS_N           = 8'b01110111; // w - 0x77
localparam WRITE_N_IN_POS_ACUMULATOR           = 8'b01110011; // s - 0x73
localparam READ_ACUMULATOR_POS_IN_MEMORY       = 8'b01000111; // G - 0x47
localparam SET_TIMEOUT                         = 8'b01010100; // T - 0x54
localparam SET_MEMORY_PAGE_SIZE                = 8'b01010000; // P - 0x50
localparam RUN_TESTS                           = 8'b01000101; // E - 0x45
localparam PING                                = 8'b01110000; // p - 0x70
localparam DEFINE_N_AS_PROGRAM_FINISH_POSITION = 8'b01000100; // D - 0x44
localparam DEFINE_ACUMULATOR_AS_PROGRAM_FINISH_POSITION = 8'b01100100; // d - 0x64
localparam GET_ACUMULATOR                      = 8'b01100001; // a - 0x61
localparam SWITCH_MEMORY_TO_CORE               = 8'b01001111; // O - 0x4F
localparam WRITE_NEXT_N_WORDS_FROM_ACUMULATOR  = 8'b01001110; // N - 0x4E
localparam READ_NEXT_N_WORDS_FROM_ACUMULATOR   = 8'b01001101; // M - 0x4D



initial begin
    state = IDLE;
    counter = 8'h00;
    read_buffer = 32'h0;
    timeout = 32'h0;
    accumulator = 64'h0;
end

always @(posedge clk) begin
    uart_read       <= 1'b0;
    uart_write      <= 1'b0;
    core_reset      <= 1'b0;
    write_pulse     <= 1'b0;
    memory_read     <= 1'b0;
    memory_write    <= 1'b0;

    if(reset == 1'b1) begin
        state <= IDLE;
        uart_buffer <= 32'h0;
        accumulator <= 64'h0;
        counter <= 8'h00;
        core_clk_enable <= 1'b0;
        memory_mux_selector <= 1'b0;
        return_state <= IDLE;
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
            end 

            FETCH: begin
                uart_read <= 1'b1;
                uart_buffer <= uart_read_data;

                if(uart_read_response == 1'b1) begin
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
                    GET_ACUMULATOR: state <= GET_ACUMULATOR;
                    SWITCH_MEMORY_TO_CORE: state <= SWITCH_MEMORY_TO_CORE;
                    WRITE_NEXT_N_WORDS_FROM_ACUMULATOR: state <= WRITE_NEXT_N_WORDS_FROM_ACUMULATOR;
                    READ_NEXT_N_WORDS_FROM_ACUMULATOR: state <= READ_NEXT_N_WORDS_FROM_ACUMULATOR;
                    default: state <= IDLE;
                endcase
            end

            WRITE_CLK: begin
                core_clk_enable <= 1'b1;
                num_of_cycles_to_pulse <= {8'h00, uart_buffer[31:8]};
                write_pulse <= 1'b1;
                state <= IDLE;
            end
            STOP_CLK: begin
                core_clk_enable <= 1'b0;
                state <= IDLE;
            end

            RESUME_CLK: begin
                core_clk_enable <= 1'b1;
                state <= IDLE;
            end

            RESET_CORE: begin
                core_reset <= 1'b1;

                if(counter == RESET_CLK_CYCLES) begin
                    state <= IDLE;
                end else begin
                    state <= RESET_CORE;
                end
            end

            WRITE_IN_MEMORY: begin
                memory_mux_selector <= 1'b0;
                address <= {8'h0, uart_buffer[31:8]};

                if(uart_rx_empty == 1'b0) begin
                    state <= READ_SECOND_PAGE_FROM_SERIAL;
                end else begin
                    state <= WRITE_IN_MEMORY;
                end
            end

            READ_SECOND_PAGE_FROM_SERIAL: begin
                uart_read <= 1'b1;
                uart_buffer <= uart_read_data;

                if(uart_read_response == 1'b1) begin
                    state <= SAVE_SECOND_WORD_IN_MEMORY;
                end else begin
                    state <= READ_SECOND_PAGE_FROM_SERIAL;
                end
            end

            SAVE_SECOND_WORD_IN_MEMORY: begin
                memory_mux_selector <= 1'b0;
                write_data <= uart_buffer[31:0];
                memory_write <= 1'b1;
                state <= IDLE;
            end

            READ_FROM_MEMORY: begin
                memory_mux_selector <= 1'b0;
                address <= uart_buffer[31:8];
                memory_read <= 1'b1;
                state <= MEMORY_READ;
            end

            LOAD_UPPER_ACUMULATOR: begin
                accumulator <= {32'h0, uart_buffer[31:8], accumulator[7:0]};
                state <= IDLE;
            end

            LOAD_LOWER_ACUMULATOR: begin
                accumulator <= {accumulator[63:8], uart_buffer[15:8]};
                state <= IDLE;
            end

            ADD_N_TO_ACUMULATOR: begin
                accumulator <= accumulator + {{40{uart_buffer[31]}}, uart_buffer[31:8]};
                state <= IDLE;
            end

            WRITE_ACUMULATOR_IN_POS_N: begin
                memory_mux_selector <= 1'b0;
                address <= {8'h0, uart_buffer[31:8]}; // ver alinhamento depois
                write_data <= accumulator[31:0];
                memory_write <= 1'b1;
                state <= IDLE;
            end

            WRITE_N_IN_POS_ACUMULATOR: begin
                memory_mux_selector <= 1'b0;
                address <= accumulator[31:0]; // ver alinhamento depois
                write_data <= {8'h0, uart_buffer[31:8]};
                memory_write <= 1'b1;
                state <= IDLE;
            end

            READ_ACUMULATOR_POS_IN_MEMORY: begin
                memory_mux_selector <= 1'b0;
                address <= accumulator[31:0]; // ver alinhamento depois
                memory_read <= 1'b1;
                state <= MEMORY_READ;
                return_state <= IDLE;
            end

            MEMORY_READ: begin
                read_buffer <= read_data;
                state <= SEND_READ_BUFFER;
            end

            SET_TIMEOUT: begin
                timeout <= {8'h0, uart_buffer[31:8]};
                state <= IDLE;
            end

            SET_MEMORY_PAGE_SIZE: begin
                memory_page_size <= uart_buffer[31:8];
                state <= IDLE;
            end

            RUN_TESTS: begin
                
            end

            PING: begin
                read_buffer <= ID;
                state <= SEND_READ_BUFFER;
                return_state <= IDLE;
            end

            GET_ACUMULATOR: begin
                read_buffer <= accumulator[31:0];
                state <= SEND_READ_BUFFER;
                return_state <= IDLE;
            end

            DEFINE_N_AS_PROGRAM_FINISH_POSITION: begin
                end_position <= {8'h0, uart_buffer[31:8]};
                state <= IDLE;
            end

            DEFINE_ACUMULATOR_AS_PROGRAM_FINISH_POSITION: begin
                end_position <= accumulator[31:0];
                state <= IDLE;
            end

            SWITCH_MEMORY_TO_CORE: begin
                memory_mux_selector <= 1'b1;
                state <= IDLE;
            end

            WRITE_NEXT_N_WORDS_FROM_ACUMULATOR: begin
                memory_mux_selector <= 1'b0;
                num_of_positions <= {8'h0, uart_buffer[31:8]};
                temp_buffer <= accumulator;
                state <= MEMORY_WRITE_LOOP;
            end

            MEMORY_WRITE_LOOP: begin
                if(num_of_positions == 1'b0) begin
                    state <= IDLE;
                end else begin
                    num_of_positions <= num_of_positions - 1'b1;
                    state <= READ_WORD_FROM_SERIAL;
                    address <= temp_buffer[31:0];
                    temp_buffer <= temp_buffer + 32'h4;
                end
            end

            READ_WORD_FROM_SERIAL: begin
                uart_read <= 1'b1;
                uart_buffer <= uart_read_data;

                if(uart_read_response == 1'b1) begin
                    state <= SAVE_WORD;
                end else begin
                    state <= READ_WORD_FROM_SERIAL;
                end
            end

            SAVE_WORD: begin
                memory_mux_selector <= 1'b0;
                write_data <= uart_buffer[31:0];
                memory_write <= 1'b1;

                state <= MEMORY_WRITE_LOOP;
            end


            READ_NEXT_N_WORDS_FROM_ACUMULATOR: begin
                memory_mux_selector <= 1'b0;
                num_of_positions <= {8'h0, uart_buffer[31:8]};
                temp_buffer <= accumulator;
                state <= MEMORY_READ_LOOP;
            end

            MEMORY_READ_LOOP: begin
                if(num_of_positions == 1'b0) begin
                    state <= IDLE;
                end else begin
                    num_of_positions <= num_of_positions - 1'b1;
                    state <= READ_WORD_FROM_MEMORY;
                    address <= temp_buffer[31:0];
                    temp_buffer <= temp_buffer + 32'h4;
                end
            end

            READ_WORD_FROM_MEMORY: begin
                memory_mux_selector <= 1'b0;
                memory_read <= 1'b1;
                state <= MEMORY_READ;
                return_state <= MEMORY_READ_LOOP;
            end

            SEND_READ_BUFFER: begin
                uart_write_data <= read_buffer;
                uart_write <= 1'b1;
                state <= WAIT_WRITE_RESPONSE;
            end

            WAIT_WRITE_RESPONSE: begin
                if(uart_write_response == 1'b1) begin
                    state <= return_state;
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

endmodule
