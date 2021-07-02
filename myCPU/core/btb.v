`timescale 1ns/100ps

`define BTB_INDEX_LEN 10
`define BTB_INDEX_BITS `BTB_INDEX_LEN-1:0
`define PHT_BITS    (1<<`BTB_INDEX_LEN-1):0
module btb(
    input [`BTB_INDEX_BITS] index,

    output                  take,   // btb预测是否跳转
    output [31:0]           target  // 跳转目的
);

    reg [1:0]  pht[`PHT_BITS];   // bimodal


endmodule