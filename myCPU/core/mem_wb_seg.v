`timescale 1ns/1ps

module mem_wb_seg (
    input           clk,
    input           resetn,

    input   stall,
    input   refresh,

    input [31:0]    mem_pc,
    input [31:0]    mem_inst,
    input [31:0]    mem_res,
    input           mem_load,
    input           mem_loadX,
    input [3 :0]    mem_lsV,
    input [1 :0]    mem_data_addr,
    input           mem_al,
    input           mem_regwen,
    input [4 :0]    mem_wreg,
    input           mem_eret,
    input           mem_cp0ren,
    input [31:0]    mem_cp0rdata,
    input [1 :0]    mem_hiloren,
    input [1 :0]    mem_hilowen,
    input [31:0]    mem_hilordata,

    output reg [31:0]   wb_pc,
    output reg [31:0]   wb_inst,
    output reg [31:0]   wb_res,
    output reg          wb_load,
    output reg          wb_loadX,
    output reg [3 :0]   wb_lsV,
    output reg [1 :0]   wb_data_addr,
    output reg          wb_al,
    output reg          wb_regwen,
    output reg [4 :0]   wb_wreg,
    output reg          wb_eret,
    output reg          wb_cp0ren,
    output reg [31:0]   wb_cp0rdata,
    output reg [1 :0]   wb_hiloren,
    output reg [1 :0]   wb_hilowen,
    output reg [31:0]   wb_hilordata
);

    always @(posedge clk) begin
        if(!resetn || refresh) begin
            wb_pc       <= 32'b0;
            wb_inst     <= 32'b0;
            wb_res      <= 32'b0;
            wb_load     <= 1'b0;
            wb_loadX    <= 1'b0;
            wb_lsV      <= 4'b0;
            wb_data_addr<= 2'b0;
            wb_al       <= 1'b0;
            wb_regwen   <= 1'b0;
            wb_wreg     <= 5'b0;
            wb_eret     <= 1'b0;
            wb_cp0ren   <= 1'b0;
            wb_cp0rdata <= 32'b0;
            wb_hiloren  <= 2'b0;
            wb_hilowen  <= 2'b0;
            wb_hilordata<= 32'b0;
        end
        else if(!stall) begin
            wb_pc       <= mem_pc;
            wb_inst     <= mem_inst;
            wb_res      <= mem_res;
            wb_load     <= mem_load;
            wb_loadX    <= mem_loadX;
            wb_lsV      <= mem_lsV;
            wb_data_addr<= mem_data_addr;
            wb_al       <= mem_al;
            wb_regwen   <= mem_regwen;
            wb_wreg     <= mem_wreg;
            wb_eret     <= mem_eret;
            wb_cp0ren   <= mem_cp0ren;
            wb_cp0rdata <= mem_cp0rdata;
            wb_hiloren  <= mem_hiloren;
            wb_hilowen  <= mem_hilowen;
            wb_hilordata<= mem_hilordata;
        end
    end

endmodule