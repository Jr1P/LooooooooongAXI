`timescale 1ns/100ps

// *TODO 中断目的地址变化
`define EXEC_ADDR   32'hbfc0_0380
`define RESET_ADDR  32'hbfc0_0000
module pc(
    input       clk,
    input       resetn,

    input               inst_bank_valid,
    input               pd_id_stall,
    input               stall,          // 1: pipeline stalled
    input               branch_stall,   // branch与后续指令数据相关导致的stall 

    // input               inst_addr_ok,
    input               BranchPredict,  // 1: take, 0: not take
    input       [31:0]  BranchTarget,   // target address of prediction

    input               PredictFailed,  // predict failed
    input       [31:0]  realTarget,

    input               exc_oc,         // 1: exception occur, 0: not

    input               eret,           // eret指令
    input       [31:0]  epc,
    output reg  [31:0]  npc
);

    reg jumped, addr_oked;
    always @(posedge clk) begin
        if(!resetn)
            jumped <= 1'b0;
        else if(!eret && !exc_oc && !PredictFailed && BranchPredict && !branch_stall && !jumped)
            jumped <= 1'b1;
        else if (stall)
            jumped <= jumped;
        else
            jumped <= 1'b0;
    end

    // always @(posedge clk) begin
    //     if(!resetn) addr_oked <= 1'b0;
    //     else        addr_oked <= inst_addr_ok || (stall && addr_oked);
    // end

    always @(posedge clk) begin
        if(!resetn)             npc <=  `RESET_ADDR ;
        else if(eret)           npc <=  epc         ;
        else if(exc_oc)         npc <=  `EXEC_ADDR  ;
        else if(PredictFailed)  npc <=  realTarget  ;
        // *   (inst_addr_ok || addr_oked)
            // *非 (如果bank有内容 且 没法写到下一级 )
            // *即   bank 空    或者    可以往下写
        else if(!(inst_bank_valid && pd_id_stall) && !jumped && BranchPredict)  npc <=  BranchTarget;
        else if(stall)          npc <=  npc         ;
        else                    npc <=  npc+32'd4   ;
    end

    // always @(posedge clk) begin
    //     if(!resetn)         npc <=  `RESET_ADDR ;
    //     else if(eret)       npc <=  epc         ;
    //     else if(exc_oc)     npc <=  `EXEC_ADDR  ;
    //     else if(stall)      npc <=  npc         ;
    //     else if(BranchTake) npc <=  BranchTarget;
    //     else                npc <=  npc+32'd4   ;
    // end

endmodule