// * function code
`define SLL     6'b000000
`define SRL     6'b000010
`define SRA     6'b000011
`define SLLV    6'b000100
`define SRLV    6'b000110
`define SRAV    6'b000111
`define MFHI    6'b010000
`define MTHI    6'b010001
`define MFLO    6'b010010
`define MTLO    6'b010011
`define MULT    6'b011000
`define MULTU   6'b011001
`define DIV     6'b011010
`define DIVU    6'b011011
`define ADD     6'b100000
`define ADDU    6'b100001
`define SUB     6'b100010
`define SUBU    6'b100011
`define AND     6'b100100
`define OR      6'b100101
`define XOR     6'b100110
`define NOR     6'b100111
`define SLT     6'b101010
`define SLTU    6'b101011

// `define SYSCALL 6'b001100
// `define BREAK   6'b001101

// `define JR      6'b001000
// `define JALR    6'b001001

// *------------------

`define ERET    32'h4200_0018

// * opcode
`define SPEC    6'b000000
// `define JR_JALR 6'b000000
// `define BGEZ_BLTZ_BGEZAL_BLTZAL     6'b000001
`define J       6'b000010
`define JAL     6'b000011
`define BEQ     6'b000100
`define BNE     6'b000101
`define BLEZ    6'b000110
`define BGTZ    6'b000111

`define ADDI    6'b001000
// `define ADDIU   6'b001001
// `define SLTI    6'b001010
// `define SLTIU   6'b001011
`define ANDI    6'b001100
// `define ORI     6'b001101
`define XORI    6'b001110
`define LUI     6'b001111

`define LB      6'b100000
`define LH      6'b100001
`define LW      6'b100011
`define LBU     6'b100100
`define LHU     6'b100101
`define SB      6'b101000
`define SH      6'b101001
`define SW      6'b101011

`define PRI     6'b010000   // * PRI means Privileged Instruction

// *------------------

// * rt code just for BGEZ_BLTZ_BGEZAL_BLTZAL
`define BLTZ    5'b00000
`define BGEZ    5'b00001
`define BLTZAL  5'b10000
`define BGEZAL  5'b10001

// * rs code just for PRI
// `define MFC0    5'b00000
// `define MTC0    5'b00100

// * ExcCode
`define EXC_INT     5'h00
`define EXC_AdEL    5'h04
`define EXC_AdES    5'h05
`define EXC_Sys     5'h08
`define EXC_Bp      5'h09
`define EXC_RI      5'h0a
`define EXC_Ov      5'h0c

// *    cp0 regs        8'b  Reg_Sel    (Reg, Sel)
`define CP0_Index       8'b00000_000    //* (0, 0)
`define CP0_Random      8'b00001_000    //* (1, 0)
`define CP0_EntryLo0    8'b00010_000    //* (2, 0)
`define CP0_EntryLo1    8'b00011_000    //* (3, 0)
`define CP0_Context     8'b00100_000    //* (4, 0)
`define CP0_PageMask    8'b00101_000    //* (5, 0)
`define CP0_Wired       8'b00110_000    //* (6, 0)
`define CP0_BadVAddr    8'b01000_000    //* (8, 0)
`define CP0_Count       8'b01001_000    //* (9, 0)
`define CP0_EntryHi     8'b01010_000    //* (10, 0)
`define CP0_Compare     8'b01011_000    //* (11, 0)
`define CP0_Status      8'b01100_000    //* (12, 0)
`define CP0_Cause       8'b01101_000    //* (13, 0)
`define CP0_EPC         8'b01110_000    //* (14, 0)
`define CP0_Config0     8'b10000_000    //* (16, 0)
`define CP0_Config1     8'b10000_001    //* (16, 1)

`define CP0ADDR     7:0
`define NUM_EX      6
`define NUM_EX_1    5
`define EXBITS      `NUM_EX_1:0

// * Index (4, 0)
`define Index_LenIndex 8
`define Index_IndexBITs `Index_LenIndex-1:0
`define TLB_SIZE 6'd63

// * Status (12, 0)
`define Status_Bev  22
`define Status_IM   15:8
`define Status_EXL  1
`define Status_IE   0

// * Cause (13, 0)
`define Cause_IP_SOFTWARE   9:8

// * Config (16, 0)
`define Config0_k0  2:0

// *------------------
`define GET_OP(x)   x[31:26]
`define GET_Rs(x)   x[25:21]
`define GET_Rt(x)   x[20:16]
`define GET_Rd(x)   x[15:11]
`define GET_Imm(x)  x[15: 0]
`define GET_SA(x)   x[10: 6]
`define GET_FUNC(x) x[5 : 0]
`define GET_SEL(x)  x[2 : 0]

`define LDEC    57
`define DECBITS `LDEC-1:0

`define DECODED_OPS \
    op_sll, op_srl, op_sra, op_sllv, op_srlv, op_srav, op_jr, op_jalr, op_syscall, \
    op_break, op_mfhi, op_mthi, op_mflo, op_mtlo, op_mult, op_multu, op_div, op_divu, op_add, \
    op_addu, op_sub, op_subu, op_and, op_or, op_xor, op_nor, op_slt, op_sltu, op_bltz, op_bgez, \
    op_bltzal, op_bgezal, op_j, op_jal, op_beq, op_bne, op_blez, op_bgtz, op_addi, op_addiu, op_slti, \
    op_sltiu, op_andi, op_ori, op_xori, op_lui, op_mfc0, op_mtc0, op_eret, op_lb, op_lh, op_lw, op_lbu, \
    op_lhu, op_sb, op_sh, op_sw



// * Gshare
`define GHR_LEN 8
`define GHR_BITS `GHR_LEN-1:0
`define PHT_NUMS (1 << `GHR_LEN)
`define PHT_BITS `PHT_NUMS-1:0

// * BTB
`define BTB_LEN 8
`define BTB_BITS `BTB_LEN-1:0
`define BTB_NUMS (1 << `BTB_LEN)
`define BTB_ENTRY_BITS `BTB_NUMS-1:0