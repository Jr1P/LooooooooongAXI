`timescale 1ns/100ps
`include "head.vh"

module id_ex_seg (
    input   clk,
    input   resetn,

    input       stall,
    input       refresh,

    input           wb_regwen,
    input [4 :0]    wb_wreg,
    input [31:0]    wb_reorder_data,

    input [`EXBITS] id_ex,

    input           id_empty,
    input [31:0]    id_pc,
    input [31:0]    id_pc_8,
    input [31:0]    id_inst,
    input           id_imm,
    input [31:0]    id_Imm,
    input [31:0]    id_A,           // GPR[rs]
    input [31:0]    id_B,           // GPR[rt]
    input           id_rs_ren,
    input           id_rt_ren,
    input           id_al,
    input           id_SPEC,
    input           id_load,
    input           id_loadX,
    input [3 :0]    id_lsV,
    input           id_branch,
    input           id_j_r,
    input           id_bd,
    input [5 :0]    id_ifunc,      // use for I type
    input           id_regwen,
    input [4 :0]    id_wreg,
    input           id_data_en,
    input [3 :0]    id_data_ren,
    input [3 :0]    id_data_wen,
    input [3 :0]    id_data_wren,
    input           id_eret,
    input           id_cp0ren,
    input           id_cp0wen,
    input [7 :0]    id_cp0addr,
    input           id_mult,
    input           id_div,
    input           id_mdsign,
    input [1 :0]    id_hiloren,
    input [1 :0]    id_hilowen,

    input           id_btb_wen,
    input[`BTB_BITS]id_btb_windex,
    input [31:0]    id_btb_wtarget,
    
    input           id_gshare_wen,
    input[`GHR_BITS]id_gshare_windex,
    input           id_bp_take,

    input           id_op_bltz,
    input           id_op_bgez,
    input           id_op_beq,
    input           id_op_bne,
    input           id_op_blez,
    input           id_op_bgtz,
    input [1:0]     id_wait_seg,

    output reg              ex_empty,
    output reg [`EXBITS]    ex_ex,
    output reg [31:0]       ex_pc,
    output reg [31:0]       ex_pc_8,
    output reg [31:0]       ex_inst,
    output reg              ex_imm,
    output reg [31:0]       ex_Imm,
    output reg [31:0]       ex_A,
    output reg [31:0]       ex_B,
    output reg              ex_rs_ren,
    output reg              ex_rt_ren,
    output reg              ex_al,
    output reg              ex_SPEC,
    output reg              ex_load,
    output reg              ex_loadX,
    output reg [3 :0]       ex_lsV,
    output reg              ex_branch,
    output reg              ex_j_r,
    output reg              ex_bd,
    output reg [5 :0]       ex_ifunc,
    output reg              ex_regwen,
    output reg [4 :0]       ex_wreg,
    output reg              ex_data_en,
    output reg [3 :0]       ex_data_ren,
    output reg [3 :0]       ex_data_wen,
    output reg [3 :0]       ex_data_wren,
    output reg              ex_eret,
    output reg              ex_cp0ren,
    output reg              ex_cp0wen,
    output reg [7 :0]       ex_cp0addr,
    output reg              ex_mult,
    output reg              ex_div,
    output reg              ex_mdsign,
    output reg [1 :0]       ex_hiloren,
    output reg [1 :0]       ex_hilowen,

    output reg              ex_btb_wen,
    output reg [`BTB_BITS]  ex_btb_windex,
    output reg [31:0]       ex_btb_wtarget,
    
    output reg              ex_gshare_wen,
    output reg [`GHR_BITS]  ex_gshare_windex,
    output reg              ex_bp_take,

    output reg              ex_op_bltz,
    output reg              ex_op_bgez,
    output reg              ex_op_beq,
    output reg              ex_op_bne,
    output reg              ex_op_blez,
    output reg              ex_op_bgtz,
    output reg [1:0]        ex_wait_seg
);

    always @(posedge clk) begin
        if(!resetn || refresh) begin
            ex_ex           <= `NUM_EX'b0;
            ex_empty        <= 1'b0;
            ex_pc           <= 32'h0;
            ex_pc_8         <= 32'h0;
            ex_inst         <= 32'h0;
            ex_bd           <= 1'b0;
            ex_branch       <= 1'b0;
            ex_j_r          <= 1'b0;
            ex_imm          <= 1'b0;
            ex_Imm          <= 32'h0;
            ex_A            <= 32'h0;
            ex_B            <= 32'h0;
            ex_rs_ren       <= 1'b0;
            ex_rt_ren       <= 1'b0;
            ex_al           <= 1'b0;
            ex_SPEC         <= 1'b0;
            ex_load         <= 1'b0;
            ex_loadX        <= 1'b0;
            ex_lsV          <= 4'b0;
            ex_ifunc        <= 6'h0;
            ex_regwen       <= 1'b0;
            ex_wreg         <= 5'h0;
            ex_data_en      <= 1'b0;
            ex_data_ren     <= 4'b0;
            ex_data_wen     <= 4'h0;
            ex_data_wren    <= 4'h0;
            ex_eret         <= 1'b0;
            ex_cp0ren       <= 1'b0;
            ex_cp0wen       <= 1'b0;
            ex_cp0addr      <= 8'b0;
            ex_mult         <= 1'b0;
            ex_div          <= 1'b0;
            ex_mdsign       <= 1'b0;
            ex_hilowen      <= 2'b0;
            ex_hiloren      <= 2'b0;

            ex_btb_wen      <= 1'b0;
            ex_btb_windex   <= `BTB_LEN'b0;
            ex_btb_wtarget  <= 32'b0;

            ex_gshare_windex<= `GHR_LEN'b0;
            ex_gshare_wen   <= 1'b0;
            ex_bp_take      <= 1'b0;

            ex_op_bltz      <= 1'b0;
            ex_op_bgez      <= 1'b0;
            ex_op_beq       <= 1'b0;
            ex_op_bne       <= 1'b0;
            ex_op_blez      <= 1'b0;
            ex_op_bgtz      <= 1'b0;
            ex_wait_seg     <= 2'b0;
        end
        else if(!stall) begin
            ex_ex           <= id_ex;
            ex_empty        <= id_empty;
            ex_pc           <= id_pc;
            ex_pc_8         <= id_pc_8;
            ex_inst         <= id_inst;
            ex_branch       <= id_branch;
            ex_j_r          <= id_j_r;
            ex_bd           <= id_bd;
            ex_imm          <= id_imm;
            ex_Imm          <= id_Imm;
            ex_A            <= id_A;
            ex_B            <= id_B;
            ex_rs_ren       <= id_rs_ren;
            ex_rt_ren       <= id_rt_ren;
            ex_al           <= id_al;
            ex_SPEC         <= id_SPEC;
            ex_load         <= id_load;
            ex_loadX        <= id_loadX;
            ex_lsV          <= id_lsV;
            ex_ifunc        <= id_ifunc;
            ex_regwen       <= id_regwen;
            ex_wreg         <= id_wreg;
            ex_data_en      <= id_data_en;
            ex_data_ren     <= id_data_ren;
            ex_data_wen     <= id_data_wen;
            ex_data_wren    <= id_data_wren;
            ex_eret         <= id_eret;
            ex_cp0ren       <= id_cp0ren;
            ex_cp0wen       <= id_cp0wen;
            ex_cp0addr      <= id_cp0addr;
            ex_mult         <= id_mult;
            ex_div          <= id_div;
            ex_mdsign       <= id_mdsign;
            ex_hilowen      <= id_hilowen;
            ex_hiloren      <= id_hiloren;

            ex_btb_wen      <= id_btb_wen;
            ex_btb_windex   <= id_btb_windex;
            ex_btb_wtarget  <= id_btb_wtarget;

            ex_gshare_windex<= id_gshare_windex;
            ex_gshare_wen   <= id_gshare_wen;
            ex_bp_take      <= id_bp_take;

            ex_op_bltz      <= id_op_bltz;
            ex_op_bgez      <= id_op_bgez;
            ex_op_beq       <= id_op_beq;
            ex_op_bne       <= id_op_bne;
            ex_op_blez      <= id_op_blez;
            ex_op_bgtz      <= id_op_bgtz;
            ex_wait_seg     <= id_wait_seg-2'd1;
        end
        else begin
            if(wb_regwen && wb_wreg == `GET_Rs(ex_inst))
                ex_A    <= wb_reorder_data;
            if(wb_regwen && wb_wreg == `GET_Rt(ex_inst))
                ex_B    <= wb_reorder_data;
        end
    end

endmodule