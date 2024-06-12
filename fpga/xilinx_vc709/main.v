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



always @(posedge clk_ref) begin
    clk_o = ~clk_o;
end

endmodule