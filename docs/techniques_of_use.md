# Técnicas de Utilização

Com base nas instruções existentes, diversas técnicas podem ser utilizadas para a execução dos testes, incluindo: execução manual, execução até um ponto de parada e execução por páginas.

### Execução Manual

A execução manual é realizada através da execução manual do fluxo após o carregamento dos testes na memória. Isso inclui tarefas como "resetar" o processador e gerar manualmente N pulsos de clock. O pseudo código abaixo ilustra essa abordagem:

```pseudo
Obter o ID e verificar o funcionamento do módulo;

Escrever N posições a partir do acumulador;

Resetar o Core;

Enviar N pulsos de CLK;

Ler a posição N de memória.

# Se necessário mais M pulsos de CLK

Enviar N pulsos de CLK
```

### Execução Até Ponto de Parada (UNTIL)

A infraestrutura permite a execução automática de um teste utilizando a técnica de ponto de parada. Com essa técnica, após carregar os testes na memória, basta definir um ponto de parada e um timeout em ciclos de clock. Com esses parâmetros definidos, é possível enviar a instrução para executar até o ponto de parada e aguardar a conclusão. O pseudo código para esse processo é apresentado abaixo:

```pseudo
Obter o ID e verificar o funcionamento do módulo;

Escrever N posições a partir do acumulador;

# Carregar endereço do ponto de parada

Definir endereço N de término da execução;

Setar timeout;

Executar até o ponto de parada.
```

### Execução por Páginas

Para a execução de vários testes em sequência, é possível utilizar um sistema baseado em paginação. Nesse sistema, os testes são armazenados em blocos de tamanho fixo, por padrão 256 posições, e o controlador navega por esses blocos controlando os bits mais significativos do endereço. O funcionamento é semelhante ao da execução até um ponto de parada, mas o processo é repetido até a execução de todas as páginas. O pseudo código a seguir ilustra esse processo:

```pseudo
Obter o ID e verificar o funcionamento do módulo;

Escrever N posições a partir do acumulador;

# Carregar endereço do ponto de parada - o endereço precisa ser menor ou igual ao endereço máximo da página, por padrão 0xFF

Definir endereço N de término da execução;

Setar timeout;

Executar testes em memória.
```

# Fluxo de Dados

É possível enviar e ler dados para a memória de duas formas: atômica (palavra por palavra) ou em lote, enviando N palavras de uma vez.

### Carregamento Atômico

O carregamento atômico é realizado lendo e escrevendo dados palavra por palavra. Esse método pode ser executado utilizando as seguintes instruções: "Escrever na posição N de memória", "Escrever N na posição do acumulador", "Ler a posição N de memória" e "Ler a posição do acumulador". Ao utilizar instruções baseadas em valores imediatos, é necessário enviar a instrução M vezes para ler ou escrever M palavras. Quando se utiliza o acumulador, é necessário definir o ponteiro do acumulador M vezes e executar as instruções de leitura e escrita M vezes. Dessa forma, o uso dessas instruções é mais adequado para pequenas modificações, como ler um resultado ou ler/escrever uma ou duas palavras na memória.

### Carregamento em Lote

O carregamento em lote permite ler ou escrever M palavras utilizando apenas uma ou duas instruções. Com esse método, é necessário apenas carregar o endereço base no acumulador e utilizar as instruções de leitura em lote para ler ou escrever M palavras. As instruções de operação em lote são: "Ler N posições a partir do acumulador" e "Escrever N posições a partir do acumulador".