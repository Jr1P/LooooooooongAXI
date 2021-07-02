`timescale 1ns / 1ps

module wb (
    input [31:0]    data_rdata,
    input           wb_load,
    input           wb_loadX,
    input [3 :0]    wb_lsV,
    input [1 :0]    wb_data_addr,
    input [31:0]    wb_reorder_ec,

    output [31:0]   wb_rdata,
    output [31:0]   wb_reorder_data
);

    wire [31:0] wb_data_rdata = data_rdata >> {wb_data_addr, 3'b0};
    assign wb_rdata[7 : 0] =    {8{wb_lsV[0]}} & wb_data_rdata[7:0];
    assign wb_rdata[15: 8] =    {8{wb_lsV[1]}} & wb_data_rdata[15:8] |
                                {8{!wb_lsV[1] && wb_lsV[0] && wb_loadX && wb_data_rdata[7]}};
    assign wb_rdata[31:16] =    {16{wb_lsV[2] && wb_lsV[3]}} & wb_data_rdata[31:16]   |
                                {16{!wb_lsV[2] && !wb_lsV[3] && wb_lsV[1] && wb_loadX && wb_data_rdata[15]}} |
                                {16{!wb_lsV[2] && !wb_lsV[3] && !wb_lsV[1] && wb_lsV[0] && wb_loadX && wb_data_rdata[7]}};
    // * 重定向数据
    assign wb_reorder_data  =   wb_load ? wb_rdata : wb_reorder_ec;

endmodule