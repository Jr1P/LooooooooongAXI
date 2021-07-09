`timescale 1ns/100ps

// *TODO 中断目的地址变化
`define EXEC_ADDR   32'hbfc0_0380
`define RESET_ADDR  32'hbfc0_0000
module pc(
    input       clk,
    input       resetn,

    input               inst_bank_valid,
    input               pd_id_stall,
    // input               if_pd_stall,
    input               stall,          // 1: pipeline stalled
    input               branch_stall,   // branch与后续指令数据相关导致的stall 

    // * 判断延迟槽
    input               id_j_r,     // j_r需特殊判断
    input               pd_bd,
    input               inst_addr_ok,
    input               BranchPredict,  // 1: take, 0: not take
    input       [31:0]  BranchTarget,   // target address of prediction

    input               PredictFailed,  // predict failed
    input       [31:0]  realTarget,

    input               exc_oc,         // 1: exception occur, 0: not

    input               eret,           // eret指令
    input       [31:0]  epc,
    output reg  [31:0]  npc
);

    reg delay_slot_fetched;
    reg jumped;
    // * 可以跳转了       j_r                 其他                              暂停后延迟槽取出          后面流水段可以传递              
    wire can_jump = ((delay_slot_fetched || (id_j_r && pd_bd || inst_addr_ok)) && BranchPredict /*|| */) && !pd_id_stall && !branch_stall && !jumped;
    always @(posedge clk) begin
        if(!resetn)
            jumped <= 1'b0;
        else if(!eret && !exc_oc && !PredictFailed) begin
            if(can_jump)
                jumped <= 1'b1;
            else
                jumped <= 1'b0;
        end
        else if (stall)
            jumped <= jumped;
        else
            jumped <= 1'b0;
    end

    // // * 表示延迟槽的地址请求是否已被接收
    always @(posedge clk) begin
        if(!resetn || PredictFailed || exc_oc || eret)
            delay_slot_fetched  <= 1'b0;
        else if(BranchPredict) begin
            if(id_j_r)
                delay_slot_fetched  <= delay_slot_fetched || pd_bd;
            else  
                delay_slot_fetched  <= delay_slot_fetched || inst_addr_ok;
        end 
        else
            delay_slot_fetched <= 1'b0;
    end

    always @(posedge clk) begin
        if(!resetn)             npc <=  `RESET_ADDR ;
        else if(eret)           npc <=  epc         ;
        else if(exc_oc)         npc <=  `EXEC_ADDR  ;
        else if(PredictFailed)  npc <=  realTarget  ;
        // *   (inst_addr_ok || addr_oked)
            // *非 (如果bank有内容 且 没法写到下一级 )
            // *即   bank 空    或者    可以往下写
        // else if(!(inst_bank_valid && pd_id_stall) && !jumped && BranchPredict)  npc <=  BranchTarget;
        else if(can_jump)       npc <=  BranchTarget;
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