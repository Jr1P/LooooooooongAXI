`timescale 1ns/1ps

// * register file
// * posedge write GPRs
module regfile(
    input           clk,
    input           resetn,

    input [4 :0]    rs,
    input [4 :0]    rt,

    input           wen,    // write engine
    input [4 :0]    wreg,   // the register to be written
    input [31:0]    wdata,  // the data to be written to wreg

    output[31:0]    outA,
    output[31:0]    outB
);

    reg [31:0] GPR[31:1];

    always @(posedge clk) if(wen) GPR[wreg] <= wdata;

    assign outA = !rs ? 32'b0 : (wen && wreg == rs) ? wdata : GPR[rs];
    assign outB = !rt ? 32'b0 : (wen && wreg == rt) ? wdata : GPR[rt];

endmodule