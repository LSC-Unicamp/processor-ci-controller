module FIFO #(
    parameter DEPTH = 8,
    parameter WIDTH = 8
) (
    input wire clk,
    input wire reset,
    input wire write,
    input wire read,
    input wire [WIDTH-1:0] write_data,
    output wire full,
    output wire empty,
    output reg [WIDTH-1:0] read_data
);

reg [WIDTH-1:0] memory[DEPTH-1:0];
reg [5:0] read_ptr;
reg [5:0] write_ptr;

initial begin
    read_ptr = 6'd0;
    write_ptr = 6'd0;
end


always @(posedge clk ) begin
    if(reset) begin
        read_ptr <= 6'd0;
    end else begin
        if(read == 1'b1 && empty == 1'b0) begin
            read_data <= memory[read_ptr];
            read_ptr <= (read_ptr == DEPTH-1'b1) ? 'd0 : read_ptr + 1'b1;
        end
    end
end

always @(posedge clk ) begin
    if(reset) begin
        write_ptr <= 6'd0;
    end else begin
        if(write == 1'b1 && full == 1'b0) begin
            memory[write_ptr] <= write_data;
            write_ptr <= (write_ptr == DEPTH-1'b1) ? 'd0 : write_ptr + 1'b1;
        end
    end
end

assign full = ((write_ptr == read_ptr - 1) || (write_ptr == DEPTH-1 && read_ptr == 'd0)) ? 1'b1 : 1'b0;
assign empty = (write_ptr == read_ptr) ? 1'b1 : 1'b0;
    
endmodule