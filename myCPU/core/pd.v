`timescale 1ns/100ps
`include "./head.vh"
// * 预解码 pre-decode
module pd (
    input [31:0]    inst,
    input [31:0]    pc,
    output          branch, // ! 1: conditional branch or unconditional jump, 0: not
    // output          jump,   // 1: jump to target, 0: keep going on
    output          j_dir,  // * 直接跳转
    output          j_r,    // * 使用寄存器直接跳转
    output          b,      // * 需判断的条件跳转
    output          take,   // 1: 表示明确的跳转，0:表示不确定是否跳转
    output          target_ok,  // 1: 地址明确的， 0: 地址还不确定
    output [31:0]   target,

    output          op_bltz,
    output          op_bgez,
    output          op_bltzal,
    output          op_bgezal,
    output          op_beq,
    output          op_bne,
    output          op_blez,
    output          op_bgtz,

    output          b_rs_ren,
    output          b_rt_ren,

    output          eret
);
    wire [5 :0] opcode  = `GET_OP(inst);
    wire [4 :0] rscode  = `GET_Rs(inst);
    wire [4 :0] rtcode  = `GET_Rt(inst);
    wire [4 :0] rdcode  = `GET_Rd(inst);
    wire [5 :0] sacode  = `GET_SA(inst);
    wire [5 :0] func    = `GET_FUNC(inst);

    wire [31:0] delay_slot_pc   = pc+32'd4;
    wire [31:0] BranchTarget    = delay_slot_pc + {{14{inst[15]}}, {inst[15:0], 2'b00}};    // branch target
    wire [31:0] JTarget         = {delay_slot_pc[31:28], inst[25:0], 2'b00};                // target of J and JAL
    // * j_r
    wire op_jr      = (rtcode | rdcode | sacode) == 5'd0 && opcode == 6'd0 && func == 6'd8;
    wire op_jalr    = (rtcode | sacode) == 5'd0 && opcode == 6'd0 && func == 6'd9;
    // * j_dir
    wire op_j       = opcode == `J;
    wire op_jal     = opcode == `JAL;
    // * b
    assign op_bltz      = opcode == 6'd1 && rtcode == `BLTZ;
    assign op_bgez      = opcode == 6'd1 && rtcode == `BGEZ;
    assign op_bltzal    = opcode == 6'd1 && rtcode == `BLTZAL;
    assign op_bgezal    = opcode == 6'd1 && rtcode == `BGEZAL;
    assign op_beq       = opcode == `BEQ;
    assign op_bne       = opcode == `BNE;
    assign op_blez      = opcode == `BLEZ && rtcode == 5'd0;
    assign op_bgtz      = opcode == `BGTZ && rtcode == 5'd0;

     // * 只有直接跳转确定是跳转的, b需要判断一些条件, beq 0 0 可以当做直接跳转
    assign take     = j_dir || j_r || (op_beq && (rscode | rdcode) == 5'd0);
    assign target_ok= j_dir || b;   // * j_r类需要寄存器才能知道地址
    assign target   = j_dir ? JTarget : BranchTarget;
    assign j_dir    = op_j || op_jal;
    assign j_r      = op_jr || op_jalr;
    assign b        = op_bltz || op_bgez || op_bltzal || op_bgezal || op_beq || op_bne || op_blez || op_bgtz;
    assign branch   = j_dir || j_r || b;

    assign b_rs_ren =   rscode != 5'h0 && (b || j_r);
    assign b_rt_ren =   rtcode != 5'h0 && (op_beq || op_bne);
    assign eret     =   inst == `ERET;

endmodule