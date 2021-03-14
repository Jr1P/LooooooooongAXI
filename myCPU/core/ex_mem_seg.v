`timescale 1ns/1ps

module ex_mem_seg (
    input           clk,
    input           resetn,
    
    input   stall,
    input   refresh,

    input [`EXBITS] ex_ex,
    input [31:0]    ex_pc,
    input [31:0]    ex_inst,
    input [31:0]    ex_res,

    input           ex_load,
    input           ex_loadX,
    input [3 :0]    ex_lsV,
    input           ex_bd,
    input           ex_al,

    input           ex_data_en,
    input [3 :0]    ex_data_ren,
    input [3 :0]    ex_data_wen,
    input [31:0]    ex_wdata,

    input           ex_regwen,
    input [4 :0]    ex_wreg,
    
    input           ex_eret,
    input           ex_cp0ren,
    input           ex_cp0wen,
    input [7 :0]    ex_cp0addr,
    input [1 :0]    ex_hiloren,
    input [1 :0]    ex_hilowen,
    input [31:0]    ex_hilordata,

    output reg [`EXBITS]mem_ex,
    output reg [31:0]   mem_pc,
    output reg [31:0]   mem_inst,
    output reg [31:0]   mem_res,
    output reg          mem_load,
    output reg          mem_loadX,
    output reg [3 :0]   mem_lsV,
    output reg          mem_bd,
    output reg          mem_al,

    output reg          mem_data_en,
    output reg [3 :0]   mem_data_ren,
    output reg [3 :0]   mem_data_wen,
    output reg [31:0]   mem_wdata,

    output reg          mem_regwen,
    output reg [4 :0]   mem_wreg,

    output reg          mem_eret,
    output reg          mem_cp0ren,
    output reg          mem_cp0wen,
    output reg [7 :0]   mem_cp0addr,
    output reg [1 :0]   mem_hiloren,
    output reg [1 :0]   mem_hilowen,
    output reg [31:0]   mem_hilordata
);

    always @(posedge clk) begin
        if(!resetn || refresh) begin
            mem_ex          <= `NUM_EX'b0;
            mem_pc          <= 32'b0;
            mem_inst        <= 32'b0;
            mem_res         <= 32'b0;
            mem_load        <= 1'b0;
            mem_loadX       <= 1'b0;
            mem_lsV         <= 4'b0;
            mem_bd          <= 1'b0;
            mem_al          <= 1'b0;
            mem_data_en     <= 1'b0;
            mem_data_ren    <= 4'b0;
            mem_data_wen    <= 4'b0;
            mem_wdata       <= 32'b0;
            mem_regwen      <= 1'b0;
            mem_wreg        <= 5'b0;
            mem_eret        <= 1'b0;
            mem_cp0ren      <= 1'b0;
            mem_cp0wen      <= 1'b0;
            mem_cp0addr     <= 8'b0;
            mem_hiloren     <= 2'b0;
            mem_hilowen     <= 2'b0;
            mem_hilordata   <= 32'b0;
        end
        else if(!stall) begin
            mem_ex          <= ex_ex;
            mem_pc          <= ex_pc;
            mem_inst        <= ex_inst;
            mem_res         <= ex_res;
            mem_load        <= ex_load;
            mem_loadX       <= ex_loadX;
            mem_lsV         <= ex_lsV;
            mem_bd          <= ex_bd;
            mem_al          <= ex_al;
            mem_data_en     <= ex_data_en;
            mem_data_ren    <= ex_data_ren;
            mem_data_wen    <= ex_data_wen;
            mem_wdata       <= ex_wdata;
            mem_regwen      <= ex_regwen;
            mem_wreg        <= ex_wreg;
            mem_eret        <= ex_eret;
            mem_cp0ren      <= ex_cp0ren;
            mem_cp0wen      <= ex_cp0wen;
            mem_cp0addr     <= ex_cp0addr;
            mem_hiloren     <= ex_hiloren;
            mem_hilowen     <= ex_hilowen;
            mem_hilordata   <= ex_hilordata;
        end
    end

endmodule