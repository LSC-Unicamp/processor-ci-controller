module Interpreter #(
    parameter CLK_FREQ = 25000000
) (
    input wire clk,
    input wire reset,

    // inputs/sinais provenientes do processador
    input [31:0] processor_alu_result,
    input [31:0] processor_reg_data,

    input wire uart_rx_empty,
    input wire uart_tx_empty,
    input wire uart_rx_full,
    input wire uart_tx_full,
    input wire [7:0] uart_in,
    
    output reg write_uart,
    output reg read_uart,
    output reg [7:0] uart_out,

    // outputs de sinais de controle pro processador 

    // outputs/sinais que irão para o processador
    output reg processor_reset,
    output reg [4:0] processor_reg_number,
    output reg [31:0] processor_reg_write_data,


);


localparam IDLE                   = 4'b0000;
localparam ESCREVER_UART          = 4'b0001;
localparam RESET_PROCESSADOR      = 4'b0010;
localparam LER_RESULTADO_ALU      = 4'b0011;
localparam LER_REGISTRADOR        = 4'b0100;
localparam ESCREVER_REGISTRADOR   = 4'b0101;
localparam LER_MEMORIA            = 4'b0110;
localparam ESCREVER_MEMORIA       = 4'b0111;
localparam PULSO_CLOCK            = 4'b1000;
localparam DECODE_UART            = 4'b1001;
// acelerar e desacelerar o cock da placa???

reg [4:0] current_state;
reg [3:0] timer;

reg [64:0] _uart_in;


initial begin
    current_state = IDLE;
    timer = 0;
end


// Cuidar da mudança de estados
always @(posedge clk) begin
    if(reset == 1) begin
        current_state = IDLE;
    end

    else begin

        case(current_state) 

            IDLE: begin
                if(uart_data) begin
                    current_state <= IDLE;
                end
                else begin
                    current_state <= IDLE;
                end
            end

            ESCREVER_UART: begin
                // Escrever UART
            end

            RESET_PROCESSADOR: begin
                // manda sinal de reset pro processador
            end

            LER_RESULTADO_ALU: begin
                // lê o resultado da operação da ALU
            end

            LER_REGISTRADOR: begin
                // lê o valor do RD de uma operação/de um registrador específico
            end

            ESCREVER_REGISTRADOR: begin
                // escrever algum valor em um registrador específico
            end

            LER_MEMORIA: begin
                // lê o valor de uma posição de memória específica
            end

            ESCREVER_MEMORIA: begin
                // escreve algum valor de uma posição de memória específica
            end

            PULSO_CLOCK: begin

            end

            // recebe 32 bits da UART pra decodificar
            DECODE_UART: begin
                if(time == 4) begin
                    // decodificar os dados da UART aqui agr?

                    // alterar o current_state baseado nos dados decodificados?
                    current_state <= IDLE;
                    timer <= 0;
                end
                else begin
                    // concatena a entrada da uart com a anterior até completar 32 bits
                    _uart_in <= {_uart_in, uart_in};
                    timer <= timer + 1;
                end
            end
            
            default: begin
                current_state <= IDLE;
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

        PULSO_CLOCK: begin

        end

        DECODE_UART: begin
            // acho que aqui, nenhuma saída vai ser modificada, então n precisa colodar nada se pá
            // talvez só zerar as saídas pra garantir q nada vai bugar
        end
        
        default: begin
            // zerar só saida
        end
    endcase 
end

endmodule
