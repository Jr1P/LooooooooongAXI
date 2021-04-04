`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/27/2020 07:39:08 PM
// Design Name: 
// Module Name: data_cache_tagv
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

module data_cache_tagv(
    //Input
    input clk,
    input en,
    input wen,
    input op_wen,
    input [`DATA_CACHE_INDEX_WIDTH-1:0] index,
    input [`DATA_CACHE_TAG_WIDTH-1:0] tag_wdata, 
    input valid_wdata,
    //Output
    output hit,
    output valid,
    output [`DATA_CACHE_TAG_WIDTH-1:0] tag_rdata
    );
    
    //wtag
    reg [`DATA_CACHE_TAG_WIDTH-1:0] wtag;
    always @(posedge clk) begin
        wtag <= tag_wdata;
    end
 
    reg [`DATA_CACHE_TAGV_WIDTH-1:0] tag_ram[`DATA_CACHE_GROUP_NUM-1:0];

    always @(posedge clk) begin
        if (wen | op_wen) begin
            tag_ram[index] <= {tag_wdata,valid_wdata};
        end        
        else begin
        end
    end
    reg [`DATA_CACHE_TAGV_WIDTH-1:0] tag_dout;

    always @(posedge clk) begin
        tag_dout <= tag_ram[index];
    end

    assign tag_rdata = tag_dout[`DATA_CACHE_TAG_WIDTH-1:1];
    assign valid = tag_dout[0];
    assign hit = !(tag_dout[`DATA_CACHE_TAG_WIDTH-1:1] ^ wtag) & valid; 
endmodule
