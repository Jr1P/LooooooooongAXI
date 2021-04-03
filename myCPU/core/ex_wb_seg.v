`timescale 1ns/1ps

module ex_wb_seg (
    input   clk,
    input   resetn,

    input   stall,
    input   refresh,

    input [31:0]    ex_pc,
    input [31:0]    ex_inst,
    input [31:0]    ex_res,

    input           ex_load,
    input           ex_loadX,
    input [3 :0]    ex_lsV,
    input [1 :0]    ex_data_addr,
    input           ex_al,

    input           ex_regwen,
    input [4 :0]    ex_wreg,
    
    input           ex_eret,
    input           ex_cp0ren,
    input [31:0]    ex_cp0rdata,
    input [1 :0]    ex_hiloren,
    input [31:0]    ex_hilordata,

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
            wb_hilordata<= 32'b0;
        end
        else if(!stall) begin
            wb_pc       <= ex_pc;
            wb_inst     <= ex_inst;
            wb_res      <= ex_res;
            wb_load     <= ex_load;
            wb_loadX    <= ex_loadX;
            wb_lsV      <= ex_lsV;
            wb_data_addr<= ex_data_addr;
            wb_al       <= ex_al;
            wb_regwen   <= ex_regwen;
            wb_wreg     <= ex_wreg;
            wb_eret     <= ex_eret;
            wb_cp0ren   <= ex_cp0ren;
            wb_cp0rdata <= ex_cp0rdata;
            wb_hiloren  <= ex_hiloren;
            wb_hilordata<= ex_hilordata;
        end
    end

endmodule