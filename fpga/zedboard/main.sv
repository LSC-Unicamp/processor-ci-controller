module top (
    input logic GCLK,
    output logic [7:0] LED
);

assign LED = 8'b10101010; // Example pattern for LEDs
    
endmodule