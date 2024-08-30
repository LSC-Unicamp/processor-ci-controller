# ProcessorCI Controler

O Controlador Processor CI é um módulo de hardware que atua como um invólucro em torno do núcleo do processador, permitindo controlá-lo, monitorar o barramento de memória e gerenciar sinais como clock, reset e halt.

A ideia principal é ser capaz de controlar diferentes tipos de processadores sem precisar interceptar sinais internos, como trabalhos anteriores faziam. Dessa forma, o controlador pode ser usado com qualquer processador que siga a ISA RISC-V, sem a necessidade de modificar o RTL do processador.

## Módulos do Projeto

O controlador é dividido em vários módulos, cada um responsável por executar uma função específica. Entre os módulos existentes, os principais são:

![Diagrama do controlador](img/controlador-riscv.svg)

## Interpretador

O interpretador é responsável por receber instruções enviadas pelo software de teste e emitir comandos para outros módulos. Esses comandos podem envolver tarefas como leitura e escrita na memória, fornecimento de N ciclos de clock para o processador, etc.

## Módulo de Comunicação

O módulo de comunicação atua como a ponte entre a máquina host que executa o software de teste e o controlador. Ele é responsável por implementar o protocolo a ser usado, que pode ser UART, SPI ou PCIe.

## Controlador de Clock

O controlador de clock gerencia o sinal de clock fornecido ao processador. Ele tem a capacidade de fornecer um número específico de pulsos e/ou dividir a frequência do clock.

## Controlador de Memória

O controlador de memória fornece uma interface de acesso à memória tanto para o controlador quanto para o processador, gerenciando a prioridade com que cada um pode interagir com a memória.

## Projeto Global

Este projeto faz parte de um projeto maior, e a página do projeto maior pode ser acessada em: [processorci.ic.unicamp.br](https://processorci.ic.unicamp.br).

## Licenças

Este projeto está regido sob a [licença CERN-OHL-P](https://github.com/LSC-Unicamp/processor-ci-controller/blob/main/LICENSE), e sua documentação está sob a [licença CC BY-SA 4.0](https://github.com/LSC-Unicamp/processor-ci-controller/blob/main/docs/LICENSE.md).