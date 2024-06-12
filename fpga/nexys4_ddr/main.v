module top (
    input  wire clk,
    input  wire CPU_RESETN,
    input  wire rx,
    output wire tx,
    output wire [7:0]LED,
    input  wire [7:0]gpio
);

wire [7:0] led;
reg clk_o;

assign LED = ~led;

initial begin
    clk_o = 1'b0; // 50mhz
end

always @(posedge clk) begin
    clk_o = ~clk_o;
end

endmodule
