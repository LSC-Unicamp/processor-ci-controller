module ClkDivider #(
    parameter COUNTER_BITS       = 32,
    parameter PULSE_CONTROL_BITS = 32
)(
    input  logic clk,
    input  logic rst_n,
    input  logic write_pulse,
    input  logic option,     // 0 - pulse, 1 - auto
    input  logic out_enable, // 0 - no, 1 - yes
    input  logic [COUNTER_BITS-1:0] divider,
    input  logic [PULSE_CONTROL_BITS-1:0] pulse,

    output logic clk_o
);

logic clk_o_pulse;
logic clk_o_auto;
logic       [COUNTER_BITS - 1 : 0] clk_counter;
logic [PULSE_CONTROL_BITS - 1 : 0] pulse_counter;

// Multiplexador da saída
assign clk_o = (!option) ? clk_o_pulse : (out_enable) ? clk_o_auto : 1'b0;

// Liga a saída ao clock enquanto o contador de pulsos for maior do que 0
assign clk_o_pulse = (|pulse_counter) ? clk : 1'b0;

always_ff @(posedge clk or negedge rst_n) begin : CLK_DIVIDER
    if (!rst_n) begin
        clk_counter <= 0;
        clk_o_auto <= 1'b0;
    end else begin
        if (clk_counter == 0) begin
            clk_o_auto <= 1'b1;
            clk_counter <= clk_counter + 1;
        end else if (clk_counter == {1'b0, divider[COUNTER_BITS-1:1]}) begin
            clk_o_auto <= 1'b0;
            clk_counter <= clk_counter + 1;
        end else begin
            clk_counter <= clk_counter + 1;
        end

        if (clk_counter >= divider - 1) begin
            clk_counter <= 0;
        end
    end
end

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        pulse_counter <= 0;
    end else begin
        if (out_enable) begin
            if (pulse_counter > 0) begin
                pulse_counter <= pulse_counter - 1;
            end
        end 
        if (write_pulse) begin
            pulse_counter <= pulse;
        end
    end
end

endmodule