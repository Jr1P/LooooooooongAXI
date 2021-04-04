`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/26/2020 03:46:57 PM
// Design Name: 
// Module Name: inst_cache_tagv
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

module inst_cache_tagv(
    //Input
    input clk,
    input en,
    input wen,
    input op_wen,
    input [`INST_CACHE_INDEX_WIDTH-1:0] index,
    input [`INST_CACHE_TAG_WIDTH-1:0] tag_wdata, 
    input valid_wdata,
    //Output
    output hit,
    output pre_found
    );

    //wtag
    reg [`INST_CACHE_TAG_WIDTH-1:0] wtag;
    always @(posedge clk) begin
        wtag <= tag_wdata;
    end

    reg [`INST_CACHE_TAGV_WIDTH-1:0] tag_ram[`INST_CACHE_GROUP_NUM-1:0];

    always @(posedge clk) begin
        if (wen | op_wen) begin
            tag_ram[index] <= {tag_wdata,valid_wdata};
        end        
        else begin
        end
    end

    reg [`INST_CACHE_TAGV_WIDTH-1:0] tag_rdata;
    reg [`INST_CACHE_TAGV_WIDTH-1:0] pre_tag_rdata;
    wire [`INST_CACHE_INDEX_WIDTH-1:0] next_index;
    assign next_index = index + `INST_CACHE_INDEX_WIDTH'b1;
    always @(posedge clk) begin
        tag_rdata     <= tag_ram[index];        
        pre_tag_rdata <= tag_ram[next_index];
    end

    assign valid = tag_rdata[0];
    assign hit = !(tag_rdata[`INST_CACHE_TAGV_WIDTH-1:1] ^ wtag) & valid;
    assign pre_found = !(pre_tag_rdata[`INST_CACHE_TAGV_WIDTH-1:1] ^ wtag) & pre_tag_rdata[0];
endmodule
