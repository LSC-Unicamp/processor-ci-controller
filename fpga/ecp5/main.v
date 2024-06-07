module top (
    input wire clk,
    input wire reset,
    input wire rx,
    output wire tx,
    output wire [7:0]led,
    inout [5:0]gpios
);

Controller #(
    .CLK_FREQ(25000000)
) Controller(
    .clk(clk),
    .tx(tx),
    .rx(rx)
);
    
endmodule
