module ClkDivider_tb;
    parameter COUNTER_BITS = 32;
    parameter PULSE_CONTROL_BITS = 32;
    
    logic clk;
    logic rst_n;
    logic write_pulse;
    logic option;
    logic out_enable;
    logic [COUNTER_BITS-1:0] divider;
    logic [PULSE_CONTROL_BITS-1:0] pulse;
    logic clk_o;
    
    ClkDivider #(
        .COUNTER_BITS       (COUNTER_BITS),
        .PULSE_CONTROL_BITS (PULSE_CONTROL_BITS)
    ) uut (
        .clk         (clk),
        .rst_n       (rst_n),
        .write_pulse (write_pulse),
        .option      (option),
        .out_enable  (out_enable),
        .divider     (divider),
        .pulse       (pulse),
        .clk_o       (clk_o)
    );
    
    // Clock generation
    always #5 clk = ~clk;
    
    initial begin
        // Inicialização dos sinais
        clk         = 0;
        rst_n       = 0;
        write_pulse = 0;
        option      = 0;
        out_enable  = 0;
        divider     = 10;
        pulse       = 5;
        
        // Reset ativo
        #10 rst_n = 1;
        assert(clk_o == 0) else $fatal(1, "Erro: clk_o deveria estar em 0 após reset");
        
        // Teste de divisão de clock no modo automático
        #20 out_enable = 1;
        option         = 1;
        
        #50;
        assert(clk_o == 1 || clk_o == 0) else $fatal(1, "Erro: clk_o inválido no modo automático");
        
        #200;
        
        // Teste de geração de pulsos
        option          = 0;
        write_pulse     = 1;
        pulse           = 50;
        #10 write_pulse = 0;
        
        #50;
        assert(clk_o == clk) else $fatal(1, "Erro: clk_o deveria seguir clk no modo pulse quando pulse_counter > 0");
        
        #100;
        
        // Teste de reset
        rst_n     = 0;
        #20 rst_n = 1;
        
        assert(clk_o == 0) else $fatal(1, "Erro: clk_o deveria estar em 0 após reset");
        
        #200;
        
        $finish;
    end
    
    initial begin
        $dumpfile("build/ClkDivider_tb.vcd");
        $dumpvars(0, ClkDivider_tb);
    end
endmodule
