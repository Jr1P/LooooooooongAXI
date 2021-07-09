`timescale 1ns/100ps
`include "./head.vh"
// * pd id 段 TODO
module pd_id_seg (
    input           resetn,
    input           clk,

    input           stall,
    input           refresh,
    input           ec_bp_fail,

    input               pd_addr_error,
    input [31:0]        pd_pc,
    input [31:0]        pd_pc_8,
    input [31:0]        pd_inst,
    input               pd_bd,
    input               pd_branch,
    input               pd_b,
    input               pd_j_dir,
    input               pd_j_r,
    input               pd_b_rs_ren,
    input               pd_b_rt_ren,
    
    input               pd_btb_wen,
    input [`BTB_BITS]   pd_btb_windex,
    input [31:0]        pd_btb_wtarget,

    input               pd_gshare_wen,
    input [`GHR_BITS]   pd_gshare_windex,
    input               pd_bp_take,

    input               pd_op_bltz,
    input               pd_op_bgez,
    input               pd_op_beq,
    input               pd_op_bne,
    input               pd_op_blez,
    input               pd_op_bgtz,
    // * O
    output reg                  id_addr_error,
    output reg [31:0]           id_pc,
    output reg [31:0]           id_pc_8,
    output reg [31:0]           id_inst,
    output reg                  id_bd,
    output reg                  id_branch,
    output reg                  id_b,
    output reg                  id_j_dir,
    output reg                  id_j_r,
    output reg                  id_b_rs_ren,
    output reg                  id_b_rt_ren,
    
    output reg                  id_btb_wen,
    output reg [`BTB_BITS]      id_btb_windex,
    output reg [31:0]           id_btb_wtarget,

    output reg                  id_gshare_wen,
    output reg [`GHR_BITS]      id_gshare_windex,
    output reg                  id_bp_take,

    output reg                  id_op_bltz,
    output reg                  id_op_bgez,
    output reg                  id_op_beq,
    output reg                  id_op_bne,
    output reg                  id_op_blez,
    output reg                  id_op_bgtz,
    output reg                  id_fail_flushed
);

    always @(posedge clk) begin
        id_fail_flushed <= ec_bp_fail;
    end

    always @(posedge clk) begin
        if(!resetn || refresh) begin
            id_addr_error   <= 1'b0;
            id_pc           <= 32'd0;
            id_pc_8         <= 32'd0;
            id_inst         <= 32'd0;
            id_bd           <= 1'b0;
            id_branch       <= 1'b0;
            id_b            <= 1'b0;
            id_j_dir        <= 1'b0;
            id_j_r          <= 1'b0;
            id_b_rs_ren     <= 1'b0;
            id_b_rt_ren     <= 1'b0;
            id_btb_wen      <= 1'b0;
            id_btb_windex   <= `BTB_LEN'd0;
            id_btb_wtarget  <= 32'd0;
            id_gshare_wen   <= 1'b0;
            id_gshare_windex<= `GHR_LEN'd0;
            id_bp_take      <= 1'b0;
            id_op_bltz      <= 1'b0;
            id_op_bgez      <= 1'b0;
            id_op_beq       <= 1'b0;
            id_op_bne       <= 1'b0;
            id_op_blez      <= 1'b0;
            id_op_bgtz      <= 1'b0;
        end
        else if(!stall) begin
            id_addr_error   <= pd_addr_error;
            id_pc           <= pd_pc;
            id_pc_8         <= pd_pc_8;
            id_inst         <= pd_inst;
            id_bd           <= pd_bd;
            id_branch       <= pd_branch;
            id_b            <= pd_b;
            id_j_dir        <= pd_j_dir;
            id_j_r          <= pd_j_r;
            id_b_rs_ren     <= pd_b_rs_ren;
            id_b_rt_ren     <= pd_b_rt_ren;
            id_btb_wen      <= pd_btb_wen;
            id_btb_windex   <= pd_btb_windex;
            id_btb_wtarget  <= pd_btb_wtarget;
            id_gshare_wen   <= pd_gshare_wen;
            id_gshare_windex<= pd_gshare_windex;
            id_bp_take      <= pd_bp_take;
            id_op_bltz      <= pd_op_bltz;
            id_op_bgez      <= pd_op_bgez;
            id_op_beq       <= pd_op_beq;
            id_op_bne       <= pd_op_bne;
            id_op_blez      <= pd_op_blez;
            id_op_bgtz      <= pd_op_bgtz;
        end
    end
    
endmodule