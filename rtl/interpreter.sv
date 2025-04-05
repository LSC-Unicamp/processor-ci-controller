module Interpreter #(
    parameter CLK_FREQ           = 25000000,
    parameter PULSE_CONTROL_BITS = 32,
    parameter BUS_WIDTH          = 32,
    parameter ID                 = 32'h7700006A,
    parameter RESET_CLK_CYCLES   = 20
) (
    // Control signals
    input  logic clk,
    input  logic rst_n,

    // communication
    input  logic communication_rx_empty,
    input  logic communication_tx_empty,

    output logic communication_read,
    output logic communication_write,
    input  logic communication_read_response,
    input  logic communication_write_response, 

    input  logic [31:0] communication_read_data,
    output logic [31:0] communication_write_data,

    // Core signals
    output logic core_clk_enable,
    output logic core_reset,
    output logic [PULSE_CONTROL_BITS-1:0] num_of_cycles_to_pulse,
    output logic write_pulse,

    // BUS signals
    input  logic finish_execution,
    output logic reset_bus,
    output logic bus_mode, // 1 - pagination mode, 0 - normal mode
    output logic [23:0] memory_page_size,
    output logic [31:0] end_position,

    // Memory BUS signal
    input  logic memory_response,
    output logic memory_read,
    output logic memory_write,
    output logic memory_mux_selector,
    output logic [23:0] memory_page_number,
    output logic [BUS_WIDTH-1:0] write_data,
    output logic [BUS_WIDTH-1:0] address,
    input  logic [BUS_WIDTH-1:0] read_data
);

localparam RUN_TESTS_FINISH_MESSAGE = 32'h676F6F64;
localparam UNTIL_FINISH_MESSAGE     = 32'h6C75636B;
localparam TIMEOUT_CLK_CYCLES       = 'd360;
localparam DELAY_CYCLES             = 'd30;

logic [7:0] counter;
logic [23:0] num_of_pages, num_of_positions;
logic [31:0] communication_buffer, read_buffer, timeout, timeout_counter;
logic [63:0] accumulator, temp_buffer;

typedef enum logic [7:0] {
    IDLE                                = 8'b00000000,
    FETCH                               = 8'b00000001,
    DECODE                              = 8'b00000010,
    SEND_READ_BUFFER                    = 8'b00000011,
    WAIT_WRITE_RESPONSE                 = 8'b00000100,
    MEMORY_READ                         = 8'b00000101,
    READ_SECOND_PAGE_FROM_SERIAL        = 8'b00000110,
    SAVE_SECOND_WORD_IN_MEMORY          = 8'b00000111,
    MEMORY_WRITE_LOOP                   = 8'b00001000,
    READ_WORD_FROM_SERIAL               = 8'b00001001,
    SAVE_WORD                           = 8'b00001010,
    MEMORY_READ_LOOP                    = 8'b00001011,
    READ_WORD_FROM_MEMORY               = 8'b00001100,
    RESET_CORE_LOOP                     = 8'b00001101,
    RESET_CORE_END                      = 8'b00001110,
    UNTIL_ENABLE_CORE                   = 8'b00001111,
    UNTIL_END_POINT_WAIT                = 8'b00010000,
    SEND_UNTIL_FINISH_MESSAGE           = 8'b00010001,
    RUN_TESTS_ENABLE_CORE               = 8'b00010010,
    RUN_TESTS_WAIT                      = 8'b00010011,
    RUN_TESTS_UPDATE_PAGE               = 8'b00010100,
    RUN_TESTS_FINISH                    = 8'b00010101,
    RUN_TESTS_INIT                      = 8'b00010110,
    SEND_UNTIL_RELATORY                 = 8'b00010111,
    WRITE_CLK                           = 8'b01000011, // C - 0x43
    STOP_CLK                            = 8'b01010011, // S - 0x53
    RESUME_CLK                          = 8'b01110010, // r - 0x72
    RESET_CORE                          = 8'b01010010, // R - 0x52
    WRITE_IN_MEMORY                     = 8'b01010111, // W - 0x57
    READ_FROM_MEMORY                    = 8'b01001100, // L - 0x4C
    LOAD_UPPER_ACUMULATOR               = 8'b01010101, // U - 0x55
    LOAD_LOWER_ACUMULATOR               = 8'b01101100, // l - 0x6C
    ADD_N_TO_ACUMULATOR                 = 8'b01000001, // A - 0x41
    WRITE_ACUMULATOR_IN_POS_N           = 8'b01110111, // w - 0x77
    WRITE_N_IN_POS_ACUMULATOR           = 8'b01110011, // s - 0x73
    READ_ACUMULATOR_POS_IN_MEMORY       = 8'b01000111, // G - 0x47
    SET_TIMEOUT                         = 8'b01010100, // T - 0x54
    SET_MEMORY_PAGE_SIZE                = 8'b01010000, // P - 0x50
    RUN_TESTS                           = 8'b01000101, // E - 0x45
    PING                                = 8'b01110000, // p - 0x70
    DEFINE_N_AS_PROGRAM_FINISH_POSITION = 8'b01000100, // D - 0x44
    DEFINE_ACC_AS_PROG_FINISH_POSITION  = 8'b01100100, // d - 0x64
    GET_ACUMULATOR                      = 8'b01100001, // a - 0x61
    SWITCH_MEMORY_TO_CORE               = 8'b01001111, // O - 0x4F
    WRITE_NEXT_N_WORDS_FROM_ACUMULATOR  = 8'b01100101, // e - 0x65
    READ_NEXT_N_WORDS_FROM_ACUMULATOR   = 8'b01001101, // M - 0x4D
    UNTIL_END_POINT                     = 8'b01110101  // u - 0x75
} interpreter_state_t;

interpreter_state_t state, return_state;

always @(posedge clk) begin
    communication_read  <= 1'b0;
    communication_write <= 1'b0;
    core_reset          <= 1'b0;
    write_pulse         <= 1'b0;
    memory_read         <= 1'b0;
    memory_write        <= 1'b0;
    reset_bus           <= 1'b0;

    if(!rst_n) begin
        state                <= IDLE;
        communication_buffer <= 32'h0;
        accumulator          <= 64'h0;
        counter              <= 8'h00;
        core_clk_enable      <= 1'b0;
        memory_mux_selector  <= 1'b0;
        return_state         <= IDLE;
        num_of_pages         <= 24'h0;
        timeout_counter      <= 8'h00;
        reset_bus            <= 1'b1;
        bus_mode             <= 1'b0;
        end_position         <= 32'h0;
        read_buffer          <= 32'h0;
        timeout              <= 32'h0;
    end else begin
        case (state)
            IDLE: begin
                counter <= 8'h00;
                if(!communication_rx_empty) begin
                    state <= FETCH;
                end else begin
                    state <= IDLE;
                end
            end 

            FETCH: begin
                communication_read   <= 1'b1;
                communication_buffer <= communication_read_data;

                if(!communication_read_response) begin
                    state <= DECODE;
                end else begin
                    state <= FETCH;
                end
            end

            DECODE: begin
                return_state <= IDLE;
                case (communication_buffer[7:0])
                    WRITE_CLK:                           state <= WRITE_CLK;
                    STOP_CLK:                            state <= STOP_CLK;
                    RESUME_CLK:                          state <= RESUME_CLK;
                    RESET_CORE:                          state <= RESET_CORE;
                    WRITE_IN_MEMORY:                     state <= WRITE_IN_MEMORY;
                    READ_FROM_MEMORY:                    state <= READ_FROM_MEMORY;
                    LOAD_UPPER_ACUMULATOR:               state <= LOAD_UPPER_ACUMULATOR;
                    LOAD_LOWER_ACUMULATOR:               state <= LOAD_LOWER_ACUMULATOR;
                    ADD_N_TO_ACUMULATOR:                 state <= ADD_N_TO_ACUMULATOR;
                    WRITE_ACUMULATOR_IN_POS_N:           state <= WRITE_ACUMULATOR_IN_POS_N;
                    WRITE_N_IN_POS_ACUMULATOR:           state <= WRITE_N_IN_POS_ACUMULATOR;
                    READ_ACUMULATOR_POS_IN_MEMORY:       state <= READ_ACUMULATOR_POS_IN_MEMORY;
                    SET_TIMEOUT:                         state <= SET_TIMEOUT;
                    SET_MEMORY_PAGE_SIZE:                state <= SET_MEMORY_PAGE_SIZE;
                    RUN_TESTS:                           state <= RUN_TESTS;
                    PING:                                state <= PING;
                    DEFINE_N_AS_PROGRAM_FINISH_POSITION: state <= DEFINE_N_AS_PROGRAM_FINISH_POSITION;
                    DEFINE_ACC_AS_PROG_FINISH_POSITION:  state <= DEFINE_ACC_AS_PROG_FINISH_POSITION;
                    GET_ACUMULATOR:                      state <= GET_ACUMULATOR;
                    SWITCH_MEMORY_TO_CORE:               state <= SWITCH_MEMORY_TO_CORE;
                    WRITE_NEXT_N_WORDS_FROM_ACUMULATOR:  state <= WRITE_NEXT_N_WORDS_FROM_ACUMULATOR;
                    READ_NEXT_N_WORDS_FROM_ACUMULATOR:   state <= READ_NEXT_N_WORDS_FROM_ACUMULATOR;
                    UNTIL_END_POINT:                     state <= UNTIL_END_POINT;
                    default: state <= IDLE;
                endcase
            end

            WRITE_CLK: begin
                core_clk_enable        <= 1'b1;
                num_of_cycles_to_pulse <= {8'h00, communication_buffer[31:8]};
                write_pulse            <= 1'b1;
                state                  <= IDLE;
            end
            STOP_CLK: begin
                core_clk_enable <= 1'b0;
                state           <= IDLE;
            end

            RESUME_CLK: begin
                core_clk_enable <= 1'b1;
                state           <= IDLE;
            end

            RESET_CORE: begin
                counter                <= 8'h00;
                core_reset             <= 1'b1;
                core_clk_enable        <= 1'b1;
                num_of_cycles_to_pulse <= RESET_CLK_CYCLES;
                write_pulse            <= 1'b1;
                state                  <= RESET_CORE_LOOP;
            end

            RESET_CORE_LOOP: begin
                core_reset <= 1'b1;
                counter    <= counter + 1'b1;
                if(counter == RESET_CLK_CYCLES) begin
                    core_clk_enable <= 1'b0;
                    state <= RESET_CORE_END;
                end else begin
                    state <= RESET_CORE_LOOP;
                end
            end

            RESET_CORE_END: begin
                core_reset      <= 1'b0;
                core_clk_enable <= 1'b0;
                state           <= return_state;
            end

            WRITE_IN_MEMORY: begin
                memory_mux_selector <= 1'b0;
                address             <= {communication_buffer[31], 6'h0, communication_buffer[30:8], 2'b0};

                if(!communication_rx_empty) begin
                    state <= READ_SECOND_PAGE_FROM_SERIAL;
                end else begin
                    state <= WRITE_IN_MEMORY;
                end
            end

            READ_SECOND_PAGE_FROM_SERIAL: begin
                communication_read   <= 1'b1;
                communication_buffer <= communication_read_data;

                if(!communication_read_response) begin
                    state <= SAVE_SECOND_WORD_IN_MEMORY;
                end else begin
                    state <= READ_SECOND_PAGE_FROM_SERIAL;
                end
            end

            SAVE_SECOND_WORD_IN_MEMORY: begin
                memory_mux_selector <= 1'b0;
                write_data          <= communication_buffer[31:0];
                memory_write        <= 1'b1;
                state               <= IDLE;
            end

            READ_FROM_MEMORY: begin
                memory_mux_selector <= 1'b0;
                address             <= {communication_buffer[31], 6'h0, communication_buffer[30:8], 2'b0};
                memory_read         <= 1'b1;
                state               <= MEMORY_READ;
            end

            LOAD_UPPER_ACUMULATOR: begin
                accumulator <= {32'h0, communication_buffer[31:8], accumulator[7:0]};
                state       <= IDLE;
            end

            LOAD_LOWER_ACUMULATOR: begin
                accumulator <= {accumulator[63:8], communication_buffer[15:8]};
                state       <= IDLE;
            end

            ADD_N_TO_ACUMULATOR: begin
                accumulator <= accumulator + {{40{communication_buffer[31]}}, communication_buffer[31:8]};
                state       <= IDLE;
            end

            WRITE_ACUMULATOR_IN_POS_N: begin
                memory_mux_selector <= 1'b0;
                address             <= {communication_buffer[31], 6'h0, communication_buffer[30:8], 2'b0}; // ver alinhamento depois
                write_data          <= accumulator[31:0];
                memory_write        <= 1'b1;
                state               <= IDLE;
            end

            WRITE_N_IN_POS_ACUMULATOR: begin
                memory_mux_selector <= 1'b0;
                address             <= accumulator[31:0]; // ver alinhamento depois
                write_data          <= {8'h0, communication_buffer[31:8]};
                memory_write        <= 1'b1;
                state               <= IDLE;
            end

            READ_ACUMULATOR_POS_IN_MEMORY: begin
                memory_mux_selector <= 1'b0;
                address             <= accumulator[31:0] + {6'h0, communication_buffer[31:8], 2'b0}; // ver alinhamento depois
                memory_read         <= 1'b1;
                state               <= MEMORY_READ;
                return_state        <= IDLE;
            end

            MEMORY_READ: begin
                read_buffer <= read_data;
                state       <= SEND_READ_BUFFER;
            end

            SET_TIMEOUT: begin
                timeout <= {8'h0, communication_buffer[31:8]};
                state   <= IDLE;
            end

            SET_MEMORY_PAGE_SIZE: begin
                memory_page_size <= communication_buffer[31:8];
                state            <= IDLE;
            end

            PING: begin
                read_buffer  <= ID;
                state        <= SEND_READ_BUFFER;
                return_state <= IDLE;
            end

            GET_ACUMULATOR: begin
                read_buffer  <= accumulator[31:0];
                state        <= SEND_READ_BUFFER;
                return_state <= IDLE;
            end

            DEFINE_N_AS_PROGRAM_FINISH_POSITION: begin
                end_position <= {6'h00, communication_buffer[31:8], 2'b00};
                state        <= IDLE;
            end

            DEFINE_ACC_AS_PROG_FINISH_POSITION: begin
                end_position <= accumulator[31:0];
                state        <= IDLE;
            end

            SWITCH_MEMORY_TO_CORE: begin
                memory_mux_selector <= 1'b1;
                state               <= IDLE;
            end

            WRITE_NEXT_N_WORDS_FROM_ACUMULATOR: begin
                memory_mux_selector <= 1'b0;
                num_of_positions    <= {8'h0, communication_buffer[31:8]};
                temp_buffer         <= accumulator;
                state               <= MEMORY_WRITE_LOOP;
            end

            MEMORY_WRITE_LOOP: begin
                if(!num_of_positions) begin
                    state <= IDLE;
                end else begin
                    num_of_positions <= num_of_positions - 1'b1;
                    state            <= READ_WORD_FROM_SERIAL;
                    address          <= temp_buffer[31:0];
                    temp_buffer      <= temp_buffer + 32'h4;
                end
            end

            READ_WORD_FROM_SERIAL: begin
                communication_read   <= 1'b1;
                communication_buffer <= communication_read_data;

                if(!communication_read_response) begin
                    state <= SAVE_WORD;
                end else begin
                    state <= READ_WORD_FROM_SERIAL;
                end
            end

            SAVE_WORD: begin
                memory_mux_selector <= 1'b0;
                write_data          <= communication_buffer[31:0];
                memory_write        <= 1'b1;

                state               <= MEMORY_WRITE_LOOP;
            end


            READ_NEXT_N_WORDS_FROM_ACUMULATOR: begin
                memory_mux_selector <= 1'b0;
                num_of_positions    <= {8'h0, communication_buffer[31:8]};
                temp_buffer         <= accumulator;
                state               <= MEMORY_READ_LOOP;
            end

            MEMORY_READ_LOOP: begin
                if(num_of_positions == 'd0) begin
                    state <= IDLE;
                end else begin
                    num_of_positions <= num_of_positions - 1'b1;
                    state            <= READ_WORD_FROM_MEMORY;
                    address          <= temp_buffer[31:0];
                    temp_buffer      <= temp_buffer + 32'h4;
                end
            end

            READ_WORD_FROM_MEMORY: begin
                memory_mux_selector <= 1'b0;
                memory_read         <= 1'b1;
                state               <= MEMORY_READ;
                return_state        <= MEMORY_READ_LOOP;
            end

            SEND_READ_BUFFER: begin
                communication_write_data <= read_buffer;
                communication_write      <= 1'b1;
                state                    <= WAIT_WRITE_RESPONSE;
            end

            WAIT_WRITE_RESPONSE: begin
                if(communication_write_response) begin
                    state <= return_state;
                end else begin
                    state <= WAIT_WRITE_RESPONSE;
                end
            end

            RUN_TESTS: begin
                memory_mux_selector <= 1'b0;
                num_of_pages        <= communication_buffer[31:8];
                bus_mode            <= 1'b1;
                memory_page_number  <= 24'h0;
                state               <= RUN_TESTS_INIT;
            end

            RUN_TESTS_INIT: begin
                reset_bus           <= 1'b1;
                timeout_counter     <= 32'h0;
                if(memory_page_number == num_of_pages) begin
                    state <= RUN_TESTS_FINISH;
                end else begin
                    state               <= RESET_CORE;
                    return_state        <= RUN_TESTS_ENABLE_CORE;
                end
            end

            RUN_TESTS_ENABLE_CORE: begin
                core_clk_enable        <= 1'b1;
                state                  <= RUN_TESTS_WAIT;
                num_of_cycles_to_pulse <= timeout;
                write_pulse            <= 1'b1;
            end

            RUN_TESTS_WAIT: begin
                timeout_counter <= timeout_counter + 1'b1;
                if(finish_execution == 1'b1 || timeout < timeout_counter ) begin
                    state <= RUN_TESTS_UPDATE_PAGE;
                end else begin
                    state <= RUN_TESTS_WAIT;
                end
            end

            RUN_TESTS_UPDATE_PAGE: begin
                core_clk_enable    <= 1'b0;
                memory_page_number <= memory_page_number + 1'b1;
                state              <= RUN_TESTS_INIT;
            end

            RUN_TESTS_FINISH: begin
                bus_mode        <= 1'b0;
                core_clk_enable <= 1'b0;
                read_buffer     <= RUN_TESTS_FINISH_MESSAGE;
                state           <= SEND_READ_BUFFER;
                return_state    <= IDLE;
            end

            UNTIL_END_POINT: begin
                memory_mux_selector <= 1'b1;
                bus_mode            <= 1'b0;
                reset_bus           <= 1'b1;
                timeout_counter     <= 32'h0;
                state               <= RESET_CORE;
                return_state        <= UNTIL_ENABLE_CORE;
            end

            UNTIL_ENABLE_CORE: begin
                core_clk_enable        <= 1'b1;
                state                  <= UNTIL_END_POINT_WAIT;
                num_of_cycles_to_pulse <= timeout;
                write_pulse            <= 1'b1;
            end

            UNTIL_END_POINT_WAIT: begin
                timeout_counter <= timeout_counter + 1'b1;
                if(finish_execution || timeout == timeout_counter ) begin
                    state <= SEND_UNTIL_FINISH_MESSAGE;
                end else begin
                    state <= UNTIL_END_POINT_WAIT;
                end
            end

            SEND_UNTIL_FINISH_MESSAGE: begin
                reset_bus           <= 1'b1;
                core_clk_enable     <= 1'b0;
                memory_mux_selector <= 1'b0;
                read_buffer         <= UNTIL_FINISH_MESSAGE;
                state               <= SEND_READ_BUFFER;
                return_state        <= SEND_UNTIL_RELATORY;
            end

            SEND_UNTIL_RELATORY: begin
                read_buffer  <= {timeout_counter[30:0], timeout >= timeout_counter};
                state        <= SEND_READ_BUFFER;
                return_state <= IDLE;
            end

            default: begin
                state <= IDLE;
            end
        endcase
    end
end

endmodule
// 00 00 03 65 73 6F 66 69 6C 61 69 73 67 61 62 69
// 80 00 00 55