`timescale 1ns/1ps
`include "head.vh"

module ec (
    input [5 :0]    ext_int,
    input           clk,
    input           resetn,

    input [`EXBITS] ec_ex,
    input [31:0]    ec_pc,
    input [31:0]    ec_res,
    input           ec_al,
    input           ec_load,

    input           ec_cp0ren,
    input           ec_cp0wen,
    input [7 :0]    ec_cp0addr,
    input [31:0]    ec_wdata,
    input [1 :0]    ec_hiloren,
    input [31:0]    ec_hilordata,
    input           wb_eret,

    output          ext_int_soft,
    output          ext_int_response,
    output [31:0]   ec_cp0rdata,
    output [31:0]   cp0_epc,
    output [31:0]   ec_reorder_data
);

    assign ec_reorder_data =    ec_hiloren  ?   ec_hilordata    :   //* HI/LO
                                ec_al       ?   ec_pc+32'd8     :   //* al写GPR[31]
                                ec_cp0ren   ?   ec_cp0rdata     :   //* cp0
                                                ec_res          ;

    wire [4:0] exc_excode = ext_int     ? `EXC_INT  :
                            ec_ex[5]    ? `EXC_AdEL :   // *取指地址错
                            ec_ex[4]    ? `EXC_RI   :   // *RI
                            ec_ex[3]    ? `EXC_Ov   :   // *Overflow
                            ec_ex[2]    ? `EXC_Bp   :   // *Break point
                            ec_ex[1]    ? `EXC_Sys  :   // *syscall
                            ec_ex[0]    ? 
                                ec_load ? `EXC_AdEL : `EXC_AdES
                                        : 5'b0      ;
    wire [31:0] exc_epc = ec_bd ? ec_pc-32'd4 : ec_pc;
    wire [31:0] cp0_status, cp0_cause;  // * cp0cause not use for now
    wire exc_valid = cp0_status[`Status_EXL] ? !wb_eret : // * valid 1 : 表示有例外在处理, 刚传到ex段的例外也算属于在处理
                    ext_int_response ? 1'b1 : |ec_ex;

    assign ex_exc_oc = !cp0_status[`Status_EXL] && exc_valid;
    wire [31:0] exc_badvaddr = ec_ex[5] ? ec_pc : ec_res; // FIXME: ec_pc可能需要修改，取地址错误的地址不一定是ec_pc
    // * CP0 regs
    cp0 u_cp0(
        .clk    (clk),
        .resetn (resetn),

        .ext_int(ext_int),

        .wen    (ec_cp0wen),
        .addr   (ec_cp0addr),
        .wdata  (ec_wdata),

        .exc_valid      (exc_valid),
        .exc_excode     (exc_excode),
        .exc_bd         (ec_bd),
        .exc_epc        (exc_epc),   // * 中断的时候epc 也给ec段的pc
        .exc_badvaddr   (exc_badvaddr),
        .exc_eret       (ec_eret),

        // * O
        .rdata              (ec_cp0rdata),

        .ext_int_response   (ext_int_response),
        .ext_int_soft       (ext_int_soft), // * 指示本条指令是否写ip_software且会在下一个周期产生软件中断

        .cause      (cp0_cause),
        .status     (cp0_status),
        .epc        (cp0_epc)
    );

endmodule