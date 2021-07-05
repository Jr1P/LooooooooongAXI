`timescale 1ns/1ps
`include "./head.vh"

// * refer to ucas
module decoder #(parameter integer bits = 4)
(
    input [bits-1:0] in,
    output [(1<<bits)-1:0] out
);

    generate
        genvar i;
        for (i=0; i<(1<<bits); i=i+1) begin
            assign out[i] = in == i;
        end
    endgenerate

endmodule

// * instruction decode
module id(
    input           id_addr_error,

    input   [31:0]  id_inst,        // used in Branch and J ins
    input   [31:0]  id_pc,
    input           b_r,            // branch or jr jalr
    // * 跳转相关
    output          al,             // 1: save return address, 0: not
    // *
    output          SPEC,           // 1: opcode is SPEC, 0: non-SPEC
    output          rs_ren,         // 1: read rs
    output          rt_ren,         // 1: read rt
    output          load,           // 1: load data from data mem, 0:not
    output          loadX,          // valid when load is 1, 1: signed extend data loaded from data mem, 0: zero extend
    output  [3 :0]  lsV,            // load store vaild, lsV[i] = 1 means the i-th Byte from data mem(or into data mem) is valid
    output          imm,            // 1: with immediate, 0: not
    output  [31:0]  Imm,            // number of Immediate

    output          regwen,         // write en on GPRs, 1: write GPR[wreg], 0: not write
    output  [4 :0]  wreg,           // vaild when regwen is 1
    // * HI LO
    output          mult,           // 1: mult operation
    output          div,            // 1: div operation 
    output          mdsign,        // mul, div sign, 1: signed, 0: unsigned
    output  [1 :0]  hiloren,        // 2'b01: read LO, 2'b10: read HI
    output  [1 :0]  hilowen,        // 0: not write, whilo[0] == 1: write lo, whilo[1] == 1: write hi
    // * Data Mem
    output          data_en,        // data active en
    output  [3 :0]  data_ren,       // 4'b0001: load byte, 4'b0011: load half word, 4'b1111: load word
    output  [3 :0]  data_wen,       // data write en
    output  [3 :0]  data_wren,
    // * cp0
    output          cp0ren,         // 1: read cp0 at cp0regs[cp0addr]
    output          cp0wen,         // 1: write cp0 at cp0regs[cp0addr]
    output  [7 :0]  cp0addr,        // read or write address of cp0regs

    output  [5 :0]  func,           // valid when SPEC is 0, use for I type
    // * 例外
    output              eret,   // eret instruction
    output  [`EXBITS]   id_ex   // Ex
);
    // TODO: TLB instructions and cache instructions
                                            // target of JR and JALR
    wire [5 :0] opcode          = `GET_OP(id_inst);
    wire [4 :0] rscode          = `GET_Rs(id_inst);
    wire [4 :0] rtcode          = `GET_Rt(id_inst);
    wire [4 :0] rdcode          = `GET_Rd(id_inst);
    wire [5 :0] IR_func         = `GET_FUNC(id_inst);
    wire [2 :0] selcode         = `GET_SEL(id_inst);

    wire [63:0] op_d, func_d;
    wire [31:0] rs_d, rt_d, rd_d, sa_d;

    // * inst table
    decoder #(.bits(6))
        dec_op (
            .in (opcode),
            .out(op_d)
        ),
        dec_func (
            .in (IR_func),
            .out(func_d)
        );

    decoder #(.bits(5))
        dec_rs (
            .in (rscode),
            .out(rs_d)
        ),
        dec_rt (
            .in (rtcode),
            .out(rt_d)
        ),
        dec_rd (
            .in (rdcode),
            .out(rd_d)
        ),
        dec_sa (
            .in (`GET_SA(id_inst)),
            .out(sa_d)
        );

    wire op_sll     = op_d[0] && rs_d[0] && func_d[0];
    wire op_srl     = op_d[0] && rs_d[0] && func_d[2];
    wire op_sra     = op_d[0] && rs_d[0] && func_d[3];
    wire op_sllv    = op_d[0] && sa_d[0] && func_d[4];
    wire op_srlv    = op_d[0] && sa_d[0] && func_d[6];
    wire op_srav    = op_d[0] && sa_d[0] && func_d[7];
    wire op_jr      = op_d[0] && rt_d[0] && rd_d[0] && sa_d[0] && func_d[8];
    wire op_jalr    = op_d[0] && rt_d[0] && sa_d[0] && func_d[9];
    wire op_syscall = op_d[0] && func_d[12];
    wire op_break   = op_d[0] && func_d[13];
    wire op_mfhi    = op_d[0] && rs_d[0] && rt_d[0] && sa_d[0] && func_d[16];
    wire op_mthi    = op_d[0] && rt_d[0] && rd_d[0] && sa_d[0] && func_d[17];
    wire op_mflo    = op_d[0] && rs_d[0] && rt_d[0] && sa_d[0] && func_d[18];
    wire op_mtlo    = op_d[0] && rt_d[0] && rd_d[0] && sa_d[0] && func_d[19];
    wire op_mult    = op_d[0] && rd_d[0] && sa_d[0] && func_d[24];
    wire op_multu   = op_d[0] && rd_d[0] && sa_d[0] && func_d[25];
    wire op_div     = op_d[0] && rd_d[0] && sa_d[0] && func_d[26];
    wire op_divu    = op_d[0] && rd_d[0] && sa_d[0] && func_d[27];
    wire op_add     = op_d[0] && sa_d[0] && func_d[32];
    wire op_addu    = op_d[0] && sa_d[0] && func_d[33];
    wire op_sub     = op_d[0] && sa_d[0] && func_d[34];
    wire op_subu    = op_d[0] && sa_d[0] && func_d[35];
    wire op_and     = op_d[0] && sa_d[0] && func_d[36];
    wire op_or      = op_d[0] && sa_d[0] && func_d[37];
    wire op_xor     = op_d[0] && sa_d[0] && func_d[38];
    wire op_nor     = op_d[0] && sa_d[0] && func_d[39];
    wire op_slt     = op_d[0] && sa_d[0] && func_d[42];
    wire op_sltu    = op_d[0] && sa_d[0] && func_d[43];
    wire op_bltz    = op_d[1] && rt_d[0];
    wire op_bgez    = op_d[1] && rt_d[1];
    wire op_bltzal  = op_d[1] && rt_d[16];
    wire op_bgezal  = op_d[1] && rt_d[17];
    wire op_j       = op_d[2];
    wire op_jal     = op_d[3];
    wire op_beq     = op_d[4];
    wire op_bne     = op_d[5];
    wire op_blez    = op_d[6] && rt_d[0];
    wire op_bgtz    = op_d[7] && rt_d[0];
    wire op_addi    = op_d[8];
    wire op_addiu   = op_d[9];
    wire op_slti    = op_d[10];
    wire op_sltiu   = op_d[11];
    wire op_andi    = op_d[12];
    wire op_ori     = op_d[13];
    wire op_xori    = op_d[14];
    wire op_lui     = op_d[15];
    wire op_mfc0    = op_d[16] && rs_d[0] && sa_d[0] && id_inst[5:3] == 3'b0;
    wire op_mtc0    = op_d[16] && rs_d[4] && sa_d[0] && id_inst[5:3] == 3'b0;
    wire op_tlbr    = op_d[16] && rs_d[16] && rt_d[0] && rd_d[0] && sa_d[0] && func_d[1]; //TODO: tlb
    wire op_tlbwi   = op_d[16] && rs_d[16] && rt_d[0] && rd_d[0] && sa_d[0] && func_d[2];
    wire op_tlbp    = op_d[16] && rs_d[16] && rt_d[0] && rd_d[0] && sa_d[0] && func_d[8];
    wire op_eret    = op_d[16] && rs_d[16] && rt_d[0] && rd_d[0] && sa_d[0] && func_d[24];
    wire op_lb      = op_d[32];
    wire op_lh      = op_d[33];
    wire op_lw      = op_d[35];
    wire op_lbu     = op_d[36];
    wire op_lhu     = op_d[37];
    wire op_sb      = op_d[40];
    wire op_sh      = op_d[41];
    wire op_sw      = op_d[43];
    wire op_cache   = op_d[47];

    assign al       =   op_jal || op_jalr || op_bltzal || op_bgezal;

    assign rs_ren   =   rscode != 5'h0 && ((SPEC && !op_sll && !op_sra && !op_srl) || imm || b_r);
    assign rt_ren   =   rtcode != 5'h0 && (SPEC || op_mtc0 || op_beq || op_bne || (|data_wen));

    // * 
    assign func     =   op_addi ? `ADD  :
                        op_slti ? `SLT  :
                        op_sltiu? `SLTU :
                        op_andi ? `AND  :
                        op_ori  ? `OR   :
                        op_xori ? `XOR  : `ADDU;

    // spec use func of inst
    assign SPEC     =   id_inst && opcode == `SPEC && !op_jr && !op_jalr && !op_syscall && !op_break;  // opcode = 0 and not JR,JALR,BREAK,SYSCALL

    assign load     =   op_lb || op_lh || op_lw || op_lbu || op_lhu;
    assign loadX    =   !op_lbu && !op_lhu;
    assign lsV      =   {3'b000, op_lb || op_lbu || op_sb} | {2'b00, {2{op_lh || op_lhu || op_sh}}} | {4{op_lw || op_sw}};

    assign imm      =   op_addi || op_addiu || op_slti || op_sltiu || op_andi || op_ori || op_xori || op_lui || data_en;

    wire[1:0] Xtype =   op_lui ? 2'b11:                                 // {imm, 16{0}}
                        op_andi || op_ori || op_xori ? 2'b00 :          // zero extend
                        2'b01;                                          // signed ex

    assign Imm      =   Xtype == 2'b00 ? {16'b0, `GET_Imm(id_inst)}           :   // zero extend
                        Xtype == 2'b01 ? {{16{id_inst[15]}}, `GET_Imm(id_inst)} : // signed extend
                        {`GET_Imm(id_inst), 16'b0};

    assign regwen   =   !(|hilowen) && (al || (imm && !(|data_wen)) || SPEC || op_mfc0);

    assign wreg     =   SPEC || op_jalr ? rdcode :
                        al ? 6'd31 :
                        ((imm && !(|data_wen)) || op_mfc0) ? rtcode : 6'd0;

    assign data_en  =   load || (|data_wen);

    assign data_ren =   op_lb || op_lbu ? 4'b0001 :
                        op_lh || op_lhu ? 4'b0011 :
                        op_lw           ? 4'b1111 : 4'b0;

    assign data_wen =   {3'b000, op_sb} | {2'b00, {2{op_sh}}} | {4{op_sw}};
    assign data_wren=   data_wen | data_ren;

    assign mult     =   op_mult || op_multu;
    assign div      =   op_div || op_divu;
    assign mdsign   =   op_mult || op_div;

    assign hiloren  =   {op_mfhi, op_mflo};

    assign hilowen  =   op_mult || op_multu || op_div || op_divu ? 2'b11 : {op_mthi, op_mtlo};

    assign cp0ren   =   op_mfc0;
    assign cp0wen   =   op_mtc0;
    assign cp0addr  =   {rdcode, selcode};


    // * ex
    assign  eret         = op_eret;
    wire    ReservedIns  = ~|{`DECODED_OPS};// ReservedInstruction Ex 
    wire    BreakEx      = op_break;        // Break point Ex
    wire    SyscallEx    = op_syscall;      // System call Ex
    // *                    取指地址错       保留指令  Overflow  陷阱例外 系统调用   访存地址错
    assign  id_ex        = {id_addr_error, ReservedIns, 1'b0, BreakEx, SyscallEx, 1'b0};

endmodule