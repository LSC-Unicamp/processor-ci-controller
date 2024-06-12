`timescale 1ns / 1ps

module top(
    input  wire clk_ref_p,
    input  wire clk_ref_n,
    input  wire button_center,
    input  wire RxD,
    output wire TxD,
    input  wire [7:0] gpio_switch,
    output wire [7:0]led
);
    
reg clk_o;

initial begin
    clk_o = 1'b0; // 100mhz
end


wire clk_ref; // Sinal de clock single-ended

// Instância do buffer diferencial
IBUFDS #(
    .DIFF_TERM("FALSE"),     // Habilita ou desabilita o terminador diferencial
    .IBUF_LOW_PWR("TRUE"),   // Ativa o modo de baixa potência
    .IOSTANDARD("DIFF_SSTL15")
) ibufds_inst (
    .O(clk_ref),    // Clock single-ended de saída
    .I(clk_ref_p),  // Entrada diferencial positiva
    .IB(clk_ref_n)  // Entrada diferencial negativa
);

wire clk_core, reset_core, core_memory_response, reset_o;

ResetBootSystem #(
    .CYCLES(20)
) ResetBootSystem(
    .clk(clk),
    .reset_o(reset_o)
);

Controller #(
    .CLK_FREQ(100000000),
    .BIT_RATE(115200),
    .PAYLOAD_BITS(8),
    .BUFFER_SIZE(8),
    .PULSE_CONTROL_BITS(32),
    .BUS_WIDTH(32),
    .WORD_SIZE_BY(4),
    .ID(32'h0000004A),
    .RESET_CLK_CYCLES(20)
) Controller(
    .clk(clk_o),
    .reset(reset_o),

    .tx(TxD),
    .rx(RxD),

    .clk_core(clk_core),
    .reset_core(reset_core),
    
    .core_memory_response(core_memory_response),
    .core_read_memory(),
    .core_write_memory(),
    .core_address_memory(),
    .core_write_data_memory(),
    .core_read_data_memory()
);


always @(posedge clk_ref) begin
    clk_o = ~clk_o;
end

endmodule
