`timescale 1ns/1ps

// * Pipeline stall and refresh
module cu(
    input [31:0]id_pc,

    input       inst_req,
    input       inst_addr_ok,
    input       inst_data_ok,
    input       id_inst_req,

    input       ec_dload_req,    // *前一个req，即ec段的
    input       data_req,       // *目前的req，即ex段的
    input       data_addr_ok,
    input       data_data_ok,
    input       wb_regwen,
    input [4:0] wb_wreg,

    input       ex_rs_ren,
    input [4:0] ex_rs,
    input       ex_rt_ren,
    input [4:0] ex_rt,

    input       exc_oc,
    input       eret,

    input       b_rs_ren,    // * rs的读有效位
    input [4:0] id_rs,
    input       b_rt_ren,    // * rt的读有效位
    input [4:0] id_rt,

    input       ex_dload_req,
    input [4:0] ex_wreg,
    input       ex_cp0ren,

    input       ec_load,
    input [4:0] ec_wreg,

    input       div_mul_stall,

    output      pre_ins,

    output      if_id_stall,
    output      id_ex_stall,
    output      ex_ec_stall,
    output      ec_wb_stall,

    output      if_id_refresh,
    output      id_ex_refresh,
    output      ex_ec_refresh,
    output      ec_wb_refresh
);

    // * 判断ex段写的reg是否为当前id段的rs load, cp0需暂停
    wire ex_rel_rs  = b_rs_ren && ex_wreg == id_rs;
    wire ex_rel_rt  = b_rt_ren && ex_wreg == id_rt;
    // * 判断ec段写的reg是否为id段的rs load 需暂停
    wire ec_rel_rs  = b_rs_ren && ec_wreg == id_rs;
    wire ec_rel_rt  = b_rt_ren && ec_wreg == id_rt;

    // * inst cache因addr_ok没返回或者数据没返回而暂停
    wire inst_stall = inst_req && !inst_addr_ok;
    // * load若addr被接收就不暂停，store需要addr被接收且data写入才能不暂停
    wire data_stall = data_req && !data_addr_ok; // * data cache因addr_ok没返回被暂停
                                                // * 注释掉为了去掉ex到id段的分支预测的重定向
    wire ex_branch_stall = ex_rel_rs || ex_rel_rt;
    wire ec_branch_stall = (ec_rel_rs || ec_rel_rt) && ec_dload_req;

    wire ec_load_to_ex_stall = ec_dload_req && (ex_rs_ren && ec_wreg == ex_rs || ex_rt_ren && ec_wreg == ex_rt);

    // * if_id_stall && !inst_stall
    assign pre_ins = ex_branch_stall || ec_branch_stall || (id_inst_req && !inst_data_ok) || (id_ex_stall && id_pc);
    // * 没返回时持续将data_req挂高
    // *                 ec是load但没返回data_ok
    assign ec_wb_stall = ec_dload_req && !data_data_ok;
    assign ex_ec_stall = ec_wb_stall || ec_load_to_ex_stall;
    assign id_ex_stall = (!id_pc && !eret) || (ex_ec_stall || div_mul_stall || data_stall);  // *id recode
    assign if_id_stall = ex_branch_stall || ec_branch_stall || inst_stall || (id_inst_req && !inst_data_ok) || (id_ex_stall && id_pc);

    assign if_id_refresh = exc_oc || eret;
    assign id_ex_refresh = !id_ex_stall && (exc_oc || if_id_stall);
    assign ex_ec_refresh =  (ec_load_to_ex_stall && !ec_wb_stall) || // * ec load and ex use ec res and data ok */
                            !ex_ec_stall && (exc_oc || div_mul_stall || data_stall);
    assign ec_wb_refresh = !ec_wb_stall && exc_oc;

endmodule