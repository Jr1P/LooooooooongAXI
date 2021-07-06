`timescale 1ns/100ps
`include "./head.vh"
/**
! 在写之前如果又读同样位置，可能出错，这个发生的概率较小
! 而且写之前GHR没有更新，会导致之后很接近的分支语句的index定位到错误的index，这个如果branch跳转到branch就可能发生
**/
module gshare(
    input               clk,
    input               resetn,
    // *                预测的时候输入的pc
    input [`GHR_BITS]   pc_predict,
    // *                分支结果真正确定后写的index位置
    input               wen,        // * 写使能
    input [`GHR_BITS]   windex,
    input               take,       // * wen拉高时使用, 表示真正的分支方向(非预测)
    // * O
    output [`GHR_BITS]  rindex,     // * 预测时用index. 往下存到后面的流水线寄存器中, write的时候使用
    output              predict,     // * 预测的跳转方向
    output reg [7:0]    GHR
);

    // * state
    parameter Strongly_Take     = 2'b11;
    parameter Weakly_Take       = 2'b10;
    parameter Weakly_Not_Take   = 2'b01;
    parameter Strongly_Not_Take = 2'b00;

    // reg [`GHR_BITS] GHR;
    reg [1:0]       PHT[`PHT_BITS];
    // reg useless;
    assign rindex = GHR ^ pc_predict;

    integer i;
    always @(posedge clk) begin
        if(!resetn) begin
            for(i = 0; i < `PHT_NUMS; i = i+1) begin
                PHT[i] = Weakly_Take;
            end
            GHR <= `GHR_LEN'd0;
        end
        else if(wen) begin
            if(take && PHT[windex] != Strongly_Take) 
                PHT[windex]  <= PHT[windex]+2'd1;
            else if(!take && PHT[windex] != Strongly_Not_Take)
                PHT[windex]  <= PHT[windex]-2'd1;
            // * GHR 共八位
            GHR <= {GHR[6:0], take};
        end
    end

    assign predict = PHT[rindex][1];

endmodule