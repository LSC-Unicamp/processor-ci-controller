# Informações Internas

## Formas de Comunicação

É possível utilizar a interface com diversos protocolos de comunicação, sendo que os protocolos com algum suporte ou em fase de implementação são listados na Tabela \ref{tab:formas_comunicacao}.

| Nome  | Velocidade   |
|-------|--------------|
| UART  | 115200 bps    |
| SPI   | 10 MHz        |
| PCIe  | 2.5 GB/s      |
| USB   |              |

*Tabela 1: Formas de Comunicação*  
*Fonte: Tabela \ref{tab:formas_comunicacao}*

## Registradores Internos

A infraestrutura possui alguns registradores internos especializados e multifuncionais que podem ser utilizados para interação com a memória e execução dos testes. Esses registradores são:

1. **Acumulador (ACC)**: O acumulador é um registrador de 32 bits de propósito geral que pode ser utilizado como ponteiro de memória, ser escrito na memória e ser definido como *breakpoint*.  
   *Nota:* O termo *breakpoint* refere-se a um ponto de parada onde o programa será interrompido quando esse ponto for atingido.

2. **Timeout**: O registrador de timeout é um registrador de 32 bits utilizado para definir o tempo máximo de execução do processador em um determinado teste, medido em ciclos de clock.

3. **NumOffPages**: O registrador de número de páginas é um registrador de 24 bits utilizado para a execução de testes que envolvem paginação de memória. Ele é responsável por definir a quantidade de páginas de testes disponíveis para execução.

4. **EndPosition**: O registrador EndPosition é um registrador de 32 bits utilizado como *breakpoint* para a execução dos testes. A partir do acesso a esse endereço pelo processador, a infraestrutura identifica que a execução foi concluída e pode interromper o processador.
