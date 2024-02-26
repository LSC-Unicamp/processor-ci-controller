module Controller #(
    parameter CLK_FREQ = 25000000
) (
    input wire clk,
    input wire reset,

    //saída de clock para o core, reset, endereço de memória, 
    //barramento de leitura e escrita entre outros.
    output wire clk_core,

    output wire reset_core,

    output wire memory_read_memory,
    output wire memory_write_memory,
    output wire [31:0] address_memory,
    output wire [31:0] write_data_memory,
    input wire [31:0]read_data_memory,

    //RISC-V FORMAL INTERFACE(RVFI)
    
    //INSTRUCTION METADATA (check: https://github.com/YosysHQ/riscv-formal/blob/main/cores/nerv/nerv.sv)
    input reg        rvfi_valid,
    input reg [63:0] rvfi_order,
    input reg [31:0] rvfi_insn,
    input reg        rvfi_trap,
    input reg        rvfi_halt,
    input reg        rvfi_intr,
    input reg [ 1:0] rvfi_mode,
    input reg [ 1:0] rvfi_ixl,
    
    //INTEGER REGISTER READ/WRITE
    input reg [ 4:0] rvfi_rs1_addr,
    input reg [ 4:0] rvfi_rs2_addr,
    input reg [31:0] rvfi_rs1_rdata,
    input reg [31:0] rvfi_rs2_rdata,
    input reg [ 4:0] rvfi_rd_addr,
    input reg [31:0] rvfi_rd_wdata,

    //PROGRAM COUNTER
    input reg [31:0] rvfi_pc_rdata,
    input reg [31:0] rvfi_pc_wdata,

    //MEMORY ACCESS
    input [31:0] rvfi_mem_addr,
    input [ 3:0] rvfi_mem_rmask,
    input [ 3:0] rvfi_mem_wmask,
    input [31:0] rvfi_mem_rdata,
    input [31:0] rvfi_mem_wd
);
    
endmodule
