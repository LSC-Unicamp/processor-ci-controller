module Controller #(
    parameter CLK_FREQ = 25000000
) (
    input wire clk,
    input wire reset,

    //RISC-V FORMAL INTERFACE(RVFI)
    
    //INSTRUCTION METADATA (check: https://github.com/YosysHQ/riscv-formal/blob/main/cores/nerv/nerv.sv)
    output reg        rvfi_valid,
	output reg [63:0] rvfi_order,
	output reg [31:0] rvfi_insn,
	output reg        rvfi_trap,
	output reg        rvfi_halt,
	output reg        rvfi_intr,
	output reg [ 1:0] rvfi_mode,
	output reg [ 1:0] rvfi_ixl,
    
    //INTEGER REGISTER READ/WRITE
    output reg [ 4:0] rvfi_rs1_addr,
	output reg [ 4:0] rvfi_rs2_addr,
	output reg [31:0] rvfi_rs1_rdata,
	output reg [31:0] rvfi_rs2_rdata,
    output reg [ 4:0] rvfi_rd_addr,
	output reg [31:0] rvfi_rd_wdata,

    //PROGRAM COUNTER
    output reg [31:0] rvfi_pc_rdata,
	output reg [31:0] rvfi_pc_wdata,

    //MEMORY ACCESS
    output [31:0] rvfi_mem_addr,
    output [ 3:0] rvfi_mem_rmask,
    output [ 3:0] rvfi_mem_wmask,
    output [31:0] rvfi_mem_rdata,
    output [31:0] rvfi_mem_wd
);
    
endmodule
