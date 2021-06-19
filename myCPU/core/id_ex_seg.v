`timescale 1ns/1ps
`include "head.vh"

module id_ex_seg (
    input   clk,
    input   resetn,

    input   stall,
    input   refresh,

    input [`EXBITS] id_ex,

    input [31:0]    id_pc,
    input [31:0]    id_inst,
    input           id_imm,
    input [31:0]    id_Imm,
    input [31:0]    id_A,           // GPR[rs]
    input [31:0]    id_B,           // GPR[rt]
    input           id_rs_ren,
    input           id_rt_ren,
    input           id_al,
    input           id_SPEC,
    input           id_load,
    input           id_loadX,
    input [3 :0]    id_lsV,
    input           id_bd,
    input [5 :0]    id_ifunc,      // use for I type
    input           id_regwen,
    input [4 :0]    id_wreg,
    input           id_data_en,
    input [3 :0]    id_data_ren,
    input [3 :0]    id_data_wen,
    input           id_eret,
    input           id_cp0ren,
    input           id_cp0wen,
    input [7 :0]    id_cp0addr,
    input           id_mult,
    input           id_div,
    input           id_mdsign,
    input [1 :0]    id_hiloren,
    input [1 :0]    id_hilowen,

    output reg [`EXBITS]ex_ex,
    
    output reg [31:0]   ex_pc,
    output reg [31:0]   ex_inst,
    output reg          ex_imm,
    output reg [31:0]   ex_Imm,
    output reg [31:0]   ex_A,
    output reg [31:0]   ex_B,
    output reg          ex_rs_ren,
    output reg          ex_rt_ren,
    output reg          ex_al,
    output reg          ex_SPEC,
    output reg          ex_load,
    output reg          ex_loadX,
    output reg [3 :0]   ex_lsV,
    output reg          ex_bd,
    output reg [5 :0]   ex_ifunc,
    output reg          ex_regwen,
    output reg [4 :0]   ex_wreg,
    output reg          ex_data_en,
    output reg [3 :0]   ex_data_ren,
    output reg [3 :0]   ex_data_wen,
    output reg          ex_eret,
    output reg          ex_cp0ren,
    output reg          ex_cp0wen,
    output reg [7 :0]   ex_cp0addr,
    output reg          ex_mult,
    output reg          ex_div,
    output reg          ex_mdsign,
    output reg [1 :0]   ex_hiloren,
    output reg [1 :0]   ex_hilowen
);

    always @(posedge clk) begin
        if(!resetn || refresh) begin
            ex_pc           <= 32'h0;
            ex_inst         <= 32'h0;
            ex_bd           <= 1'b0;
        end
        else if(!stall) begin
            ex_pc           <= id_pc;
            ex_inst         <= id_inst;
            ex_bd           <= id_bd;
        end
    end

    always @(posedge clk) begin
        if(!resetn || refresh) begin
            ex_ex       <= `NUM_EX'b0;
            ex_imm      <= 1'b0;
            ex_Imm      <= 32'h0;
            ex_A        <= 32'h0;
            ex_B        <= 32'h0;
            ex_rs_ren   <= 1'b0;
            ex_rt_ren   <= 1'b0;
            ex_al       <= 1'b0;
            ex_SPEC     <= 1'b0;
            ex_load     <= 1'b0;
            ex_loadX    <= 1'b0;
            ex_lsV      <= 4'b0;
            ex_ifunc    <= 6'h0;
            ex_regwen   <= 1'b0;
            ex_wreg     <= 5'h0;
            ex_data_en  <= 1'b0;
            ex_data_ren <= 4'b0;
            ex_data_wen <= 4'h0;
            ex_eret     <= 1'b0;
            ex_cp0ren   <= 1'b0;
            ex_cp0wen   <= 1'b0;
            ex_cp0addr  <= 8'b0;
            ex_mult     <= 1'b0;
            ex_div      <= 1'b0;
            ex_mdsign   <= 1'b0;
            ex_hilowen  <= 2'b0;
            ex_hiloren  <= 2'b0;
        end
        else if(!stall) begin
            ex_ex       <= id_ex;
            ex_imm      <= id_imm;
            ex_Imm      <= id_Imm;
            ex_A        <= id_A;
            ex_B        <= id_B;
            ex_rs_ren   <= id_rs_ren;
            ex_rt_ren   <= id_rt_ren;
            ex_al       <= id_al;
            ex_SPEC     <= id_SPEC;
            ex_load     <= id_load;
            ex_loadX    <= id_loadX;
            ex_lsV      <= id_lsV;
            ex_ifunc    <= id_ifunc;
            ex_regwen   <= id_regwen;
            ex_wreg     <= id_wreg;
            ex_data_en  <= id_data_en;
            ex_data_ren <= id_data_ren;
            ex_data_wen <= id_data_wen;
            ex_eret     <= id_eret;
            ex_cp0ren   <= id_cp0ren;
            ex_cp0wen   <= id_cp0wen;
            ex_cp0addr  <= id_cp0addr;
            ex_mult     <= id_mult;
            ex_div      <= id_div;
            ex_mdsign   <= id_mdsign;
            ex_hilowen  <= id_hilowen;
            ex_hiloren  <= id_hiloren;
        end
    end

endmodule