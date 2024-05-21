module Interpreter #(
    parameter CLOCK_FEQ = 25000000,
    parameter NUM_PAGES = 17,
    parameter PULSE_CONTROL_BITS = 32,
    parameter BUS_WIDTH = 32
) (
    //  Control signals
    input wire clk,
    input wire reset,

    // UART 
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
localparam RESET_CLK_CYCLES = 'd20;

reg [1:0] counter;
reg [3:0] state;
reg [31:0] uart_buffer;
reg [63:0] accumulator;

localparam IDLE = 4'b0000;
localparam FETCH = 4'b0001;
localparam DECODE = 4'b0010;

initial begin
    state = IDLE;
    uart_buffer = 32'h0;
    accumulator = 32'h0;
    counter = 2'b00;
end

always @(posedge clk) begin
    if(reset == 1'b1) begin
        state <= IDLE;
        uart_buffer <= 32'h0;
        accumulator <= 32'h0;
        counter <= 2'b00;
    end else begin
        case (state)
            IDLE: begin
                if(uart_rx_empty == 1'b0) begin
                    state <= FETCH;
                end
                else begin
                    state <= IDLE;
                end
            end 

            FETCH: begin
                if(counter == 2'b11) begin
                    counter <= 2'b00;
                    state <= DECODE;
                end else begin
                    state <= IDLE;
                end
            end

            DECODE: begin
                case (uart_buffer)
                    00: begin

                    end 
                    default: begin
                        
                    end
                endcase
            end

            default: begin
                state <= IDLE;
            end
        endcase
    end
end

always @(*) begin
    case (state)
        IDLE: begin
            
        end

        FETCH: begin
            
        end 

        DECODE: begin
            
        end

    endcase
end
    
endmodule
