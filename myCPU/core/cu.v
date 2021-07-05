`timescale 1ns/1ps

// * Pipeline stall and refresh
module cu(
    input [31:0]pd_pc,
    input       pd_bd,

    input       inst_data_ok,
    input       pd_inst_req,

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

    input       pd_j_r,
    input       id_j_r,
    // input       ex_j_r,
    input       id_bp_error,
    input       ex_bp_error,
    input       ec_bp_error,

    input       b_rs_ren,    // * rs的读有效位
    input [4:0] id_rs,
    // input       b_rt_ren,    // * rt的读有效位
    // input [4:0] id_rt,

    input       ex_branch,
    input       ex_dload_req,
    input [4:0] ex_wreg,
    input       ex_cp0ren,

    input       ec_load,
    input [4:0] ec_wreg,

    input       div_mul_stall,
    // * O
    output      pc_stall,
    output      if_pd_stall,
    output      pd_id_stall,
    output      id_ex_stall,
    output      ex_ec_stall,
    output      ec_wb_stall,

    output      if_pd_refresh,
    output      pd_id_refresh,
    output      id_ex_refresh,
    output      ex_ec_refresh,
    output      ec_wb_refresh
);

    // * 判断ex段写的reg是否为当前id段的rs load, cp0需暂停
    wire ex_rel_rs  = b_rs_ren && ex_wreg == id_rs;
    // * 判断ec段写的reg是否为id段的rs load 需暂停
    wire ec_rel_rs  = b_rs_ren && ec_wreg == id_rs;

    // * load若addr被接收就不暂停，store需要addr被接收且data写入才能不暂停
    wire data_stall = data_req && !data_addr_ok;    // * data cache因addr_ok没返回被暂停
                                                    // * 注释掉为了去掉ex到id段的分支预测的重定向
    // * 只有j_r暂停
    // *TODO 后续可以尝试j_r不暂停，然后到后面fresh流水线
    // *TODO 如果添加RAS需要修改j_r,只有jalr暂停
    wire j_r_stall  = pd_j_r;
    wire ex_branch_stall = ex_rel_rs && id_j_r;
    wire ec_branch_stall = ec_rel_rs && ec_dload_req && id_j_r;

    wire ec_load_to_ex_stall = (ex_rs_ren && ec_wreg == ex_rs || ex_rt_ren && ec_wreg == ex_rt)
                               && ec_dload_req && !ex_branch;
    wire pd_data_okn = pd_inst_req && !inst_data_ok;

    // *                 ec是load但没返回data_ok
    assign ec_wb_stall  = ec_dload_req && !data_data_ok;
    assign ex_ec_stall  = ec_wb_stall || ec_load_to_ex_stall;
    assign id_ex_stall  = ex_ec_stall || div_mul_stall || data_stall;
    assign pd_id_stall  = id_ex_stall || ex_branch_stall || ec_branch_stall;
    assign if_pd_stall  = pd_data_okn || pd_id_stall;
    assign pc_stall     = if_pd_stall || j_r_stall;

    assign if_pd_refresh    =   !(pd_bd && if_pd_stall) &&
                                (id_bp_error || ex_bp_error || ec_bp_error || 
                                exc_oc || eret || (id_j_r && !id_ex_stall));

    assign pd_id_refresh    =   (ex_bp_error || ec_bp_error) || 
                                (!pd_id_stall && (exc_oc || pd_data_okn));

    assign id_ex_refresh    =   ec_bp_error || 
                                (!id_ex_stall && (exc_oc || ex_branch_stall || ec_branch_stall));

    assign ex_ec_refresh    =   (ec_load_to_ex_stall && data_data_ok) || // * ec load and ex use ec res and data ok */
                                !ex_ec_stall && (exc_oc || div_mul_stall || data_stall);

    assign ec_wb_refresh    =   !ec_wb_stall && exc_oc;

endmodule