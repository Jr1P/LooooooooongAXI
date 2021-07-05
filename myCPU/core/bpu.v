`timescale 1ns/100ps

// * 处理分支的各种信号
module bpu (

    input           eq,
    input [31:0]    rega,

    input           op_bltz,
    input           op_bgez,
    input           op_beq,
    input           op_bne,
    input           op_blez,
    input           op_bgtz,

    input           b_rs_ren,
    input           b_rt_ren,
    input [4:0]     id_rs,
    input [4:0]     id_rt,

    input [4:0]     ex_wreg,
    input           ex_load,
    input [4:0]     ec_wreg,
    input           ec_load,
    // * O
    // * 0 表示目前段就能知道是否为真正跳转
    // * 1 表示要到下一段 即 ex
    // * 2 表示要到下下段 即 ec
    output          realj,
    output  [1:0]   wait_seg
);
    wire ex_rel_rs = ex_wreg == id_rs && b_rs_ren;
    wire ex_rel_rt = ex_wreg == id_rt && b_rt_ren;

    wire ec_rel_rs = ec_wreg == id_rs && b_rs_ren;
    wire ec_rel_rt = ec_wreg == id_rt && b_rt_ren;

    wire lez        =   rega[31] || rega == 0;
    assign realj    =   (eq         &&  op_beq  )   ||
                        (!eq        &&  op_bne  )   ||
                        (lez        &&  op_blez )   ||
                        (!lez       &&  op_bgtz )   ||
                        (rega[31]   &&  op_bltz )   ||
                        (!rega[31]  &&  op_bgez )   ;

    assign wait_seg =   ex_rel_rs || ex_rel_rt ? (2'b01 << ex_load) :
                        {1'b0, (ec_rel_rs || ec_rel_rt) && ec_load} ;

endmodule