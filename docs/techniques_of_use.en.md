# Utilization Techniques

Based on the existing instructions, various techniques can be used for test execution, including: manual execution, execution until a breakpoint, and execution by pages.

### Manual Execution

Manual execution is performed by manually executing the workflow after loading the tests into memory. This includes tasks such as resetting the processor and manually generating N clock pulses. The pseudo-code below illustrates this approach:

```pseudo
Get ID and check module functionality;

Write N positions from the accumulator;

Reset Core;

Send N CLK pulses;

Read memory position N.

# If more M CLK pulses are needed

Send N CLK pulses
```

### Execution Until Breakpoint (UNTIL)

The infrastructure supports automatic test execution using the breakpoint technique. With this technique, after loading the tests into memory, you simply set a breakpoint and a timeout in clock cycles. With these parameters defined, you can send the instruction to execute until the breakpoint and wait for completion. The pseudo-code for this process is shown below:

```pseudo
Get ID and check module functionality;

Write N positions from the accumulator;

# Load breakpoint address

Define address N as the end of execution;

Set timeout;

Execute until breakpoint.
```

### Execution by Pages

For executing multiple tests in sequence, a paging system can be used. In this system, tests are stored in fixed-size blocks, by default 256 positions, and the controller navigates through these blocks by controlling the most significant bits of the address. The operation is similar to execution until a breakpoint, but the process is repeated until all pages have been executed. The pseudo-code below illustrates this process:

```pseudo
Get ID and check module functionality;

Write N positions from the accumulator;

# Load breakpoint address - the address must be less than or equal to the maximum page address, by default 0xFF

Define address N as the end of execution;

Set timeout;

Execute tests in memory.
```

# Data Flow

Data can be sent and read from memory in two ways: atomically (word by word) or in bulk, sending N words at once.

### Atomic Loading

Atomic loading is performed by reading and writing data word by word. This method can be executed using the following instructions: "Write to memory position N", "Write N to accumulator position", "Read memory position N", and "Read accumulator position". When using immediate value instructions, you need to send the instruction M times to read or write M words. When using the accumulator, you need to set the accumulator pointer M times and execute the read and write instructions M times. Thus, using these instructions is more suitable for small modifications, such as reading a result or reading/writing one or two words in memory.

### Bulk Loading

Bulk loading allows reading or writing M words using only one or two instructions. With this method, you only need to load the base address into the accumulator and use bulk read instructions to read or write M words. The bulk operation instructions are: "Read N positions from the accumulator" and "Write N positions from the accumulator".