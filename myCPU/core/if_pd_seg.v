`timescale 1ns/1ps
`include "./head.vh"

module if_pd_seg(
    input   clk,
    input   resetn,

    input   stall,      // *暂停
    input   refresh,    // *刷新
    input   ex_af_bp_fail,  // * ex段及以后的预测失败

    input               id_j_r,
    input               pd_branch,  // 前一条指令是否为分支
    input               if_addr_error,
    input [31:0]        if_pc,
    input               if_inst_req,
    input               if_btb_hit,
    input [31:0]        if_btb_target,
    input [`BTB_BITS]   if_btb_index,
    input               if_gshare_take,
    input [`GHR_BITS]   if_gshare_index,
    
    // output reg              pd_pc_zero,
    output reg              empty,
    output reg              pd_bd,  // * branch delay slot
    output reg              pd_addr_error,
    output reg  [31:0]      pd_pc,
    output reg  [31:0]      pd_pc_8,
    output reg              pd_inst_req,
    output reg              pd_btb_hit,
    output reg  [31:0]      pd_btb_target,
    output reg  [`BTB_BITS] pd_btb_index,
    output reg              pd_gshare_take,
    output reg  [`GHR_BITS] pd_gshare_index,
    output reg              pd_inst_invalid,
    output reg              pd_fail_flushed
);

always @(posedge clk) begin
    pd_inst_invalid <= (!resetn || refresh) || (stall && pd_inst_invalid);
end

always @(posedge clk) begin
    pd_fail_flushed <= ex_af_bp_fail; // * 因为失败时的刷新只会在
end

always @(posedge clk) begin
    if(!resetn || refresh) begin
        empty           <= 1'b0;
        pd_bd           <= 1'b0;
        pd_addr_error   <= 1'b0;
        pd_pc           <= 32'b0;
        pd_inst_req     <= 1'b0;
        pd_btb_hit      <= 1'b0;
        pd_btb_target   <= 32'h0;
        pd_btb_index    <= `BTB_LEN'h0;
        pd_gshare_take  <= 1'b0;
        pd_gshare_index <= `GHR_LEN'h0;
    end
    else if(!stall) begin
        empty           <= id_j_r;
        pd_bd           <= pd_branch;
        pd_addr_error   <= if_addr_error;
        pd_pc           <= if_pc;
        pd_pc_8         <= if_pc+32'd8;
        pd_inst_req     <= if_inst_req;
        pd_btb_hit      <= if_btb_hit;
        pd_btb_target   <= if_btb_target;
        pd_btb_index    <= if_btb_index;
        pd_gshare_take  <= if_gshare_take;
        pd_gshare_index <= if_gshare_index;
    end
end

endmodule