`timescale 1ns/1ps
`include "head.vh"

module ex_ec_seg (
    input   clk,
    input   resetn,

    input   stall,
    input   refresh,

    input [`EXBITS] ex_ex,

    input [31:0]    ex_pc,
    input [31:0]    ex_inst,
    input [31:0]    ex_res,
    input [31:0]    ex_B,

    input           ex_load,
    input           ex_loadX,
    input [3 :0]    ex_lsV,
    input           ex_bd,
    input [1 :0]    ex_data_addr,
    input           ex_al,

    input           ex_regwen,
    input [4 :0]    ex_wreg,
    
    input           ex_data_req,

    input           ex_eret,
    input           ex_cp0wen,
    input [`CP0ADDR]ex_cp0addr,
    input           ex_cp0ren,
    input [31:0]    ex_cp0rdata,
    input [1 :0]    ex_hiloren,
    input [31:0]    ex_hilordata,

    output reg [`EXBITS]ec_ex,
    output reg [31:0]   ec_pc,
    output reg [31:0]   ec_inst,
    output reg [31:0]   ec_res,
    output reg [31:0]   ec_res1, //* reduce fanout
    output reg [31:0]   ec_B,
    output reg          ec_load,
    output reg          ec_loadX,
    output reg [3 :0]   ec_lsV,
    output reg          ec_bd,
    output reg [1 :0]   ec_data_addr,
    output reg          ec_al,

    output reg          ec_regwen,
    output reg [4 :0]   ec_wreg,

    output reg          ec_data_req,

    output reg          ec_eret,
    output reg          ec_cp0wen,
    output reg [`CP0ADDR] ec_cp0addr,
    output reg          ec_cp0ren,
    output reg [31:0]   ec_cp0rdata,
    output reg [1 :0]   ec_hiloren,
    output reg [31:0]   ec_hilordata
);

    always @(posedge clk) begin
        if(!resetn || refresh) begin
            ec_ex       <= `NUM_EX'b0;
            ec_pc       <= 32'b0;
            ec_inst     <= 32'b0;
            ec_res      <= 32'b0;
            ec_res1     <= 32'b0;
            ec_B        <= 32'b0;
            ec_load     <= 1'b0;
            ec_loadX    <= 1'b0;
            ec_lsV      <= 4'b0;
            ec_bd       <= 1'b0;
            ec_data_addr<= 2'b0;
            ec_al       <= 1'b0;
            ec_regwen   <= 1'b0;
            ec_wreg     <= 5'b0;
            ec_data_req <= 1'b0;
            ec_eret     <= 1'b0;
            ec_cp0wen   <= 1'b0;
            ec_cp0addr  <= 8'b0;
            ec_cp0ren   <= 1'b0;
            ec_cp0rdata <= 32'b0;
            ec_hiloren  <= 2'b0;
            ec_hilordata<= 32'b0;
        end
        else if(!stall) begin
            ec_ex       <= ex_ex;
            ec_pc       <= ex_pc;
            ec_inst     <= ex_inst;
            ec_res      <= ex_res;
            ec_res1     <= ex_res;
            ec_B        <= ex_B;
            ec_load     <= ex_load;
            ec_loadX    <= ex_loadX;
            ec_lsV      <= ex_lsV;
            ec_bd       <= ex_bd;
            ec_data_addr<= ex_data_addr;
            ec_al       <= ex_al;
            ec_regwen   <= ex_regwen;
            ec_wreg     <= ex_wreg;
            ec_data_req <= ex_data_req;
            ec_eret     <= ex_eret;
            ec_cp0wen   <= ex_cp0wen;
            ec_cp0addr  <= ex_cp0addr;
            ec_cp0ren   <= ex_cp0ren;
            ec_cp0rdata <= ex_cp0rdata;
            ec_hiloren  <= ex_hiloren;
            ec_hilordata<= ex_hilordata;
        end
    end

endmodule