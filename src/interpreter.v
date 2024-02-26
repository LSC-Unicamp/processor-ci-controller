module Interpreter #(
    parameter CLK_FREQ = 25000000
) (
    input wire clk,
    input wire reset,

    input wire [2:0] uart_state
);


localparam IDLE = 3'b000;
localparam ESCREVER_UART = 3'b001;
localparam RESET_PROCESSADOR = 3'b010;
localparam LER_RESULTADO_ALU = 3'b011;
localparam LER_REGISTRADOR = 3'b100;
localparam ESCREVER_REGISTRADOR = 3'b101;
localparam LER_MEMORIA = 3'b110;
localparam ESCREVER_MEMORIA = 3'b111;


reg [2:0] current_state, next_state;


// Cuidar da mudança de estados
always @(posedge clk) begin
    if(reset == 1) begin
        current_state = 3'b000;
    end

    else begin

        case(current_state) 

            IDLE: begin
                // Ler da UART
            end

            ESCREVER_UART: begin
                // Escrever UART
            end

            RESET_PROCESSADOR: begin

            end

            LER_RESULTADO_ALU: begin

            end

            LER_REGISTRADOR: begin

            end

            ESCREVER_REGISTRADOR: begin

            end

            LER_MEMORIA: begin

            end

            ESCREVER_MEMORIA: begin

            end
            
            default: begin
                current_state = 3'b000;
            end
        endcase 
    end
end



always @(current_state) begin

    case(current_state) 

        IDLE: begin
        
        end

        ESCREVER_UART: begin
        
        end

        RESET_PROCESSADOR: begin

        end

        LER_RESULTADO_ALU: begin

        end

        LER_REGISTRADOR: begin

        end

        ESCREVER_REGISTRADOR: begin

        end

        LER_MEMORIA: begin

        end

        ESCREVER_MEMORIA: begin

        end
        
        default: begin
            current_state = 3'b000;
        end
    endcase 
end

end

endmodule
