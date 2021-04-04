/*
    @Copyright HIT team
    The definition of the parameters
*/
`ifndef PARAMETERS_DECODER_VH
//Formats of instruction
`define IR_OP               31:26
`define IR_RS               25:21
`define IR_RT               20:16
`define IR_RD               15:11
`define IR_FUNC             5:0
`define IR_IMM              15:0
`define IR_JIMM             25:0
`define IR_SA               10:6
`define IR_SEL              2:0
//Split the upper 3 bits of function code(HIGH:5:3) out,used to match the format of the mtc0/mfc0 instruction
`define FUNC_HI             5:3//uesd to check whether 5 to 3 bits of MFC0/MTC0 instruction are 0
//Fixed field value of instruction
`define RT_BGEZ             5'b00001//The fixed RT register address(5'b00001) required by the BGEZ instruction
`define RT_BGEZAL           5'b10001//The fixed RT register address(5'b10001) required by the BGEZAL instruction
`define RT_BLTZAL           5'b10000//The fixed RT register address(5'b10000) required by the BLTZAL instruction
`define INS_ERET            32'b01000010000000000000000000011000//The fixed instruction format required by the ERET instruction
`define RS_MTC0             5'b00100
//Write-back register address of link instruction
`define R31                 5'b11111
`endif