`timescale 1ns/1ps

// * Pipeline stall and refresh
module cu(
    input [31:0]id_pc,

    input       inst_req,
    input       inst_addr_ok,
    input       inst_data_ok,

    input       ec_data_req,    // *前一个req，即ec段的
    input       data_req,       // *目前的req，即ex段的
    input       data_addr_ok,
    input       data_data_ok,
    input       wb_data_ok,

    input       ext_int_soft,

    input       ex_rs_ren,
    input [4:0] ex_rs,
    input       ex_rt_ren,
    input [4:0] ex_rt,

    input       exc_oc,
    input       eret,

    input       id_branch,
    input       id_rs_ren,    // * rs的读有效位
    input [4:0] id_rs,
    input       id_rt_ren,    // * rt的读有效位
    input [4:0] id_rt,

    input       ex_regwen,
    input       ex_load,
    input [4:0] ex_wreg,
    input       ex_cp0ren,

    input       ec_regwen,
    input       ec_load,
    input [4:0] ec_wreg,

    input       div_mul_stall,

    output      id_recode,      // * load写后面指令读时使用
    output      pre_ins,
    output      inst_stall,

    output      if_id_stall,
    output      id_ex_stall,
    output      ex_ec_stall,
    output      ec_wb_stall,

    output      if_id_refresh,
    output      id_ex_refresh,
    output      ex_ec_refresh,
    output      ec_wb_refresh
);

    // * 对于cp0rdata, branch指令需要暂停一个周期
    // * 对于data load, branch指令需要暂停两个周期

    // * 判断ex段写的reg是否为当前id段的rs load, cp0需暂停
    wire ex_rel_rs  = id_branch && id_rs_ren && ex_regwen && ex_wreg == id_rs;
    wire ex_rel_rt  = id_branch && id_rt_ren && ex_regwen && ex_wreg == id_rt;
    // * 判断ec段写的reg是否为id段的rs load 需暂停
    wire ec_rel_rs  = id_branch && id_rs_ren && ec_regwen && ec_wreg == id_rs;
    wire ec_rel_rt  = id_branch && id_rt_ren && ec_regwen && ec_wreg == id_rt;

    assign inst_stall = (inst_req && !inst_addr_ok) || !inst_data_ok; // * inst cache因addr_ok没返回或者数据没返回而暂停
    // * load若addr被接收就不暂停，store需要addr被接收且data写入才能不暂停
    wire data_stall = data_req && !data_addr_ok; // * data cache的因addr_ok没返回被暂停

    wire ex_branch_stall = (ex_rel_rs || ex_rel_rt) && (ex_load || ex_cp0ren); // * ex段 数据相关导致分支预测暂停
    wire ec_branch_stall = (ec_rel_rs || ec_rel_rt) && ec_data_req;
    assign pre_ins = (div_mul_stall || data_stall || ec_wb_stall) && !inst_stall;

    wire load_load = ex_load && ec_data_req && data_data_ok; // * ec load ex load且data_ok高，说明前一个的load的数据返回了
    wire ec_load_to_ex_stall = ec_data_req && (ex_rs_ren && ec_wreg == ex_rs || ex_rt_ren && ec_wreg == ex_rt);

    assign id_recode = ec_load_to_ex_stall && !ec_wb_stall;

    // * 没返回时持续将data_req挂高
    // *                如果data_stall且 !load_load  或 ec是load但没返回data_ok
    assign ec_wb_stall = (data_stall && !load_load) || (ec_data_req && !data_data_ok);
    assign ex_ec_stall = ec_wb_stall || (ec_load_to_ex_stall && !wb_data_ok);
    assign id_ex_stall = !id_pc || (!id_recode && (ex_ec_stall || div_mul_stall || data_stall));  // *id recode
    assign if_id_stall = ex_branch_stall || ec_branch_stall || inst_stall || (id_ex_stall && id_pc) || id_recode;

    assign if_id_refresh = exc_oc || eret;
    assign id_ex_refresh = !id_recode && !id_ex_stall && !ext_int_soft && (eret || exc_oc || ex_branch_stall || if_id_stall);
    assign ex_ec_refresh = (ec_load_to_ex_stall && !ec_wb_stall) || !ex_ec_stall && (exc_oc || div_mul_stall || (data_stall && load_load));
    assign ec_wb_refresh = !ec_wb_stall && exc_oc;

endmodule