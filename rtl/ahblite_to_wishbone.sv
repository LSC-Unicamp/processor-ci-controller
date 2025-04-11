module ahb_to_wishbone #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input logic                   HCLK,
    input logic                   HRESETn,

    // AHB Interface
    input  logic [ADDR_WIDTH-1:0] HADDR,
    input  logic [1:0]            HTRANS,
    input  logic                  HWRITE,
    input  logic [2:0]            HSIZE,
    input  logic [2:0]            HBURST,
    input  logic [3:0]            HPROT,
    input  logic                  HLOCK,
    input  logic [DATA_WIDTH-1:0] HWDATA,
    input  logic                  HREADY,
    output logic [DATA_WIDTH-1:0] HRDATA,
    output logic                  HREADYOUT,
    output logic [1:0]            HRESP,

    // Wishbone Interface
    output logic                  wb_cyc,
    output logic                  wb_stb,
    output logic                  wb_we,
    output logic [ADDR_WIDTH-1:0] wb_adr,
    output logic [DATA_WIDTH-1:0] wb_dat_w,
    input  logic [DATA_WIDTH-1:0] wb_dat_r,
    input  logic                  wb_ack
);

    // Internal state
    logic ahb_active;
    logic [2:0] burst_cnt;
    logic burst_en;
    logic [ADDR_WIDTH-1:0] base_addr;
    logic [2:0] beat_size;

    // AHB access condition
    logic ahb_access = (HTRANS[1] == 1'b1) && HREADY;

    // Response and read data
    assign HRDATA    = wb_dat_r;
    assign HRESP     = 2'b00; // OKAY
    assign HREADYOUT = 1'b1;  // Always ready (zero-wait for now)

    // Burst type check
    logic is_burst = (HBURST != 3'b000); // Not SINGLE

    always_ff @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            wb_cyc      <= 0;
            wb_stb      <= 0;
            wb_we       <= 0;
            wb_adr      <= 0;
            wb_dat_w    <= 0;
            ahb_active  <= 0;
            burst_cnt   <= 0;
            burst_en    <= 0;
            base_addr   <= 0;
            beat_size   <= 0;
        end else begin
            // Default deassertions
            wb_cyc <= 0;
            wb_stb <= 0;

            if (ahb_access && !ahb_active) begin
                // Start transaction
                wb_adr     <= HADDR;
                wb_we      <= HWRITE;
                wb_dat_w   <= HWDATA;
                wb_cyc     <= 1;
                wb_stb     <= 1;
                ahb_active <= 1;

                // Save base and setup burst
                base_addr  <= HADDR;
                beat_size  <= HSIZE;
                burst_cnt  <= get_burst_len(HBURST); // Number of beats
                burst_en   <= is_burst;
            end else if (ahb_active && wb_ack) begin
                // On ACK: if burst, prepare next beat
                if (burst_en && burst_cnt > 1) begin
                    wb_cyc     <= 1;
                    wb_stb     <= 1;
                    wb_we      <= HWRITE;
                    wb_adr     <= next_burst_addr(wb_adr, beat_size);
                    wb_dat_w   <= HWDATA;
                    burst_cnt  <= burst_cnt - 1;
                    ahb_active <= 1; // continue burst
                end else begin
                    ahb_active <= 0;
                    burst_en   <= 0;
                end
            end
        end
    end

    // Function to compute number of beats from HBURST
    function [2:0] get_burst_len(input [2:0] burst);
        case (burst)
            3'b000: get_burst_len = 3'd1;  // SINGLE
            3'b001: get_burst_len = 3'd4;  // INCR4
            3'b010: get_burst_len = 3'd8;  // INCR8
            3'b011: get_burst_len = 3'd16; // INCR16
            default: get_burst_len = 3'd1; // INCR (undefined length)
        endcase
    endfunction

    // Function to calculate next burst address (incremental only)
    function [ADDR_WIDTH-1:0] next_burst_addr(
        input [ADDR_WIDTH-1:0] addr,
        input [2:0] size
    );
        begin
            next_burst_addr = addr + (1 << size); // increment by beat size
        end
    endfunction

endmodule
