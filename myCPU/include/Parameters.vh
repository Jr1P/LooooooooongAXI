/*
    @Copyright HIT team
    The definition of the parameters
*/
`ifndef PARAMETERS_VH
//Parameters Of Data
`define BIT 1//Length of bit
`define B   8//Length of byte
`define HW  16//Length of halfword
`define W   32//Length of word
//Parameters Of Mode (Will be defined in the register cp0)
`define ENDIAN_MODE    0//Mode of endian:  1->big endian : 0->small endian(default little endian mode)
`define OPERATION_MODE 1//Mode of operation: 1->kernel mode : 0->user mode(default kernel mode)
//Parameters Of Instructions
`define INS_LEN  32//Length of instruction,the same length as a word
`define OP_LEN   6//Length of option code
`define FUN_LEN  6//Length of function code
`define ADDR_LEN 5//Length of address code
`define IMM_LEN  16//Length of i-class immediate operand
`define JIMM_LEN 26//Length of j-class immediate operand
//Parameters Of Register
`define PC_WIDTH  32
`define REG_WIDTH 32
`define GPRS_NUM  32
//Parameters Of Cpu
`define STAT_NUM  5
//Parameters Of CP0
`define PC_LEN 32



`endif