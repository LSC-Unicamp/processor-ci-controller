module fifo_tb ();

reg clk, reset, read, write;
reg [7:0] write_data;
wire [7:0] read_data;

initial begin
    clk = 1'b0;
    reset = 1'b0;
end

FIFO #(
    .DEPTH(8),
    .WIDTH(8)
) fifo (
    .clk(clk),
    .reset(reset),
    .write(write),
    .read(read),
    .write_data(write_data),
    .full(),
    .empty(),
    .read_data(read_data)
);

always #1 clk = ~clk;

initial begin
    $dumpfile("build/fifo.vcd");
    $dumpvars;

    clk = 1'b0;
    reset = 1'b1;
    read = 1'b0;
    write = 1'b0;

    #10 reset = 1'b0;

    write_data = 8'h70;
    write = 1'b1;

    #2

    write_data = 8'h71;
    write = 1'b1;

    #2

    read = 1'b1;

    #2

    read = 1'b0;

    #2

    write_data = 8'h72;

    write = 1'b1;

    #2

    read = 1'b1;

    #2

    read = 1'b0;

    #2 

    $finish;
end

endmodule
