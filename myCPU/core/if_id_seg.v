`timescale 1ns/1ps
`include "./head.vh"

module if_id_seg(
    input   clk,
    input   resetn,

    input   stall,      // *暂停
    input   refresh,    // *刷新

    input               id_branch,  // 前一条指令是否为分支
    input               if_addr_error,
    input [31:0]        if_pc,
    input               if_inst_req,
    input               if_btb_hit,
    input [31:0]        if_btb_target,
    input [`BTB_BITS]   if_btb_index,
    input               if_gshare_take,
    input [`GHR_BITS]   if_gshare_index,
    
    output reg              id_bd,  // * branch delay slot
    output reg              id_addr_error,
    output reg  [31:0]      id_pc,
    output reg              id_inst_req,
    output reg              id_btb_hit,
    output reg  [31:0]      id_btb_target,
    output reg  [`BTB_BITS] id_btb_index,
    output reg              id_gshare_take,
    output reg  [`GHR_BITS] id_gshare_index
);

always @(posedge clk) begin
    if(!resetn)
        id_inst_req     <= 1'b0;
    else if(!stall)
        id_inst_req     <= if_inst_req;
end

always @(posedge clk) begin
    if(!resetn || refresh) begin
        id_bd           <= 1'b0;
        id_addr_error   <= 1'b0;
        id_pc           <= 32'b0;
        id_btb_hit      <= 1'b0;
        id_btb_target   <= 32'h0;
        id_btb_index    <= `BTB_LEN'h0;
        id_gshare_take  <= 1'b0;
        id_gshare_index <= `GHR_LEN'h0;
    end
    else if(!stall) begin
        id_bd           <= id_branch;
        id_addr_error   <= if_addr_error;
        id_pc           <= if_pc;
        id_btb_hit      <= if_btb_hit;
        id_btb_target   <= if_btb_target;
        id_btb_index    <= if_btb_index;
        id_gshare_take  <= if_gshare_take;
        id_gshare_index <= if_gshare_index;
    end
end

endmodule