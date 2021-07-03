`timescale 1ns/1ps

`define EXEC_ADDR   32'hbfc0_0380
`define RESET_ADDR  32'hbfc0_0000
module pc(
    input       clk,
    input       resetn,

    input               stall,          // 1: pipeline stalled

    input               BranchPredict,  // 1: take, 0: not take
    input       [31:0]  BranchTarget,   // target address of prediction

    input               PredictFailed,  // predict failed
    input       [31:0]  realTarget,

    input               exc_oc,         // 1: exception occur, 0: not

    input               eret,           // eret指令
    input       [31:0]  epc,
    output reg  [31:0]  npc
);

    always @(posedge clk) begin
        if(!resetn)             npc <=  `RESET_ADDR ;
        else if(eret)           npc <=  epc         ;
        else if(exc_oc)         npc <=  `EXEC_ADDR  ;
        else if(stall)                              ;
        else if(PredictFailed)  npc <=  realTarget  ;
        else if(BranchPredict)  npc <=  BranchTarget;
        else                    npc <=  npc+32'd4   ;
    end

endmodule