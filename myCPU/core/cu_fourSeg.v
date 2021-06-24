`timescale 1ns/1ps

// * Pipeline stall and refresh
module cu(
    input [31:0]id_pc,

    input       inst_req,
    input       inst_addr_ok,
    input       inst_data_ok,

    input       wb_data_req,   // 前一个req，即wb段的
    input       data_req,       // 目前的req，即ex段的
    input       data_addr_ok,
    input       data_data_ok,

    input       ext_int_soft,

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

    output  pre_ins,

    input   div_mul_stall,

    output  if_id_stall,
    output  id_ex_stall,
    output  ex_wb_stall,

    output  if_id_refresh,
    output  id_ex_refresh,
    output  ex_wb_refresh
);

    wire ex_rel_rs  = id_branch && id_rs_ren && ex_regwen && ex_wreg == id_rs;
    wire ex_rel_rt  = id_branch && id_rt_ren && ex_regwen && ex_wreg == id_rt;

    wire inst_stall = (inst_req && !inst_addr_ok) || !inst_data_ok;
    // * load若addr被接收就不暂停，store需要addr被接收且data写入才能不暂停
    wire data_stall = data_req && !data_addr_ok;

    wire ex_branch_stall = (ex_rel_rs || ex_rel_rt) && ex_load; // * ex段 数据相关导致分支预测暂停
    assign pre_ins = (div_mul_stall || data_stall || ex_wb_stall) && !inst_stall;

    wire load_load = ex_load && wb_data_req && data_data_ok; // * wb load ex load

    assign ex_wb_stall = (data_stall && !load_load) || (wb_data_req && !data_data_ok); // * 没返回时持续将data_req挂高
    assign id_ex_stall = !id_pc || ex_wb_stall || div_mul_stall || data_stall;  // *id recode
    assign if_id_stall = ex_branch_stall || inst_stall || (id_ex_stall && id_pc);

    assign if_id_refresh = exc_oc/* || eret*/;
    assign id_ex_refresh = !id_ex_stall && !ext_int_soft && (eret || exc_oc || ex_branch_stall || if_id_stall);
    assign ex_wb_refresh = !ex_wb_stall && (exc_oc || div_mul_stall || (data_stall && load_load));

endmodule