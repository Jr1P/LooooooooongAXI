`timescale 1ns/1ps

// * Pipeline stall and refresh
module cu(
    input [31:0]id_pc,

    input       ex_rs_ren,
    input [4:0] ex_rs,
    input       ex_rt_ren,
    input [4:0] ex_rt,

    input exc_oc,
    input eret,

    input id_branch,
    input id_rs_ren,
    input [4:0] id_rs,
    input id_rt_ren,
    input [4:0] id_rt,

    input ex_regwen,
    input ex_load,
    input ex_cp0ren,
    input [4:0] ex_wreg,

    output  ex_stall,

    output  if_id_stall,
    output  id_ex_stall,
    output  ex_wb_stall,

    output  if_id_refresh,
    output  id_ex_refresh,
    output  ex_wb_refresh
);

    wire ex_rel_rs  = id_branch && id_rs_ren && ex_regwen && ex_wreg == id_rs;
    wire ex_rel_rt  = id_branch && id_rt_ren && ex_regwen && ex_wreg == id_rt;
    assign ex_stall = (ex_rel_rs || ex_rel_rt) && ex_load;

    assign ex_wb_stall = 1'b0;
    assign id_ex_stall = 1'b0;  // *id recode
    assign if_id_stall = ex_stall;

    assign if_id_refresh = exc_oc || eret;
    assign id_ex_refresh = exc_oc || ex_stall || !id_pc;
    assign ex_wb_refresh = exc_oc;

endmodule