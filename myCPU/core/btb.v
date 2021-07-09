`timescale 1ns/100ps
`include "./head.vh"

// * 一般的BTB只有成功的分支才存
// * 该BTB存储分支，非成功也存其目的地址
// * 是否take交给gshare判断
module btb(
    input           clk,
    input           resetn,
    // * write
    input               wen,            // * 更新表项
    input [`BTB_BITS]   index_w,        // * 写的index位置
    input [31:0]        pc_w,           // * 写入的pc
    input [31:0]        target_w,       // * 目标地址
    
    // * read
    input [31:0]        pc_r,             // * 用于索引
    input [`GHR_BITS]   ghr,
    output              hit_r,
    output [`BTB_BITS]  index_r,
    output [31:0]       target_r        // * 跳转目的
);

    reg [31:0]  dest[`BTB_ENTRY_BITS];  // 目的地址
    reg [31:0]  tag[`BTB_ENTRY_BITS];   // pc, 相当于tag
    reg         valid[`BTB_ENTRY_BITS]; // 有效位

    wire index_rw_eq = index_w == index_r;
    assign index_r = pc_r[9:2] ^ ghr; // TODO maybe another way
    // // *                       正好读写入的  以及其他
    // assign hit_r = wen && index_rw_eq ? pc_r == pc_w : valid[index_r] && pc_r == tag[index_r];

    assign {hit_r, target_r} =  /*remove && index_rw_eq   ?   33'b0                                                   : */
                                wen && index_rw_eq      ?   {pc_r == pc_w, target_w}                           :
                                                            {valid[index_r] && pc_r == tag[index_r], dest[index_r]} ;
    integer i;
    always @(posedge clk) begin
        if(!resetn) begin
            for(i = 0; i < `BTB_NUMS; i = i+1) begin
                valid[i]        <= 1'b0;
                tag[index_w]    <= 32'd0;
                dest[index_w]   <= 32'd0;
            end
        end
        else if(wen) begin
            valid[index_w]  <= 1'b1;
            tag[index_w]    <= pc_w;
            dest[index_w]   <= target_w;
        end
    end

endmodule