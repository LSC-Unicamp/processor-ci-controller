module AXI4Lite_to_Wishbone #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input  logic                  ACLK,
    input  logic                  ARESETN,

    // AXI4-Lite Slave Interface
    input  logic [ADDR_WIDTH-1:0] AWADDR,
    input  logic [2:0]            AWPROT,
    input  logic                  AWVALID,
    output logic                  AWREADY,

    input  logic [DATA_WIDTH-1:0] WDATA,
    input  logic [(DATA_WIDTH/8)-1:0] WSTRB,
    input  logic                  WVALID,
    output logic                  WREADY,

    output logic [1:0]            BRESP,
    output logic                  BVALID,
    input  logic                  BREADY,

    input  logic [ADDR_WIDTH-1:0] ARADDR,
    input  logic [2:0]            ARPROT,
    input  logic                  ARVALID,
    output logic                  ARREADY,

    output logic [DATA_WIDTH-1:0] RDATA,
    output logic [1:0]            RRESP,
    output logic                  RVALID,
    input  logic                  RREADY,

    // Wishbone Master Interface
    output logic [ADDR_WIDTH-1:0] wb_adr_o,
    output logic [DATA_WIDTH-1:0] wb_dat_o,
    output logic                  wb_we_o,
    output logic                  wb_stb_o,
    output logic                  wb_cyc_o,
    output logic [(DATA_WIDTH/8)-1:0] wb_sel_o,
    input  logic [DATA_WIDTH-1:0] wb_dat_i,
    input  logic                  wb_ack_i,
    input  logic                  wb_err_i
);

    // Estado interno
    typedef enum logic [1:0] {
        IDLE,
        WRITE,
        READ
    } state_t;

    state_t state;

    always_ff @(posedge ACLK or negedge ARESETN) begin
        if (!ARESETN) begin
            state    <= IDLE;
            AWREADY  <= 0;
            WREADY   <= 0;
            BVALID   <= 0;
            ARREADY  <= 0;
            RVALID   <= 0;
            wb_cyc_o <= 0;
            wb_stb_o <= 0;
            wb_we_o  <= 0;
        end else begin
            unique case (state)
                IDLE: begin
                    AWREADY <= 1;
                    ARREADY <= 1;
                    BVALID  <= 0;
                    RVALID  <= 0;

                    if (AWVALID && AWREADY) begin
                        wb_adr_o <= AWADDR;
                        wb_we_o  <= 1;
                        wb_dat_o <= WDATA;
                        wb_sel_o <= WSTRB;
                        wb_cyc_o <= 1;
                        wb_stb_o <= 1;
                        AWREADY  <= 0;
                        WREADY   <= 1;
                        state    <= WRITE;
                    end
                    else if (ARVALID && ARREADY) begin
                        wb_adr_o <= ARADDR;
                        wb_we_o  <= 0;
                        wb_cyc_o <= 1;
                        wb_stb_o <= 1;
                        ARREADY  <= 0;
                        state    <= READ;
                    end
                end

                WRITE: begin
                    if (WVALID && WREADY) begin
                        WREADY <= 0;
                    end

                    if (wb_ack_i) begin
                        wb_cyc_o <= 0;
                        wb_stb_o <= 0;
                        BVALID   <= 1;
                        BRESP    <= (wb_err_i) ? 2'b10 : 2'b00; // 2'b10 = SLVERR, 2'b00 = OKAY
                        state    <= IDLE;
                    end
                end

                READ: begin
                    if (wb_ack_i) begin
                        wb_cyc_o <= 0;
                        wb_stb_o <= 0;
                        RDATA    <= wb_dat_i;
                        RRESP    <= (wb_err_i) ? 2'b10 : 2'b00; // 2'b10 = SLVERR, 2'b00 = OKAY
                        RVALID   <= 1;
                        state    <= IDLE;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end
endmodule
