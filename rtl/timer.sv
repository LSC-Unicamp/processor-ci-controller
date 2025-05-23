module Timer (
    input  logic clk,
    input  logic rst_n,

    input  logic upper_i,

    output logic [31:0] read_o,
    output logic [63:0] long_read_o
);


logic [63:0] timer_value;

always_ff @( posedge clk ) begin
    if(!rst_n) begin
        timer_value <= 64'h0;
    end else begin
        timer_value <= timer_value + 1;
    end
end

assign read_o      = (upper_i) ? timer_value[63:32] : timer_value[31:0];
assign long_read_o = timer_value;
    
endmodule