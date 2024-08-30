# Instruções

Para a comunicação entre o hardware e o software, a interface é realizada por meio de um protocolo baseado em instruções (comandos).

### Formato das Instruções

As instruções são compostas por 32 bits, onde os 8 bits menos significativos representam o opcode e os 24 bits mais significativos são utilizados para o campo imediato, conforme mostrado na Tabela 1. Para instruções que não possuem um campo imediato, esses bits são preenchidos com zeros.

| 31:8      | 7:0   |
| --------- | ----- |
| Imediato  | Opcode|

*Tabela 1: Formato da Instrução*

### Opcodes

A Tabela 2 apresenta uma lista de todas as instruções disponíveis, incluindo seus respectivos opcodes em binário, ASCII e hexadecimal. A especificação detalhada de cada instrução pode ser encontrada na Seção 3.

| Descrição | Opcode  | Opcode ASCII | Opcode Hex | 2º Pacote |
|-----------|---------|--------------|------------|-----------|
| Enviar N pulsos de CLK | 01000011 | C | 0x43 |             |
| Parar CLK do Core | 01010011 | S | 0x53 |             |
| Retomar CLK do Core | 01110010 | r | 0x72 |             |
| Resetar Core | 01010010 | R | 0x52 |             |
| Escrever na posição N de memória | 01010111 | W | 0x57 | Y           |
| Ler a posição N de memória | 01001100 | L | 0x4C |             |
| Carregar bits mais significativos no Acumulador | 01010101 | U | 0x55 |             |
| Carregar bits menos significativos no Acumulador | 01101100 | l | 0x6C |             |
| Somar N ao Acumulador | 01000001 | A | 0x41 |             |
| Escrever Acumulador na posição N | 01110111 | w | 0x77 |             |
| Escrever N na posição do Acumulador | 01110011 | s | 0x73 |             |
| Ler a posição do Acumulador | 01110010 | r | 0x72 |             |
| Definir timeout | 01010100 | T | 0x54 |             |
| Definir tamanho da página de memória | 01010000 | P | 0x50 |             |
| Executar testes de memória | 01000101 | E | 0x45 |             |
| Obter o ID do módulo e verificar funcionamento | 01110000 | p | 0x70 |             |
| Definir endereço de término N | 01000100 | D | 0x44 |             |
| Definir valor do Acumulador como endereço de término | 01100100 | d | 0x64 |             |
| Escrever N posições a partir do Acumulador | 01100101 | e | 0x65 |             |
| Ler N posições a partir do Acumulador | 01100010 | b | 0x62 |             |
| Obter valor do Acumulador | 01100001 | a | 0x61 |             |
| Alterar prioridade de acesso à memória para o Core | 01001111 | O | 0x4F |             |
| Executar até ponto de parada | 01110101 | u | 0x75 |             |

*Tabela 2: Lista de Comandos Suportados pelo Protocolo*

## Implementação

### Funcionamento

O protocolo de interface opera sobre um protocolo físico responsável pela transmissão de dados entre a FPGA e a máquina host. Em configurações de comunicação Master-Slave, como no protocolo SPI, uma linha de sinal chamada CAL (Callback) é usada. Essa linha informa à máquina host que o controlador possui informações prontas ou está preparado para executar um novo comando. Para protocolos bidirecionais, como o UART, os dados são enviados pela FPGA sem sinais de callback.

As tabelas abaixo mostram os regimes de comunicação entre a FPGA e a máquina host ao longo do tempo, considerando os três casos possíveis: envio de instrução, envio de instrução e dados, e envio de instruções com recebimento de dados. Em cada caso, as ações ocorrem sequencialmente. Por exemplo, no caso 2, os dados são enviados apenas após o envio da instrução.

**Caso 1: Apenas Envio**  
| Master | Instrução |
|--------|-----------|
| Slave  |           |

**Caso 2: Envio com Dados**  
| Master | Instrução | Dados |
|--------|-----------|-------|
| Slave  |           |       |

**Caso 3: Envio e Recebimento**  
| Master | Instrução |       |
|--------|-----------|-------|
| Slave  |           | Dados |



Aqui está o texto traduzido para markdown:

---

## Especificação das instruções

1. **Enviar N pulsos de CLK (Opcode: 01000011, Hex: 0x43):**  
   Envia N pulsos de clock para o processador, permitindo o avanço de N ciclos de clock. Após o término dos N ciclos, o clock do processador é interrompido.

2. **Parar o CLK do Core (Opcode: 01010011, Hex: 0x53):**  
   Interrompe o clock do núcleo do processador, pausando a execução.

3. **Retomar o CLK do Core (Opcode: 01110010, Hex: 0x72):**  
   Retoma o clock do núcleo do processador, continuando a execução a partir do ponto de parada.

4. **Resetar o Core (Opcode: 01010010, Hex: 0x52):**  
   Realiza o reset do processador, utilizando um valor constante de ciclos de clock denominado `RESET_CLK_CYCLES`, que por padrão é 20. Ou seja, o processador é resetado por 20 ciclos de clock, ou pelo valor configurado em `RESET_CLK_CYCLES`.

5. **Escrever na posição N de memória (Opcode: 01010111, Hex: 0x57):**  
   Escreve um valor na posição N da memória. A operação necessita do envio de dois pacotes de dados de 32 bits, com o primeiro contendo o opcode e o endereço, e o segundo contendo os dados a serem escritos.

6. **Ler a posição N de memória (Opcode: 01001100, Hex: 0x4C):**  
   Lê o valor armazenado na posição N da memória e retorna o valor lido.

7. **Carregar bits mais significativos no Acumulador (Opcode: 01010101, Hex: 0x55):**  
   Carrega os 24 bits mais significativos (superiores) do acumulador.

8. **Carregar bits menos significativos no acumulador (Opcode: 01101100, Hex: 0x6C):**  
   Carrega os 8 bits menos significativos (inferiores) do acumulador.

9. **Somar N ao acumulador (Opcode: 01000001, Hex: 0x41):**  
   Adiciona o valor N ao conteúdo atual do acumulador. Esta operação é sinalizada utilizando complemento de 2.

10. **Escrever Acumulador na posição N (Opcode: 01110111, Hex: 0x77):**  
    Escreve o valor contido no acumulador na posição N da memória.

11. **Escrever N na posição do acumulador (Opcode: 01110011, Hex: 0x73):**  
    Escreve o valor N na posição de memória apontada pelo acumulador.

12. **Ler a posição do acumulador (Opcode: 01110010, Hex: 0x72):**  
    Lê o valor da memória na posição apontada pelo acumulador.

13. **Setar timeout (Opcode: 01010100, Hex: 0x54):**  
    Define um valor de tempo limite para a execução do processador, especificado em ciclos de clock.

14. **Setar tamanho da página de memória (Opcode: 01010000, Hex: 0x50):**  
    Define o tamanho da página de memória utilizada para os testes, configurando a quantidade de memória a ser usada para cada teste.

15. **Executar testes em memória (Opcode: 01000101, Hex: 0x45):**  
    Inicia a execução de um conjunto de testes na memória especificada. Esses testes são executados de forma paginada, com a possibilidade de executar um lote de testes de forma automatizada. A infraestrutura executa um teste até um determinado ponto de parada ou até o timeout. Após o término da execução do teste, o processador é "resetado" e a página de memória é alterada, repetindo todo o processo. Após o término da execução, é enviada uma mensagem de confirmação (`0x676F6F64` - "good"). O número de páginas a serem utilizadas é passado como o valor imediato da instrução.

16. **Obter o ID e verificar funcionamento do módulo (Opcode: 01110000, Hex: 0x70):**  
    Recupera o ID do módulo e verifica se ele está funcionando corretamente. O ID é um número de 32 bits, que contém informações como a FPGA em utilização, a identificação da infraestrutura, entre outros.

17. **Definir endereço N de término de execução (Opcode: 01000100, Hex: 0x44):**  
    Define o endereço N como ponto de término para a execução (*breakpoint*).

18. **Definir o valor do Acumulador como endereço de término (Opcode: 01100100, Hex: 0x64):**  
    Utiliza o valor atual do acumulador para definir o endereço de término de execução (*breakpoint*).

19. **Escrever N posições a partir do acumulador (Opcode: 01100101, Hex: 0x65):**  
    Escreve valores em N posições consecutivas de memória a partir do endereço apontado pelo acumulador. Essa instrução recebe N + 1 palavras[^1] de 32 bits, com a primeira sendo a instrução em si e as próximas N palavras sendo as informações a serem escritas na memória.

20. **Ler N posições a partir do acumulador (Opcode: 01100010, Hex: 0x62):**  
    Lê N posições consecutivas de memória a partir do endereço apontado pelo acumulador. Essa instrução retorna N palavras, com essas N palavras sendo os dados da memória.

21. **Obter o acumulador (Opcode: 01100001, Hex: 0x61):**  
    Recupera o valor atual armazenado no acumulador.

22. **Alterar prioridade de acesso à memória para o Core (Opcode: 01001111, Hex: 0x4F):**  
    Modifica a prioridade de acesso à memória, permitindo que o processador tenha acesso prioritário à memória.

23. **Executar até ponto de parada (Opcode: 01110101, Hex: 0x75):**  
    Permite a execução do processador até que um ponto predefinido (*breakpoint*) seja alcançado. Ao executar esta instrução, o processador é resetado, recebe prioridade de acesso à memória e opera até alcançar o ponto de parada ou atingir o timeout de execução. Após o término da execução, é enviada de volta uma mensagem de confirmação (`0x6C75636B` - "luck") e uma informação indicando se o término ocorreu por timeout ou fim da execução, além da quantidade de ciclos gastos pelo processador para a execução. Essa informação é enviada no formato: 24 bits mais significativos indicam os ciclos gastos, e os 8 bits menos significativos indicam se ocorreu timeout.

[^1]: Para fins de esclarecimento, o termo "palavra" se refere a um bloco de informações de 32 bits ou 4 bytes. 

---