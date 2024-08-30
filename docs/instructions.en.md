# Instructions

For communication between hardware and software, the interface is carried out through an instruction-based protocol (commands).

### Instruction Format

The instructions are composed of 32 bits, where the 8 least significant bits represent the opcode, and the 24 most significant bits are used for the immediate field, as shown in Table 1. For instructions that do not have an immediate field, these bits are filled with zeros.

| 31:8      | 7:0   |
| --------- | ----- |
| Immediate | Opcode|

*Table 1: Instruction Format*

### Opcodes

Table 2 shows a list of all available instructions, including their respective opcodes in binary, ASCII, and hexadecimal. The detailed specification of each instruction can be found in Section 3.

| Description | Opcode  | ASCII Opcode | Hex Opcode | 2nd Packet |
|-------------|---------|--------------|------------|------------|
| Send N CLK pulses | 01000011 | C | 0x43 |            |
| Stop Core CLK | 01010011 | S | 0x53 |            |
| Resume Core CLK | 01110010 | r | 0x72 |            |
| Reset Core | 01010010 | R | 0x52 |            |
| Write to memory position N | 01010111 | W | 0x57 | Y          |
| Read memory position N | 01001100 | L | 0x4C |            |
| Load most significant bits into Accumulator | 01010101 | U | 0x55 |            |
| Load least significant bits into Accumulator | 01101100 | l | 0x6C |            |
| Add N to Accumulator | 01000001 | A | 0x41 |            |
| Write Accumulator to position N | 01110111 | w | 0x77 |            |
| Write N to Accumulator position | 01110011 | s | 0x73 |            |
| Read Accumulator position | 01110010 | r | 0x72 |            |
| Set timeout | 01010100 | T | 0x54 |            |
| Set memory page size | 01010000 | P | 0x50 |            |
| Execute memory tests | 01000101 | E | 0x45 |            |
| Get module ID and check functionality | 01110000 | p | 0x70 |            |
| Set execution end address N | 01000100 | D | 0x44 |            |
| Set Accumulator value as end address | 01100100 | d | 0x64 |            |
| Write N positions from Accumulator | 01100101 | e | 0x65 |            |
| Read N positions from Accumulator | 01100010 | b | 0x62 |            |
| Get Accumulator | 01100001 | a | 0x61 |            |
| Change memory access priority to Core | 01001111 | O | 0x4F |            |
| Execute until breakpoint | 01110101 | u | 0x75 |            |

*Table 2: List of Commands Supported by the Protocol*

## Implementation

### Operation

The interface protocol operates over a physical protocol responsible for data transmission between the FPGA and the host machine. In Master-Slave communication settings, such as the SPI protocol, a signal line called CAL (Callback) is used. This line informs the host machine that the controller has information ready or is prepared to execute a new command. For bidirectional protocols, like UART, data is sent by the FPGA without callback signals.

The tables below show the communication regimes between the FPGA and the host machine over time, considering the three possible cases: sending instruction only, sending instruction and data, and sending instructions with data reception. In each case, actions occur sequentially. For example, in case 2, the data is sent only after sending the instruction.  

**Case 1: Sending Only**  
| Master | Instruction |
|--------|-------------|
| Slave  |             |

**Case 2: Sending with Data**  
| Master | Instruction | Data |
|--------|-------------|------|
| Slave  |             |      |

**Case 3: Sending and Receiving**  
| Master | Instruction |      |
|--------|-------------|------|
| Slave  |             | Data |

Here is the text translated to English:

---

## Instruction Specification


1. **Send N CLK pulses (Opcode: 01000011, Hex: 0x43):**  
   Sends N clock pulses to the processor, allowing the advancement of N clock cycles. After the N cycles are completed, the processor's clock is halted.

2. **Stop Core CLK (Opcode: 01010011, Hex: 0x53):**  
   Stops the processor core clock, pausing execution.

3. **Resume Core CLK (Opcode: 01110010, Hex: 0x72):**  
   Resumes the processor core clock, continuing execution from the halt point.

4. **Reset Core (Opcode: 01010010, Hex: 0x52):**  
   Resets the processor using a constant clock cycle value called `RESET_CLK_CYCLES`, which defaults to 20. In other words, the processor is reset for 20 clock cycles or for the value set in `RESET_CLK_CYCLES`.

5. **Write to memory position N (Opcode: 01010111, Hex: 0x57):**  
   Writes a value to memory position N. This operation requires sending two 32-bit data packets, with the first containing the opcode and the address, and the second containing the data to be written.

6. **Read memory position N (Opcode: 01001100, Hex: 0x4C):**  
   Reads the value stored in memory position N and returns the read value.

7. **Load most significant bits to Accumulator (Opcode: 01010101, Hex: 0x55):**  
   Loads the 24 most significant (upper) bits of the accumulator.

8. **Load least significant bits to Accumulator (Opcode: 01101100, Hex: 0x6C):**  
   Loads the 8 least significant (lower) bits of the accumulator.

9. **Add N to Accumulator (Opcode: 01000001, Hex: 0x41):**  
   Adds the value N to the current content of the accumulator. This operation uses two’s complement signaling.

10. **Write Accumulator to position N (Opcode: 01110111, Hex: 0x77):**  
    Writes the value stored in the accumulator to memory position N.

11. **Write N to the Accumulator position (Opcode: 01110011, Hex: 0x73):**  
    Writes the value N to the memory position pointed to by the accumulator.

12. **Read Accumulator position (Opcode: 01110010, Hex: 0x72):**  
    Reads the memory value at the position pointed to by the accumulator.

13. **Set timeout (Opcode: 01010100, Hex: 0x54):**  
    Sets a timeout value for processor execution, specified in clock cycles.

14. **Set memory page size (Opcode: 01010000, Hex: 0x50):**  
    Sets the memory page size used for tests, configuring the amount of memory to be used for each test.

15. **Execute tests in memory (Opcode: 01000101, Hex: 0x45):**  
    Starts executing a set of tests in the specified memory. These tests are executed in a paginated manner, allowing for automated batch testing. The infrastructure runs a test until a specific breakpoint or timeout is reached. After completing the test execution, the processor is reset, and the memory page is changed, repeating the entire process. After execution ends, a confirmation message (`0x676F6F64` - "good") is sent. The number of pages to be used is passed as the immediate value of the instruction.

16. **Get ID and check module functionality (Opcode: 01110000, Hex: 0x70):**  
    Retrieves the module ID and checks if it is functioning correctly. The ID is a 32-bit number that contains information such as the FPGA in use, the infrastructure identification, and more.

17. **Set end of execution address N (Opcode: 01000100, Hex: 0x44):**  
    Sets address N as the breakpoint for execution.

18. **Set Accumulator value as end of execution address (Opcode: 01100100, Hex: 0x64):**  
    Uses the current accumulator value to set the breakpoint address for execution.

19. **Write N positions starting from the Accumulator (Opcode: 01100101, Hex: 0x65):**  
    Writes values to N consecutive memory positions starting from the address pointed to by the accumulator. This instruction receives N + 1 words[^1] of 32 bits, with the first being the instruction itself and the next N words being the data to be written to memory.

20. **Read N positions starting from the Accumulator (Opcode: 01100010, Hex: 0x62):**  
    Reads N consecutive memory positions starting from the address pointed to by the accumulator. This instruction returns N words, with these N words being the memory data.

21. **Get Accumulator (Opcode: 01100001, Hex: 0x61):**  
    Retrieves the current value stored in the accumulator.

22. **Change memory access priority to Core (Opcode: 01001111, Hex: 0x4F):**  
    Modifies the memory access priority, allowing the processor to have priority access to the memory.

23. **Execute until breakpoint (Opcode: 01110101, Hex: 0x75):**  
    Allows the processor to execute until a predefined breakpoint is reached. When this instruction is executed, the processor is reset, given priority access to memory, and operates until the breakpoint is reached or execution timeout occurs. After execution ends, a confirmation message (`0x6C75636B` - "luck") is sent back, along with information indicating whether the termination was due to a timeout or end of execution, as well as the number of cycles taken by the processor to execute. This information is sent in the format: the 24 most significant bits indicate the cycles taken, and the 8 least significant bits indicate whether a timeout occurred.

[^1]: For clarification, the term "word" refers to a 32-bit block of information or 4 bytes.
