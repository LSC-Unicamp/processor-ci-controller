module ResetBootSystem #(
    parameter int CYCLES = 20
) (
    input  logic clk,
    input  logic start,
    output logic rst_o,
    output logic rst_n_o
);

assign rst_n_o = ~rst_o;

logic [5:0] counter;

typedef enum logic [1:0] { 
    INIT          = 2'b00, 
    RESET_COUNTER = 2'b01, 
    IDLE          = 2'b10
} reset_state_t;

reset_state_t state;

initial begin
    state   = RESET_COUNTER;
    rst_o   = 1'b0;
    counter = 6'h00;
end

always_ff @(posedge clk) begin : RESET_FSM
    if (start) begin
        state <= INIT;
    end else begin
        unique case (state)
            INIT: begin
                rst_o   <= 1'b1;
                state   <= RESET_COUNTER;
                counter <= 6'h00;
            end

            RESET_COUNTER: begin
                if (!rst_o) begin
                    state <= INIT;
                end else begin
                    if (counter < CYCLES) begin
                        counter <= counter + 1;
                    end else if (counter == CYCLES) begin
                        counter <= 0;
                        state   <= IDLE;
                    end else begin
                        state <= INIT;
                    end
                end
            end

            IDLE: begin
                if (counter != 0) begin
                    state <= INIT;
                end else begin
                    rst_o <= 1'b0;
                end
            end

            default: state <= INIT;
        endcase
    end
end

endmodule