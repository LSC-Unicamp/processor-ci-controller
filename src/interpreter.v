module Interpreter #(
    parameter CLK_FREQ = 25000000,
    parameter PULSE_BITS = 12
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

    // outputs/sinais de controle para o controller
    output reg clk_enable,
    output wire [PULSE_BITS-1:0] num_pulses,
    output reg write_pulse
);


localparam IDLE                   = 4'b0000;
localparam ESCREVER_UART          = 4'b0001;
localparam RESET_PROCESSADOR      = 4'b0010;
localparam LER_RESULTADO_ALU      = 4'b0011;
localparam LER_REGISTRADOR        = 4'b0100;
localparam ESCREVER_REGISTRADOR   = 4'b0101;
localparam LER_MEMORIA            = 4'b0110;
localparam ESCREVER_MEMORIA       = 4'b0111;
localparam PARAR_CLOCK            = 4'b1000;
localparam INICIAR_CLOCK          = 4'b1001;
localparam PULSO_CLOCK            = 4'b1010;
localparam DECODE_UART            = 4'b1011;
// acelerar e desacelerar o clock da placa???

reg [3:0] current_state;
reg [3:0] timer;

reg [31:0] _uart_in; // [31:20] immediate para mandar pulsos de clock

assign num_pulses = _uart_in[31:20];

initial begin
    current_state = IDLE;
    timer = 0;
    clk_enable = 1;
    pulse_counter = 0;
end


// Cuidar da mudança de estados
always @(posedge clk) begin
    write_pulse <= 1'b0;
    if(reset == 1) begin
        current_state <= IDLE;
        clk_enable <= 1'b1; // habilita o clock por default
    end
    else begin
        case(current_state) 
            IDLE: begin
                if(uart_rx_empty == 1'b0) begin
                    current_state <= DECODE_UART;
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

            PARAR_CLOCK: begin
                // parar o clock da placa
                current_state <= IDLE;
            end

            INICIAR_CLOCK: begin
                // continuar o clock da placa
                current_state <= IDLE;
            end

            PULSO_CLOCK: begin
                // pulso de clock pra fazer o processador avançar um ciclo quando clock está parado
                current_state <= IDLE;
            end

            // recebe 32 bits da UART pra decodificar
            DECODE_UART: begin
                if(timer == 4'd4) begin
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



always @(*) begin
    write_pulse = 1'b0;
    clk_enable = 1'b0;
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

        PARAR_CLOCK: begin
            clk_enable <= 1'b0;
        end

        INICIAR_CLOCK: begin
            clk_enable <= 1'b1;
        end

        PULSO_CLOCK: begin
            write_pulse <= 1'b1;
        end

        DECODE_UART: begin
            // acho que aqui, nenhuma saída vai ser modificada, então n precisa colodar nada se pá
            // talvez só zerar as saídas pra garantir q nada vai bugar
        end
    endcase 
end

endmodule
