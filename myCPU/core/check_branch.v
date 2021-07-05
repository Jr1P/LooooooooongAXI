`timescale 1ns/100ps

// * 处理分支的各种信号
module check_branch (

    input           eq,
    input [31:0]    rega,

    input           op_bltz,
    input           op_bgez,
    input           op_beq,
    input           op_bne,
    input           op_blez,
    input           op_bgtz,

    // * 0 表示目前段就能知道是否为真正跳转
    // * 1 表示要到下一段 即 ec
    output          realj
);

    wire lez        =   rega[31] || rega == 0;
    assign realj    =   (eq         &&  op_beq  )   ||
                        (!eq        &&  op_bne  )   ||
                        (lez        &&  op_blez )   ||
                        (!lez       &&  op_bgtz )   ||
                        (rega[31]   &&  op_bltz )   ||
                        (!rega[31]  &&  op_bgez )   ;

endmodule