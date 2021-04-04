/*
    @Copyright HIT team
    The definition of the parameters in ALU
*/
`define AL_ADD    0
`define AL_SUB    1
`define AL_SLT    2
`define AL_AND    3
`define AL_NOR    4
`define AL_OR     5
`define AL_XOR    6
`define AL_SLL    7
`define AL_SRA    8
`define AL_SRL    9
`define AL_SLLV   10
`define AL_SRAV   11
`define AL_SRLV   12
`define AL_LUI    13
`define AL_TOTAL  14

`define  N(n)  [(n)-1:0]


/* ALU_DIV */
// /**
//  *  Use binary Gray code to encode the states of the FSM
//  *  (finite state machine) to reduce the use of logic units.
//  */
// `define STATE_LEN 2     // Both div and mult
// `define RST       `STATE_LEN'b00
// `define INIT      `STATE_LEN'b01
// `define RUNNING   `STATE_LEN'b11
// `define OVER      `STATE_LEN'b10
`define DIVIDER divider

/* ALU_MULT */
`define MULTIPLIER multiplier_gen_4
