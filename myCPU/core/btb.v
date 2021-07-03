`timescale 1ns/100ps
`include "./head.vh"

module btb(
    input           clk,
    input           resetn,
    // * write
    input               wen,            // * 更新表项
    input               remove,         // * 错误时的删除
    input [`BTB_BITS]   index_w,        // * 写的index位置
    input               un_j_w,         // * unconditional jump
    input [31:0]        pc_w,           // * 写入的pc
    input [31:0]        target_w,       // * 目标地址
    
    // * read
    input [31:0]        pc_r,             // * 用于索引
    output              un_j_r,
    output              hit_r,
    output [`BTB_BITS]  index_r,
    output [31:0]       target_r        // * 跳转目的
);

    reg [31:0]  dest[`BTB_ENTRY_BITS];  // 目的地址
    reg [31:0]  tag[`BTB_ENTRY_BITS];   // pc, 相当于tag
    reg         j[`BTB_ENTRY_BITS];     // 是否为非条件跳转
    reg         valid[`BTB_ENTRY_BITS]; // 有效位

    wire index_rw_eq = index_w == index_r;
    assign index_r = pc_r[11:2];
    // *                       正好读要删除的 . 正好读写入的  以及其他
    assign {hit_r, target_r} =  remove && index_rw_eq   ?   33'b0                                                   : 
                                wen && index_rw_eq      ?   {pc_r == pc_w, dest[index_r]}                           :
                                                            {valid[index_r] && pc_r == tag[index_r], dest[index_r]} ;
    assign un_j_r = j[index_r];

    integer i;
    always @(posedge clk) begin
        if(!resetn) begin
            for(i = 0; i < `BTB_NUMS; i = i+1) begin
                valid[i] <= 1'b0;
            end
        end
        else if(wen) begin
            valid[index_w]  <= 1'b1;
            j[index_w]      <= un_j_w;
            tag[index_w]    <= pc_w;
            dest[index_w]   <= target_w;
        end
        else if(remove) begin
            valid[index_w]  <= 1'b0;
            j[index_w]      <= 1'b0;
            tag[index_w]    <= 32'h0;
            dest[index_w]   <= 32'h0;
        end
    end

endmodule