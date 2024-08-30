# ProcessorCI Controler

Processor CI Controller is a hardware module that acts as a wrapper around the processor core, enabling control over it, monitoring the memory bus, and managing signals such as clock, reset, and halt.

The key idea is to be able to control distinct kind of processors without needing to intercept internal signals as previous works do. This way, the controller can be used with any processor that follows the RISC-V ISA, without needing to modify the processor's RTL.

## Project Modules

The controller is divided into various modules, each responsible for performing a specific function. Among the existing modules, the main ones are:

![Controller diagram](img/controlador-riscv.svg)

## Interpreter

The interpreter is responsible for receiving instructions sent by the test software and issuing commands to other modules. These commands can involve tasks such as reading and writing to memory, providing N clock cycles to the processor, etc.

## Communication Module

The communication module acts as the bridge between the host machine running the test software and the controller. It is responsible for implementing the protocol to be used, which could be UART, SPI, or PCIe.

## Clock Controller

The clock controller manages the clock signal provided to the processor. It has the capability to supply a specific number of pulses and/or divide the clock frequency.

## Memory Controller

The memory controller provides an access interface to the memory for both the controller and the processor, managing the priority with which each can interact with the memory.

## Global project

This project is part of a larger project, and the page for the larger project can be accessed at: [processorci.ic.unicamp.br](https://processorci.ic.unicamp.br).

## Licenses

This project is governed by the [CERN-OHL-P license](https://github.com/LSC-Unicamp/processor-ci-controller/blob/main/LICENSE), and its documentation is under the [CC BY-SA 4.0 license](https://github.com/LSC-Unicamp/processor-ci-controller/blob/main/docs/LICENSE.md).