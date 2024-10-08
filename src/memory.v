module Memory #(
    parameter MEMORY_FILE = "",
    parameter MEMORY_SIZE = 4096
)(
    input wire clk,
    input wire reset,
    input wire memory_read,
    input wire memory_write,
    input wire [31:0] address,
    input wire [31:0] write_data,
    output wire [31:0] read_data,
    output reg [31:0] read_sync,
    output wire response,
    output reg sync_write_response,
    output reg sync_read_response
);

reg [31:0] memory [(MEMORY_SIZE/4)-1: 0];
integer i;

assign read_data = (memory_read == 1'b1) ? memory[{2'b00, address[31:2]}] : 32'h00000000;
assign response = memory_read | memory_write;

initial begin
    `ifdef __ICARUS__
        for (i = 0; i < (MEMORY_SIZE/4)-1; i = i + 1) begin
            memory[i] = 32'h00000000; 
        end
    `endif

    if(MEMORY_FILE != "") begin
        $readmemh(MEMORY_FILE, memory, 0, (MEMORY_SIZE/4) - 1);
    end
end

always @(posedge clk) begin
    if(memory_read == 1'b1) begin
        read_sync <= memory[{2'b00, address[31:2]}];
    end
    if(memory_write == 1'b1) begin
        memory[{2'b00, address[31:2]}] <= write_data;
    end
end

always @(posedge clk ) begin
    sync_write_response <= memory_write;
    sync_read_response <= memory_read;
end
    
endmodule
