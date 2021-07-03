`timescale 1ns / 1ps

module wb (
    input [31:0]    data_rdata,
    input           wb_load,
    input [31:0]    wb_reorder_ec,

    output [31:0]   wb_reorder_data
);

    // * 重定向数据
    assign wb_reorder_data  =   wb_load ? data_rdata : wb_reorder_ec;

endmodule