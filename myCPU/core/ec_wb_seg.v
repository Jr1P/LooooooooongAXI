`timescale 1ns/1ps

module ec_wb_seg (
    input   clk,
    input   resetn,

    input   stall,
    input   refresh,

    input [31:0]    ec_data_rdata,
    input [31:0]    ec_pc,
    input [31:0]    ec_inst,
    input [31:0]    ec_res,

    input           ec_load,
    input           ec_loadX,
    input [3 :0]    ec_lsV,
    input [1 :0]    ec_data_addr,
    input           ec_al,

    input           ec_regwen,
    input [4 :0]    ec_wreg,
    
    input           ec_data_req,

    input           ec_eret,
    input           ec_cp0ren,
    input [31:0]    ec_cp0rdata,
    input [1 :0]    ec_hiloren,
    input [31:0]    ec_hilordata,

    output reg [31:0]   wb_data_rdata,
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

    output reg          wb_data_req,

    output reg          wb_eret,
    output reg          wb_cp0ren,
    output reg [31:0]   wb_cp0rdata,
    output reg [1 :0]   wb_hiloren,
    output reg [31:0]   wb_hilordata
);

    always @(posedge clk) begin
        if(!resetn || refresh) begin
            wb_data_rdata   <= 32'b0;
            wb_pc           <= 32'b0;
            wb_inst         <= 32'b0;
            wb_res          <= 32'b0;
            wb_load         <= 1'b0;
            wb_loadX        <= 1'b0;
            wb_lsV          <= 4'b0;
            wb_data_addr    <= 2'b0;
            wb_al           <= 1'b0;
            wb_regwen       <= 1'b0;
            wb_wreg         <= 5'b0;
            wb_data_req     <= 1'b0;
            wb_eret         <= 1'b0;
            wb_cp0ren       <= 1'b0;
            wb_cp0rdata     <= 32'b0;
            wb_hiloren      <= 2'b0;
            wb_hilordata    <= 32'b0;
        end
        else if(!stall) begin
            wb_data_rdata   <= ec_data_rdata;
            wb_pc           <= ec_pc;
            wb_inst         <= ec_inst;
            wb_res          <= ec_res;
            wb_load         <= ec_load;
            wb_loadX        <= ec_loadX;
            wb_lsV          <= ec_lsV;
            wb_data_addr    <= ec_data_addr;
            wb_al           <= ec_al;
            wb_regwen       <= ec_regwen;
            wb_wreg         <= ec_wreg;
            wb_data_req     <= ec_data_req;
            wb_eret         <= ec_eret;
            wb_cp0ren       <= ec_cp0ren;
            wb_cp0rdata     <= ec_cp0rdata;
            wb_hiloren      <= ec_hiloren;
            wb_hilordata    <= ec_hilordata;
        end
    end

endmodule