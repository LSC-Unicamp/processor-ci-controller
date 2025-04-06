`timescale 1ns/1ps

module fifo_tb;
    parameter DEPTH = 8;
    parameter WIDTH = 8;

    logic clk = 0;
    logic rst_n;
    logic wr_en_i;
    logic rd_en_i;
    logic [WIDTH-1:0] write_data_i;
    logic full_o;
    logic empty_o;
    logic [WIDTH-1:0] read_data_o;

    // Instância do DUT (Device Under Test)
    FIFO #(
        .DEPTH(DEPTH),
        .WIDTH(WIDTH)
    ) uut (
        .clk          (clk),
        .rst_n        (rst_n),
        .wr_en_i      (wr_en_i),
        .rd_en_i      (rd_en_i),
        .write_data_i (write_data_i),
        .full_o       (full_o),
        .empty_o      (empty_o),
        .read_data_o  (read_data_o)
    );

    // Geração de clock
    always #5 clk = ~clk;

    initial begin
        $dumpfile("build/fifo_tb.vcd");
        $dumpvars(0, fifo_tb);

        // Reset
        rst_n = 0;
        wr_en_i = 0;
        rd_en_i = 0;
        write_data_i = 0;
        #20 rst_n = 1;

        // Escrever até encher a FIFO
        for (int i = 0; i < DEPTH; i++) begin
            write_data_i = i;
            wr_en_i = 1;
            #10;
            wr_en_i = 0;
            #10;
        end
        
        // Verificar que a FIFO está cheia
        assert(full_o) else $error("Erro: FIFO deveria estar cheia!");
        
        // Tentar escrever com a FIFO cheia
        write_data_i = 42;
        wr_en_i = 1;
        #10;
        wr_en_i = 0;
        assert(full_o) else $error("Erro: FIFO deveria continuar cheia!");
        
        // Ler até esvaziar
        for (int i = 0; i < DEPTH; i++) begin
            rd_en_i = 1;
            #10;
            rd_en_i = 0;
            assert(read_data_o == i) else $error("Erro: Dados lidos incorretamente!");
            #10;
        end
        
        // Verificar que a FIFO está vazia
        assert(empty_o) else $error("Erro: FIFO deveria estar vazia!");
        
        // Teste de leitura com FIFO vazia
        rd_en_i = 1;
        #10;
        rd_en_i = 0;
        assert(empty_o) else $error("Erro: FIFO deveria continuar vazia!");
        
        // Finaliza simulação
        $display("Testbench finalizado com sucesso.");
        $finish;
    end
endmodule
