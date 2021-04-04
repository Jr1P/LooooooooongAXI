/*
    @Copyright HIT team
    The definition of the instrucitons
        including opcode and the funcode
*/
`ifndef INSTRUCTIONS_VH
`define OP_LEN   6//Length of operation code
`define FUN_LEN  6//Length of function code
`define ADDR_LEN 5//Length of address code
//----------I-Class Instructions----------
//-----Arithmetic Operation Instruction
`define ADDI        `OP_LEN'b001000
`define ADDIU       `OP_LEN'b001001
`define SLTI        `OP_LEN'b001010
`define SLTIU       `OP_LEN'b001011
//-----Logical Operation Instruction
`define ANDI        `OP_LEN'b001100
`define LUI         `OP_LEN'b001111
`define ORI         `OP_LEN'b001101
`define XORI        `OP_LEN'b001110
//-----Conditional Branch Instruction
//Operation Code
`define BEQ         `OP_LEN'b000100
`define BNE         `OP_LEN'b000101
`define BGTZ        `OP_LEN'b000111
`define BLEZ        `OP_LEN'b000110
`define BGEZ        `OP_LEN'b000001
`define BLTZ        `OP_LEN'b000001
`define BGEZAL      `OP_LEN'b000001
`define BLTZAL      `OP_LEN'b000001
//Address Code
`define ADDR_BGEZ   `ADDR_LEN'b00001
`define ADDR_BLTZ   `ADDR_LEN'b00000
`define ADDR_BGEZAL `ADDR_LEN'b10001
`define ADDR_BLTZAL `ADDR_LEN'b10000
//-----Likely Conditional Branch Instruction
`define BEQL        `OP_LEN'b010100
`define BGEZALL     `OP_LEN'b000001
`define BGEZL       `OP_LEN'b000001
`define BGTZL       `OP_LEN'b010111
`define BLEZL       `OP_LEN'b010110
`define BLTZALL     `OP_LEN'b000001
`define BLTZL       `OP_LEN'b000001
`define BNEL        `OP_LEN'b010101
//-----Memory Access Instruction
`define LB          `OP_LEN'b100000
`define LBU         `OP_LEN'b100100
`define LH          `OP_LEN'b100001
`define LHU         `OP_LEN'b100101
`define LW          `OP_LEN'b100011
`define SB          `OP_LEN'b101000
`define SH          `OP_LEN'b101001
`define SW          `OP_LEN'b101011
`define LL          `OP_LEN'b110000
`define SC          `OP_LEN'b111000
`define LWL         `OP_LEN'b100010
`define LWR         `OP_LEN'b100110
`define SWL         `OP_LEN'b101010
`define SWR         `OP_LEN'b101110
//----------R-Class Instructions----------
//-----Arithmetic Operation Instruction
//Operation Code
`define ADD         `OP_LEN'b000000
`define ADDU        `OP_LEN'b000000
`define SUB         `OP_LEN'b000000
`define SUBU        `OP_LEN'b000000
`define SLT         `OP_LEN'b000000
`define SLTU        `OP_LEN'b000000
`define DIV         `OP_LEN'b000000
`define DIVU        `OP_LEN'b000000
`define MULT        `OP_LEN'b000000
`define MULTU       `OP_LEN'b000000
`define MUL         `OP_LEN'b011100
`define MADD        `OP_LEN'b011100
`define MADDU       `OP_LEN'b011100
`define MSUB        `OP_LEN'b011100
`define MSUBU       `OP_LEN'b011100
//Function Code
`define FUN_ADD     `FUN_LEN'b100000
`define FUN_ADDU    `FUN_LEN'b100001
`define FUN_SUB     `FUN_LEN'b100010
`define FUN_SUBU    `FUN_LEN'b100011
`define FUN_SLT     `FUN_LEN'b101010
`define FUN_SLTU    `FUN_LEN'b101011
`define FUN_DIV     `FUN_LEN'b011010
`define FUN_DIVU    `FUN_LEN'b011011
`define FUN_MULT    `FUN_LEN'b011000
`define FUN_MULTU   `FUN_LEN'b011001
`define FUN_MUL     `FUN_LEN'b000010
`define FUN_MADD    `FUN_LEN'b000000
`define FUN_MADDU   `FUN_LEN'b000001
`define FUN_MSUB    `FUN_LEN'b000100
`define FUN_MSUBU   `FUN_LEN'b000101
//-----Logical Operation Instruction
//Operation Code
`define AND         `OP_LEN'b000000
`define NOR         `OP_LEN'b000000
`define OR          `OP_LEN'b000000
`define XOR         `OP_LEN'b000000
//Function Code
`define FUN_AND     `FUN_LEN'b100100
`define FUN_NOR     `FUN_LEN'b100111
`define FUN_OR      `FUN_LEN'b100101
`define FUN_XOR     `FUN_LEN'b100110
//-----Shift Operation Instruction
//Operation Code
`define SLLV        `OP_LEN'b000000
`define SLL         `OP_LEN'b000000
`define SRAV        `OP_LEN'b000000
`define SRA         `OP_LEN'b000000
`define SRLV        `OP_LEN'b000000
`define SRL         `OP_LEN'b000000
//Function Code
`define FUN_SLLV    `FUN_LEN'b000100
`define FUN_SLL     `FUN_LEN'b000000
`define FUN_SRAV    `FUN_LEN'b000111
`define FUN_SRA     `FUN_LEN'b000011
`define FUN_SRLV    `FUN_LEN'b000110
`define FUN_SRL     `FUN_LEN'b000010
//-----Conditional Branch Instruction
//Operation Code
`define JR          `OP_LEN'b000000
`define JALR        `OP_LEN'b000000
//Function Code
`define FUN_JR      `FUN_LEN'b001000
`define FUN_JALR    `FUN_LEN'b001001
//-----Data Movement Instruction
//Operation Code
`define MFHI        `OP_LEN'b000000
`define MFLO        `OP_LEN'b000000
`define MTHI        `OP_LEN'b000000
`define MTLO        `OP_LEN'b000000
`define MOVN        `OP_LEN'b000000
`define MOVZ        `OP_LEN'b000000
//Function Code
`define FUN_MFHI    `FUN_LEN'b010000
`define FUN_MFLO    `FUN_LEN'b010010
`define FUN_MTHI    `FUN_LEN'b010001
`define FUN_MTLO    `FUN_LEN'b010011
`define FUN_MOVN    `FUN_LEN'b001011
`define FUN_MOVZ    `FUN_LEN'b001010
//-----Self-trap Instruction
//Operation Code
`define BREAK       `OP_LEN'b000000
`define SYSCALL     `OP_LEN'b000000
`define TEQ         `OP_LEN'b000000
`define TEQI        `OP_LEN'b000001
`define TGE         `OP_LEN'b000000
`define TGEI        `OP_LEN'b000001
`define TGEIU       `OP_LEN'b000001
`define TGEU        `OP_LEN'b000000
`define TLT         `OP_LEN'b000000
`define TLTI        `OP_LEN'b000001
`define TLTIU       `OP_LEN'b000001
`define TLTU        `OP_LEN'b000000
`define TNE         `OP_LEN'b000000
`define TNEI        `OP_LEN'b000001
//Function Code
`define FUN_BREAK   `FUN_LEN'b001101
`define FUN_SYSCALL `FUN_LEN'b001100
`define FUN_TEQ     `FUN_LEN'b110100
`define FUN_TGE     `FUN_LEN'b110000
`define FUN_TGEU    `FUN_LEN'b110001
`define FUN_TLT     `FUN_LEN'b110010
`define FUN_TLTU    `FUN_LEN'b110011
`define FUN_TNE     `FUN_LEN'b110110
//----------J-Class Instructions----------

//-----Unconditional Branch Instruction
`define J           `OP_LEN'b000010
`define JAL         `OP_LEN'b000011

//----------Privileged Instructions----------
//Operation Code
`define ERET        `OP_LEN'b010000
`define MFC0        `OP_LEN'b010000
`define MTC0        `OP_LEN'b010000
`define PREF        `OP_LEN'b110011
`define SYNC        `OP_LEN'b000000
`define WAIT        `OP_LEN'b010000
//Function Code
`define FUN_SYNC    `FUN_LEN'b001111
`define FUN_WAIT    `FUN_LEN'b100000

//---------TLB Instructions----------
//Operation Code
`define TLBP        `OP_LEN'b010000
`define TLBR        `OP_LEN'b010000
`define TLBWI       `OP_LEN'b010000
`define TLBWR       `OP_LEN'b010000
//Function Code
`define FUN_TLBP    `FUN_LEN'b001000
`define FUN_TLBR    `FUN_LEN'b000001
`define FUN_TLBWI   `FUN_LEN'b000010
`define FUN_TLBWR   `FUN_LEN'b000110

//---------Count Instructions----------
//Operation Code
`define CLO         `OP_LEN'b011100
`define CLZ         `OP_LEN'b011100
//Function Code
`define FUN_CLO     `FUN_LEN'b100001
`define FUN_CLZ     `FUN_LEN'b100000

//---------Cache Instructions----------
`define CACHE       `OP_LEN'b101111



`endif