`timescale 1ns/1ps
`include "head.vh"

module ec (
    input [5 :0]    ext_int,
    input           clk,
    input           resetn,

    input [`EXBITS] ec_ex,
    input [31:0]    ec_pc,
    input [31:0]    ec_res,
    input           ec_load,

    input           ec_cp0ren,
    input           ec_cp0wen,
    // input [7 :0]    ec_cp0addr,
    input [31:0]    ec_wdata,
    input           ec_bd,
    input           ec_eret,

    input           ec_cp0_badV_en,
    input           ec_cp0_count_en,
    input           ec_cp0_compare_en,
    input           ec_cp0_status_en,
    input           ec_cp0_cause_en,
    input           ec_cp0_epc_en,

    input [31:0]    ec_reorder_ex,
    input           wb_eret,

    output          exc_oc,
    output          ext_int_response,
    output [31:0]   cp0rdata,
    output [31:0]   cp0_epc,
    output [31:0]   reorder_data
);

    wire [4:0] exc_excode = ext_int     ? `EXC_INT  :
                            ec_ex[5]    ? `EXC_AdEL :   // *取指地址错
                            ec_ex[4]    ? `EXC_RI   :   // *RI
                            ec_ex[3]    ? `EXC_Ov   :   // *Overflow
                            ec_ex[2]    ? `EXC_Bp   :   // *Break point
                            ec_ex[1]    ? `EXC_Sys  :   // *syscall
                            ec_ex[0]    ? 
                                ec_load ? `EXC_AdEL : `EXC_AdES
                                        : 5'b0      ;
    wire [31:0] exc_epc =   ec_cp0wen   ? ec_pc+32'd4 : // * 软件中断
                            ec_bd       ? ec_pc-32'd4 : ec_pc; // * 延迟槽和通常情况
    wire [31:0] cp0_status, cp0_cause;  // * cp0cause not use for now
    // * valid 1 : 表示有例外在处理, 刚传到ec段的例外也算属于在处理
    // * exl位高表示在异常处理, 如果wb段eret了，就看ec段有没有新异常提交
    wire exc_valid =    cp0_status[`Status_EXL] && !wb_eret ? 1'b1 : 
                        (ext_int_response || (|ec_ex));

    assign reorder_data =   ec_cp0ren ? cp0rdata : ec_reorder_ex;
    wire [31:0] exc_badvaddr = ec_ex[5] ? ec_pc : ec_res; // FIXME: ec_pc可能需要修改，取地址错误的地址不一定是ec_pc
    assign exc_oc = !cp0_status[`Status_EXL] && exc_valid;
    // * CP0 regs
    cp0 u_cp0(
        .clk    (clk),
        .resetn (resetn),

        .ext_int(ext_int),

        .wen    (ec_cp0wen),
        // .addr   (ec_cp0addr),
        .wdata  (ec_wdata),

        .cp0_badV_en    (ec_cp0_badV_en),
        .cp0_count_en   (ec_cp0_count_en),
        .cp0_compare_en (ec_cp0_compare_en),
        .cp0_status_en  (ec_cp0_status_en),
        .cp0_cause_en   (ec_cp0_cause_en),
        .cp0_epc_en     (ec_cp0_epc_en),

        .exc_valid      (exc_valid),
        .exc_excode     (exc_excode),
        .exc_bd         (ec_bd),
        .exc_epc        (exc_epc),   // * 中断的时候epc 也给ec段的pc
        .exc_badvaddr   (exc_badvaddr),
        .exc_eret       (ec_eret),

        // * O
        .rdata              (cp0rdata),

        .ext_int_response   (ext_int_response),

        .cause      (cp0_cause),
        .status     (cp0_status),
        .epc        (cp0_epc)
    );

endmodule