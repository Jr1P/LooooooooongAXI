`timescale 1ns / 1ps

module wb (
    input [31:0]    data_rdata,
    input [31:0]    wb_pc,
    input [31:0]    wb_res,
    input           wb_load,
    input           wb_loadX,
    input [3 :0]    wb_lsV,
    input [1 :0]    wb_data_addr,
    input           wb_al,
    input           wb_cp0ren,
    input [31:0]    wb_cp0rdata,
    input [1 :0]    wb_hiloren,
    input [31:0]    wb_hilordata,

    output [31:0]   wb_reorder_data
);

    wire [31:0] wb_rdata;
    wire [31:0] wb_data_rdata = data_rdata >> {wb_data_addr, 3'b0};
    assign wb_rdata[7 : 0] =    {8{wb_lsV[0]}} & wb_data_rdata[7:0];
    assign wb_rdata[15: 8] =    {8{wb_lsV[1]}} & wb_data_rdata[15:8] |
                                {8{!wb_lsV[1] && wb_lsV[0] && wb_loadX && wb_data_rdata[7]}};
    assign wb_rdata[31:16] =    {16{wb_lsV[2] && wb_lsV[3]}} & wb_data_rdata[31:16]   |
                                {16{!wb_lsV[2] && !wb_lsV[3] && wb_lsV[1] && wb_loadX && wb_data_rdata[15]}} |
                                {16{!wb_lsV[2] && !wb_lsV[3] && !wb_lsV[1] && wb_lsV[0] && wb_loadX && wb_data_rdata[7]}};
    // * 重定向数据
    assign wb_reorder_data  =   wb_load         ? wb_rdata      :   //* wb段load写rs
                                wb_cp0ren       ? wb_cp0rdata   :   //* wb段读cp0写rs
                                (|wb_hiloren)   ? wb_hilordata  :   //* wb段读HI/LO写rs
                                wb_al           ? wb_pc+32'd8   :   //* wb段al写GPR[31]
                                                  wb_res        ;

endmodule