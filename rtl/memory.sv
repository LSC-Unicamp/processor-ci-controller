module Memory #(
    parameter MEMORY_FILE = "",
    parameter MEMORY_SIZE = 4096
)(
    input  logic        clk,

    input  logic        cyc_i,      // Indica uma transação ativa
    input  logic        stb_i,      // Indica uma solicitação ativa
    input  logic        we_i,       // 1 = Write, 0 = Read

    input  logic [31:0] addr_i,     // Endereço
    input  logic [31:0] data_i,     // Dados de entrada (para escrita)
    output logic [31:0] data_o,     // Dados de saída (para leitura)

    output logic        ack_o       // Confirmação da transação (agora assíncrona)
);

    localparam BIT_INDEX = $clog2(MEMORY_SIZE) - 1'b1;
    logic [31:0] memory [(MEMORY_SIZE/4)-1:0];

    // Inicialização da memória com arquivo, se fornecido
    initial begin
        if (MEMORY_FILE != "") begin
            $readmemh(MEMORY_FILE, memory);
        end
    end

    // Leitura assíncrona
    assign data_o = (cyc_i && stb_i && !we_i) ? memory[addr_i[BIT_INDEX:2]] : 32'd0;

    // Resposta assíncrona de ACK (igual ao antigo `response`)
    assign ack_o = cyc_i && stb_i;  

    // Escrita síncrona
    always_ff @(posedge clk) begin : MEMORY_SYNC_WRITE
        if (cyc_i && stb_i && we_i) begin
            memory[addr_i[BIT_INDEX:2]] <= data_i;
        end
    end

endmodule
