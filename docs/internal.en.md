# Internal Information

## Communication Methods

It is possible to use the interface with various communication protocols, with those having some level of support or in the implementation phase listed in Table \ref{tab:communication_methods}.

| Name  | Speed      |
|-------|------------|
| UART  | 115200 bps  |
| SPI   | 10 MHz      |
| PCIe  | 2.5 GB/s    |
| USB   |            |

*Table 1: Communication Methods*  
*Source: Table \ref{tab:communication_methods}*

## Internal Registers

The infrastructure includes several specialized and multifunctional internal registers that can be used for memory interaction and test execution. These registers are:

1. **Accumulator (ACC)**: The accumulator is a 32-bit general-purpose register that can be used as a memory pointer, to write to memory, and to be set as a *breakpoint*.  
   *Note:* The term *breakpoint* refers to a stopping point where the program will be interrupted when this point is reached.

2. **Timeout**: The timeout register is a 32-bit register used to define the maximum execution time of the processor for a given test, measured in clock cycles.

3. **NumOffPages**: The number of pages register is a 24-bit register used for running tests involving memory paging. It is responsible for defining the number of test pages available for execution.

4. **EndPosition**: The EndPosition register is a 32-bit register used as a *breakpoint* for test execution. Once the processor accesses this address, the infrastructure identifies that the execution has been completed and can halt the processor.
