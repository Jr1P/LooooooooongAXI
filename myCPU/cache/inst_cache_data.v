`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/26/2020 03:57:22 PM
// Design Name: 
// Module Name: inst_cache_data
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`include "../Head_Files/Parameter.vh"
`include "../Head_Files/Cache.vh"

module inst_cache_data(
    //Inputs
    input                                                clk,
    // input resetn,
    input                                                en,
    input   [31:0]                                       wen,
    input [`INST_CACHE_INDEX_WIDTH -1:0]                 index,//Line choose
    input [`INST_CACHE_OFFSET_WIDTH-1:0]                   offset,//Bank choose
    input [`INST_CACHE_BANK_WIDTH * `INST_CACHE_BANK_NUM-1:0] data_wdata,
    //Outputs
    output [`INST_CACHE_BANK_WIDTH -1:0]                   data_rdata
    );

     /*
        ICache_data module:
            8x32-bit bank
            bank0-8
    */
    //----------Bank----------
    reg [7:0] woffset;
    always @(posedge clk) begin
        woffset <= offset;
    end

    wire [255:0] bank_douta;
    wire [31:0] buf_rdata[7:0];
    assign {buf_rdata[0],buf_rdata[1],buf_rdata[2],buf_rdata[3],buf_rdata[4],buf_rdata[5],buf_rdata[6],buf_rdata[7]} = bank_douta;
    assign data_rdata = buf_rdata[woffset[4:2]];

    inst_cache_data_ram INST_BANK_0_7(
        .clka(clk),
        .ena(en),
        .wea(wen),
        .addra(index),
        .dina(data_wdata),
        .douta(bank_douta)
        );
endmodule
