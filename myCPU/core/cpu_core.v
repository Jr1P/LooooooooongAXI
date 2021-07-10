`timescale 1ns / 1ps
`include "./head.vh"

// * five segment pipeline cpu

// TODO: 1. 时序优化以及分支预测优化
// *TODO    1.1 RAS添加
// *TODO    1.2 gshare预写优化
// *TODO    1.3 refresh逻辑简化
// TODO: 2. TLB inst  mul inst  3. interrupt mech    4. maybe 反思
module cpu_core(
    input   [5 :0]  ext_int,        // *硬件中断

    input           aclk,
    input           aresetn,

    output          inst_req,
    output          inst_cache,
    output  [31:0]  inst_addr,
    input   [31:0]  inst_rdata,
    input           inst_addr_ok,
    input           inst_data_ok,

    output          data_req,
    output          data_wr,
    output          data_cache,
    output  [3 :0]  data_wstrb,
    output  [31:0]  data_addr,
    output  [1 :0]  data_size,
    output  [31:0]  data_wdata,
    input   [31:0]  data_rdata,
    input           data_addr_ok,
    input           data_data_ok,

    output          cache_req,
    output  [6 :0]  cache_op,
    output  [31:0]  cache_tag,
    input           cache_over,

    output  [31:0]  debug_wb_pc,
    output  [3 :0]  debug_wb_rf_wen,
    output  [4 :0]  debug_wb_rf_wnum,
    output  [31:0]  debug_wb_rf_wdata
);

    // *Exceptions
    wire    ex_IntegerOverflow;
    wire    ex_data_ADDRESS_ERROR;
    // * IF
    wire [31:0]     npc;
    wire            if_addr_error;
    wire            if_btb_hit;
    wire [31:0]     if_btb_target;
    wire [`BTB_BITS]if_btb_index;
    wire [`GHR_BITS]if_gshare_index;
    wire            if_gshare_take;
    // * PD
    wire            pd_fail_flushed; // * 表示if_pd段是否被ex或ec段的bp_fail刷新过
    wire            pd_empty;
    wire            pd_addr_error;
    wire [31:0]     pd_pc;
    wire [31:0]     pd_pc_8;
    wire [31:0]     pd_inst;
    wire            pd_inst_invalid;
    wire            pd_branch;
    wire            pd_j_dir;
    wire            pd_j_r;
    wire            pd_b;
    wire            pd_take;
    wire            pd_target_ok;
    wire [31:0]     pd_target;
    wire            pd_bd;
    wire            pd_inst_req;
    
    wire            pd_op_bltz;
    wire            pd_op_bgez;
    wire            pd_op_bltzal;
    wire            pd_op_bgezal;
    wire            pd_op_beq;
    wire            pd_op_bne;
    wire            pd_op_blez;
    wire            pd_op_bgtz;
    wire            pd_eret;

    wire            pd_b_rs_ren;
    wire            pd_b_rt_ren;
    
    wire            pd_dir;     // * 确定直接跳转
    wire            pd_bp_ok;   // * 预测跳转

    wire            pd_btb_hit;
    wire [31:0]     pd_btb_target;
    wire [`BTB_BITS]pd_btb_index;
    wire            pd_btb_wen;
    wire            pd_gshare_take;
    wire [`GHR_BITS]pd_gshare_index;
    // *ID
    wire            id_fail_flushed; // * 表示pd_id段是否被ec段的bp_fail刷新过
    wire            id_empty;
    wire            id_b;
    wire            id_j_dir;
    wire            id_j_r;
    wire            id_b_rs_ren;
    wire            id_b_rt_ren;

    wire            id_op_bltz;
    wire            id_op_bgez;
    wire            id_op_beq;
    wire            id_op_bne;
    wire            id_op_blez;
    wire            id_op_bgtz;

    wire [31:0]     regouta, regoutb;
    wire [31:0]     re_rs, re_rt;
    wire            id_addr_error;
    wire [`EXBITS]  id_ex;

    wire [31:0]     id_pc;
    wire [31:0]     id_pc_8;
    wire [31:0]     id_inst;
    wire [4 :0]     id_rs = `GET_Rs(id_inst);
    wire [4 :0]     id_rt = `GET_Rt(id_inst);
    wire            id_bd;
    wire            id_branch;
    wire            id_al;
    wire            id_SPEC;
    wire            id_rs_ren;
    wire            id_rt_ren;
    wire [5 :0]     id_ifunc;
    wire            id_load;
    wire            id_loadX;
    wire [3 :0]     id_lsV;
    wire            id_imm;
    wire [31:0]     id_Imm;
    wire            id_eret;
    wire            id_data_en;
    wire [3 :0]     id_data_ren;
    wire [3 :0]     id_data_wen;
    wire [3 :0]     id_data_wren; // write | read
    wire            id_regwen;
    wire [4 :0]     id_wreg;
    wire            id_cp0ren;
    wire            id_cp0wen;
    wire [`CP0ADDR] id_cp0addr;
    wire            id_mult;
    wire            id_div;
    wire            id_mdsign;
    wire [1 :0]     id_hiloren;
    wire [1 :0]     id_hilowen;
    // * id part branch
    wire            id_btb_wen;
    wire [`BTB_BITS]id_btb_windex;
    wire [31:0]     id_btb_wtarget;
    wire            id_gshare_wen;
    wire [`GHR_BITS]id_gshare_windex;
    wire            id_bp_take;
    wire            id_realj;
    wire [1 :0]     id_wait_seg;
    // * gshare 预写
    wire            id_gshare_pre_wen;
    wire            id_pre_bit;
    // *EX
    wire            ex_empty;
    wire [`EXBITS]  ex_ex;
    wire [31:0]     ex_pc;
    wire [31:0]     ex_pc_8;
    wire [31:0]     ex_inst;
    wire [4 :0]     ex_rs = `GET_Rs(ex_inst);
    wire [4 :0]     ex_rt = `GET_Rt(ex_inst);
    wire [31:0]     ex_res;
    wire            ex_imm;
    wire [31:0]     ex_Imm;
    wire [31:0]     ex_A;
    wire [31:0]     ex_B;
    wire [31:0]     ex_daddr;
    wire            ex_rs_ren;
    wire            ex_rt_ren;
    wire            ex_al;
    wire            ex_SPEC;
    wire            ex_load;
    wire            ex_loadX;
    wire [3 :0]     ex_lsV;
    wire            ex_branch;
    wire            ex_j_r;
    wire            ex_bd;
    wire [5 :0]     ex_ifunc;
    wire            ex_regwen;
    wire [4 :0]     ex_wreg;
    wire            ex_data_en;
    wire [3 :0]     ex_data_ren;
    wire [3 :0]     ex_data_wen;
    wire [3 :0]     ex_data_wren;
    wire [31:0]     ex_wdata;
    wire            ex_eret;
    wire            ex_cp0ren;
    wire [31:0]     ex_cp0rdata;
    wire            ex_cp0wen;
    wire [`CP0ADDR] ex_cp0addr;
    wire            ex_mult;
    wire            ex_div;
    wire            ex_mdsign;
    wire [1 :0]     ex_hilowen;
    wire [1 :0]     ex_hiloren;
    wire [31:0]     ex_hilordata;
    // * ex part branch
    wire            ex_bp_take;
    wire            ex_realj;
    wire [1 :0]     ex_wait_seg;
    wire            ex_btb_wen;
    wire [`BTB_BITS]ex_btb_windex;
    wire [31:0]     ex_btb_wtarget;
    wire            ex_gshare_wen;
    wire [`GHR_BITS]ex_gshare_windex;
    // *EC
    wire [`EXBITS]  ec_ex;
    wire [31:0]     ec_pc;
    wire [31:0]     ec_pc_8;
    wire [31:0]     ec_inst;
    wire [4 :0]     ec_rs = `GET_Rs(ec_inst);
    wire [4 :0]     ec_rt = `GET_Rt(ec_inst);
    wire [31:0]     ec_res;
    wire [31:0]     ec_A;
    wire [31:0]     ec_B;
    wire            ec_load;
    wire            ec_loadX;
    wire [3 :0]     ec_lsV;
    wire            ec_bd;
    wire [1 :0]     ec_data_addr;
    wire            ec_regwen;
    wire [4 :0]     ec_wreg;
    wire            ec_data_req;
    wire [31:0]     ec_wdata;
    wire            ec_eret;
    wire            ec_exc_oc;
    wire            ec_cp0ren;
    wire            ec_cp0wen;
    wire [`CP0ADDR] ec_cp0addr;
    wire [31:0]     ec_cp0rdata;
    wire [31:0]     ec_reorder_data;
    wire [31:0]     ec_reorder_ex;
    // * ex part branch
    wire            ec_bp_take;
    wire            ec_realj;
    wire [1 :0]     ec_wait_seg;
    // * 写BTB以及gshare
    wire            ec_btb_wen;
    wire [31:0]     ec_btb_wtarget;
    wire [`BTB_BITS]ec_btb_windex;
    wire            ec_gshare_wen;
    wire [`GHR_BITS]ec_gshare_windex;
    // * cp0寄存器的读写请求
    wire ec_cp0_badV_en     ;
    wire ec_cp0_count_en    ;
    wire ec_cp0_compare_en  ;
    wire ec_cp0_status_en   ;
    wire ec_cp0_cause_en    ;
    wire ec_cp0_epc_en      ;
    // * CP0
    wire [31:0]     cp0_epc;
    wire            ext_int_response;
    // *WB
    wire [31:0]     wb_data_rdata;
    wire [31:0]     wb_pc;
    wire [31:0]     wb_inst;
    wire            wb_load;
    wire            wb_regwen;
    wire [4 :0]     wb_wreg;
    wire            wb_eret;
    wire [31:0]     wb_reorder_data;
    wire [31:0]     wb_reorder_ec;
    // * Branch Predict
    wire        bp_take;    // * 确定的跳转或者预测的跳转均为 1'b1
    wire [31:0] bp_target;  // * 目的地址
    wire        bp_fail;    // * 失败
    wire [31:0] bp_real_target; // * 真正的目的地址
    wire [`GHR_BITS]    ghr;

    // * CU
    // * 分支跳转方向错误
    wire    id_bp_error;
    wire    ex_bp_error;
    wire    ec_bp_error;

    wire    branch_stall;
    wire    pc_stall;
    wire    if_pd_stall;
    wire    pd_id_stall;
    wire    id_ex_stall;
    wire    ex_ec_stall;
    wire    ec_wb_stall;

    reg inst_bank_valid;

    wire    if_pd_refresh;
    wire    pd_id_refresh;
    wire    id_ex_refresh;
    wire    ex_ec_refresh;
    wire    ec_wb_refresh;

    wire    div_mul_stall;

    // * 重定向数据
    wire [31:0] ex_reorder_data =   ex_al           ?   ex_pc_8         :
                                    (|ex_hiloren)   ?   ex_hilordata    :
                                    ex_cp0ren       ?   ex_cp0rdata     :
                                                        ex_res          ;

    // * cache / uncache
    assign inst_cache   = 1'b1;
    assign data_cache   = !(ex_daddr[31:29] == 3'b101);
    assign cache_req    = 1'b0;
    assign cache_op     = 7'b0;
    assign cache_tag    = 32'b0;

    reg inst_cache_state;
    parameter IDLE          =   1'b0;
    parameter BUSY          =   1'b1;
    always @(posedge aclk)
        inst_cache_state    <=  !aresetn        ? IDLE :
                                inst_addr_ok    ? BUSY :
                                inst_data_ok    ? IDLE :
                                inst_cache_state       ;

    assign inst_req =   !id_bp_error && !ex_bp_error && !ec_bp_error &&
                        !ec_exc_oc && (!inst_cache_state || inst_data_ok) && 
                        !pd_eret && !if_addr_error && !id_j_r;
    
    cu u_cu(
        .pd_empty       (pd_empty),
        .id_empty       (id_empty),
        .ex_empty       (ex_empty),

        .if_addr_error  (if_addr_error),
        .pd_addr_error  (pd_addr_error),
        .pd_bd          (pd_bd),
        .id_bd          (id_bd),
        .ex_bd          (ex_bd),

        .inst_addr_ok       (inst_addr_ok),
        .inst_data_ok       (inst_data_ok),
        .inst_cache_state   (inst_cache_state),

        .ec_dload_req   (ec_data_req && ec_load),   // * ec取数请求
        .data_req       (data_req),
        .data_addr_ok   (data_addr_ok),
        .data_data_ok   (data_data_ok),

        .ex_rs_ren  (ex_rs_ren),
        .ex_rs      (ex_rs),
        .ex_rt_ren  (ex_rt_ren),
        .ex_rt      (ex_rt),

        .exc_oc     (ec_exc_oc),
        .eret       (pd_eret),

        .pd_j_r     (pd_j_r),
        .id_j_r     (id_j_r),

        .id_bp_error(id_bp_error),
        .ex_bp_error(ex_bp_error),
        .ec_bp_error(ec_bp_error),

        .b_rs_ren   (id_b_rs_ren),
        .id_rs      (id_rs),
        .ex_branch      (ex_branch),
        .ex_wreg        (ex_wreg),
 
        .ec_load    (ec_load),
        .ec_wreg    (ec_wreg),

        .inst_bank_valid   (inst_bank_valid),
        .div_mul_stall  (div_mul_stall),
        // * O
        .branch_stall   (branch_stall),
        .pc_stall       (pc_stall),
        .if_pd_stall    (if_pd_stall),
        .pd_id_stall    (pd_id_stall),
        .id_ex_stall    (id_ex_stall),
        .ex_ec_stall    (ex_ec_stall),
        .ec_wb_stall    (ec_wb_stall),

        .if_pd_refresh  (if_pd_refresh),
        .pd_id_refresh  (pd_id_refresh),
        .id_ex_refresh  (id_ex_refresh),
        .ex_ec_refresh  (ex_ec_refresh),
        .ec_wb_refresh  (ec_wb_refresh)
    );

    // *IF
    // * 分支预测
    assign bp_take = pd_dir || pd_bp_ok || id_j_r;
   
    // ! 这里将BTB读出的目标直接不要了，如果需要，请用下面的
    assign bp_target =  id_j_r ? re_rs : pd_target;
                        // pd_dir ? pd_target : pd_btb_target;
    assign bp_fail = id_bp_error || ex_bp_error || ec_bp_error;
    assign bp_real_target = ec_bp_error ? 
                                ec_bp_take ? ec_pc_8 : ec_btb_wtarget
                          : ex_bp_error ?
                                ex_bp_take ? ex_pc_8 : ex_btb_wtarget
                          :     id_bp_take ? id_pc_8 : id_btb_wtarget;
    assign id_gshare_pre_wen = id_gshare_wen && (id_bp_error || !ec_bp_error);
    assign id_pre_bit = id_bp_error ? !id_bp_take : id_bp_take;

    wire [31:0]     exc_pc = ec_cp0_epc_en && ec_cp0wen ? ec_wdata : cp0_epc;

    pc u_pc(
        .clk            (aclk),
        .resetn         (aresetn),

        .pd_id_stall    (pd_id_stall),
        .id_j_r         (id_j_r),
        .pd_bd          (pd_bd),
        .inst_addr_ok   (inst_addr_ok),
        .inst_bank_valid(inst_bank_valid),
        .stall          (pc_stall),
        .branch_stall   (branch_stall),

        .BranchPredict  (bp_take),
        .BranchTarget   (bp_target),
        .PredictFailed  (bp_fail),
        .realTarget     (bp_real_target),

        .exc_oc         (ec_exc_oc),

        .eret           (pd_eret),  // * eret
        .epc            (exc_pc),  // * epc from cp0

        .npc            (npc)
    );

    // *               取前一条
    assign inst_addr =  /*if_pd_stall ? pd_pc :*/ npc;
    assign if_addr_error = npc[0] | npc[1];

    reg exc_oc_invalid; // * 异常发生后紧接着取出的指令不是正确指令
    always @(posedge aclk) begin
        if(!aresetn)    exc_oc_invalid <=   1'b0;
        else            exc_oc_invalid <=   ec_exc_oc || (if_pd_stall && exc_oc_invalid);
    end

    btb u_btb(
        .clk        (aclk),
        .resetn     (aresetn),

        // * write
        .wen        (ec_btb_wen),
        .index_w    (ec_btb_windex),
        .pc_w       (ec_pc[31:2]),
        // .target_w   (ec_btb_wtarget),
        // * read
        .pc_r       (npc[31:2]), // * I
        .ghr        (ghr),  // * I
        .hit_r      (if_btb_hit), // * O
        .index_r    (if_btb_index) // * O
        // .target_r   (if_btb_target)  // * O
    );

    gshare u_gshare(
        .clk        (aclk),
        .resetn     (aresetn),
        .pc_predict (npc[9:2]), // * 预测时输入的PC[9:2]
        // * id pre_write
        .pre_wen    (id_gshare_pre_wen),
        .pre_take   (id_pre_bit),
        // * ec Write
        .wen        (ec_gshare_wen),
        .windex     (ec_gshare_windex),
        .take       (ec_realj),
        // * O
        .rindex     (if_gshare_index),
        .predict    (if_gshare_take),      // * 预测方向
        .r_GHR      (ghr)
    );

    if_pd_seg u_if_pd_seg(
        .clk    (aclk),
        .resetn (aresetn),

        .stall  (if_pd_stall),
        .refresh(if_pd_refresh),

        // .id_j_r         (id_j_r),
        .pd_branch      (pd_branch),
        .if_addr_error  (if_addr_error),
        .if_pc          (inst_addr),
        .if_inst_req    (inst_req),
        .if_btb_hit     (if_btb_hit),
        .if_btb_target  (if_btb_target),
        .if_btb_index   (if_btb_index),
        .if_gshare_take (if_gshare_take),
        .if_gshare_index(if_gshare_index),

        .pd_empty       (pd_empty),
        .pd_bd          (pd_bd),
        .pd_addr_error  (pd_addr_error),
        .pd_pc          (pd_pc),
        .pd_pc_8        (pd_pc_8), // * pc+4
        .pd_inst_req    (pd_inst_req),
        .pd_btb_hit     (pd_btb_hit),
        .pd_btb_target  (pd_btb_target),
        .pd_btb_index   (pd_btb_index),
        .pd_gshare_take (pd_gshare_take),
        .pd_gshare_index(pd_gshare_index),
        .pd_inst_invalid(pd_inst_invalid)
    );

    // * PD
    reg [31:0] inst_bank;
    always @(posedge aclk) begin
        if(!aresetn || !pd_id_stall)
            inst_bank <= 32'h0;
        else if(!inst_bank_valid && inst_data_ok)
            inst_bank <= inst_rdata;
        else
            inst_bank <= inst_bank;

        // inst_bank_valid 表示有存货
        if(!aresetn || !pd_id_stall)
            inst_bank_valid <= 1'b0;
        else if(!inst_bank_valid && inst_data_ok)
            inst_bank_valid <= 1'b1;
        else 
            inst_bank_valid <= inst_bank_valid;
    end

    // *        exc_oc 后一条以及inst_data_ok低和取指地址错时, 分支等等都是无效指令
    wire [31:0] mask =  {32{
                            inst_data_ok    && /*!bp_fail_flush     && */
                            /*!pd_eret_d      &&*/ !pd_inst_invalid     &&
                            !exc_oc_invalid && !pd_addr_error       }};

    assign pd_inst  =   inst_bank_valid ? inst_bank : inst_rdata & mask;

    // * 指令预解码
    pd u_pd(
        .inst       (pd_inst),
        .pc         (pd_pc),
        // * O
        .branch     (pd_branch),
        .j_dir      (pd_j_dir),
        .j_r        (pd_j_r),
        .b          (pd_b),
        .take       (pd_take),
        .target_ok  (pd_target_ok),
        .target     (pd_target), // * 计算出来的target

        .op_bltz    (pd_op_bltz),
        .op_bgez    (pd_op_bgez),
        .op_bltzal  (pd_op_bltzal),
        .op_bgezal  (pd_op_bgezal),
        .op_beq     (pd_op_beq),
        .op_bne     (pd_op_bne),
        .op_blez    (pd_op_blez),
        .op_bgtz    (pd_op_bgtz),

        .b_rs_ren   (pd_b_rs_ren),
        .b_rt_ren   (pd_b_rt_ren),
        .eret       (pd_eret)
    );

    assign pd_dir    = pd_take && pd_target_ok;          // * 确定直接跳转
    assign pd_bp_ok  = (pd_btb_hit || pd_gshare_wen) && pd_gshare_take;     // * 预测跳转

    // ! 注意pd_take = 0表示暂不确定方向的跳转
    assign pd_btb_wen = !pd_take && pd_b && !pd_btb_hit; // * 对于未命中的条件跳转且不是beq 0 0 才会写btb
    assign pd_gshare_wen = !pd_take && pd_b;

    pd_id_seg u_pd_id_seg(
        .clk        (aclk),
        .resetn     (aresetn),

        .stall      (pd_id_stall),
        .refresh    (pd_id_refresh),
        
        .pd_addr_error  (pd_addr_error),
        .pd_empty       (pd_empty),
        .pd_pc          (pd_pc),
        .pd_pc_8        (pd_pc_8),
        .pd_inst        (pd_inst),
        .pd_bd          (pd_bd),
        .pd_branch      (pd_branch),
        .pd_b           (pd_b),
        .pd_j_dir       (pd_j_dir),
        .pd_j_r         (pd_j_r),
        .pd_b_rs_ren    (pd_b_rs_ren),
        .pd_b_rt_ren    (pd_b_rt_ren),
        // * btb
        .pd_btb_windex  (pd_btb_index),
        .pd_btb_wen     (pd_btb_wen),
        .pd_btb_wtarget (pd_target),
        // * gshare
        .pd_gshare_wen      (pd_gshare_wen),
        .pd_gshare_windex   (pd_gshare_index),
        .pd_bp_take         (pd_bp_ok),
        // * 预解码信息
        .pd_op_bltz     (pd_op_bltz || pd_op_bltzal),
        .pd_op_bgez     (pd_op_bgez || pd_op_bgezal),
        .pd_op_beq      (pd_op_beq      ),
        .pd_op_bne      (pd_op_bne      ),
        .pd_op_blez     (pd_op_blez     ),
        .pd_op_bgtz     (pd_op_bgtz     ),

        .id_addr_error  (id_addr_error),
        .id_empty       (id_empty),
        .id_pc          (id_pc),
        .id_pc_8        (id_pc_8),
        .id_inst        (id_inst),
        .id_bd          (id_bd),
        .id_branch      (id_branch),
        .id_b           (id_b),
        .id_j_dir       (id_j_dir),
        .id_j_r         (id_j_r),
        .id_b_rs_ren    (id_b_rs_ren),
        .id_b_rt_ren    (id_b_rt_ren),

        .id_btb_windex  (id_btb_windex),
        .id_btb_wen     (id_btb_wen),
        .id_btb_wtarget (id_btb_wtarget),

        .id_gshare_wen      (id_gshare_wen),
        .id_gshare_windex   (id_gshare_windex),
        .id_bp_take         (id_bp_take),

        .id_op_bltz     (id_op_bltz),
        .id_op_bgez     (id_op_bgez),
        .id_op_beq      (id_op_beq),
        .id_op_bne      (id_op_bne),
        .id_op_blez     (id_op_blez),
        .id_op_bgtz     (id_op_bgtz)
    );

    // *ID
    regfile u_regfile(
        .clk    (aclk),
        .resetn (aresetn),
        .rs     (id_rs),
        .rt     (id_rt),
        .wen    (wb_regwen && !ec_wb_stall), // * wb被暂停不写
        .wreg   (wb_wreg),
        .wdata  (wb_reorder_data),

        .outA   (regouta),
        .outB   (regoutb)
    );

    assign re_rs =     ec_regwen && ec_wreg == id_rs   ? ec_reorder_data   : regouta;
    assign re_rt =     ec_regwen && ec_wreg == id_rt   ? ec_reorder_data   : regoutb;

    bpu u_bpu(
        .eq     (re_rs == re_rt),
        .rega   (re_rs),

        .op_bltz    (id_op_bltz),
        .op_bgez    (id_op_bgez),
        .op_beq     (id_op_beq),
        .op_bne     (id_op_bne),
        .op_blez    (id_op_blez),
        .op_bgtz    (id_op_bgtz),

        .b_rs_ren   (id_b_rs_ren),
        .b_rt_ren   (id_b_rt_ren),
        .id_rs      (id_rs),
        .id_rt      (id_rt),

        .ex_wreg    (ex_wreg),
        .ex_load    (ex_load),
        .ec_wreg    (ec_wreg),
        .ec_load    (ec_load),

        // * O
        .realj      (id_realj),
        .wait_seg   (id_wait_seg)
    );

    assign id_bp_error = id_realj != id_bp_take && id_wait_seg == 2'b0
                         && id_gshare_wen;
    
    id u_id(
        .id_addr_error  (id_addr_error),

        .id_inst    (id_inst),
        .id_pc      (id_pc),

        .b_r        (id_j_r || id_b),
        .al         (id_al),
        .SPEC       (id_SPEC),
        .rs_ren     (id_rs_ren),
        .rt_ren     (id_rt_ren),
        .load       (id_load),
        .loadX      (id_loadX),
        .lsV        (id_lsV),
        .imm        (id_imm),
        .Imm        (id_Imm),
        .regwen     (id_regwen),
        .wreg       (id_wreg),
        .mult       (id_mult),
        .div        (id_div),
        .mdsign     (id_mdsign),
        .hiloren    (id_hiloren),
        .hilowen    (id_hilowen),
        .data_en    (id_data_en),
        .data_ren   (id_data_ren),
        .data_wen   (id_data_wen),
        .data_wren  (id_data_wren),
        .cp0ren     (id_cp0ren),
        .cp0wen     (id_cp0wen),
        .cp0addr    (id_cp0addr),
        .func       (id_ifunc),

        .eret       (id_eret),
        .id_ex      (id_ex)
    );

    id_ex_seg u_id_ex_seg(
        .clk    (aclk),
        .resetn (aresetn),

        .stall  (id_ex_stall),
        .refresh(id_ex_refresh),

        .wb_regwen          (wb_regwen && !ec_wb_stall),
        .wb_wreg            (wb_wreg),
        .wb_reorder_data    (wb_reorder_data),

        .id_empty   (id_empty),
        .id_ex      (id_ex),
        .id_pc      (id_pc),
        .id_pc_8    (id_pc_8),
        .id_inst    (id_inst),
        .id_imm     (id_imm),
        .id_Imm     (id_Imm),
        .id_A       (regouta),
        .id_B       (regoutb),
        .id_rs_ren  (id_rs_ren),
        .id_rt_ren  (id_rt_ren),
        .id_al      (id_al),
        .id_SPEC    (id_SPEC),
        .id_load    (id_load),
        .id_loadX   (id_loadX),
        .id_lsV     (id_lsV),
        .id_branch  (id_branch),
        .id_j_r     (id_j_r),
        .id_bd      (id_bd),
        .id_ifunc   (id_ifunc),
        .id_regwen  (id_regwen),
        .id_wreg    (id_wreg),
        .id_data_en (id_data_en),
        .id_data_ren(id_data_ren),
        .id_data_wen(id_data_wen),
        .id_data_wren(id_data_wren),
        .id_eret    (id_eret),
        .id_cp0ren  (id_cp0ren),
        .id_cp0wen  (id_cp0wen),
        .id_cp0addr (id_cp0addr),
        .id_mult    (id_mult),
        .id_div     (id_div),
        .id_mdsign  (id_mdsign),
        .id_hiloren (id_hiloren),
        .id_hilowen (id_hilowen),

        .id_btb_wen     (id_btb_wen),
        .id_btb_windex  (id_btb_windex),
        .id_btb_wtarget (id_btb_wtarget),

        .id_gshare_wen      (id_gshare_wen),
        .id_gshare_windex   (id_gshare_windex),
        .id_bp_take         (id_bp_take),

        .id_op_bltz     (id_op_bltz),
        .id_op_bgez     (id_op_bgez),
        .id_op_beq      (id_op_beq),
        .id_op_bne      (id_op_bne),
        .id_op_blez     (id_op_blez),
        .id_op_bgtz     (id_op_bgtz),
        .id_wait_seg    (id_wait_seg),

        .ex_empty   (ex_empty),
        .ex_ex      (ex_ex),
        .ex_pc      (ex_pc),
        .ex_pc_8    (ex_pc_8),
        .ex_inst    (ex_inst),
        .ex_imm     (ex_imm),
        .ex_Imm     (ex_Imm),
        .ex_A       (ex_A),
        .ex_B       (ex_B),
        .ex_rs_ren  (ex_rs_ren),
        .ex_rt_ren  (ex_rt_ren),
        .ex_al      (ex_al),
        .ex_SPEC    (ex_SPEC),
        .ex_load    (ex_load),
        .ex_loadX   (ex_loadX),
        .ex_lsV     (ex_lsV),
        .ex_branch  (ex_branch),
        .ex_j_r     (ex_j_r),
        .ex_bd      (ex_bd),
        .ex_ifunc   (ex_ifunc),
        .ex_regwen  (ex_regwen),
        .ex_wreg    (ex_wreg),
        .ex_data_en (ex_data_en),
        .ex_data_ren(ex_data_ren),
        .ex_data_wen(ex_data_wen),
        .ex_data_wren(ex_data_wren),
        .ex_eret    (ex_eret),
        .ex_cp0ren  (ex_cp0ren),
        .ex_cp0wen  (ex_cp0wen),
        .ex_cp0addr (ex_cp0addr),
        .ex_mult    (ex_mult),
        .ex_div     (ex_div),
        .ex_mdsign  (ex_mdsign),
        .ex_hiloren (ex_hiloren),
        .ex_hilowen (ex_hilowen),

        .ex_btb_wen         (ex_btb_wen),
        .ex_btb_windex      (ex_btb_windex),
        .ex_btb_wtarget     (ex_btb_wtarget),

        .ex_gshare_wen      (ex_gshare_wen),
        .ex_gshare_windex   (ex_gshare_windex),
        .ex_bp_take         (ex_bp_take),
    
        .ex_op_bltz         (ex_op_bltz),
        .ex_op_bgez         (ex_op_bgez),
        .ex_op_beq          (ex_op_beq),
        .ex_op_bne          (ex_op_bne),
        .ex_op_blez         (ex_op_blez),
        .ex_op_bgtz         (ex_op_bgtz),
        .ex_wait_seg        (ex_wait_seg)
    );

    // *EX
    // *store命令写入的数据
    assign ex_wdata     =   ec_wreg == ex_rt && ec_regwen   ? ec_reorder_data   :
                            wb_wreg == ex_rt && wb_regwen   ? wb_reorder_data   : ex_B;

    wire [31:0] inAlu1  =   ec_wreg == ex_rs && ec_regwen   ? ec_reorder_data   :
                            wb_wreg == ex_rs && wb_regwen   ? wb_reorder_data   : ex_A;

    wire [31:0] inAlu2  =   ex_imm ? ex_Imm : ex_wdata;

    wire [5 :0] ex_func =   ex_SPEC ? `GET_FUNC(ex_inst) : ex_ifunc;
    check_branch u_check_branch_ex (
        .eq     (inAlu1 == ex_wdata),
        .rega   (inAlu1),

        .op_bltz    (ex_op_bltz),
        .op_bgez    (ex_op_bgez),
        .op_beq     (ex_op_beq),
        .op_bne     (ex_op_bne),
        .op_blez    (ex_op_blez),
        .op_bgtz    (ex_op_bgtz),

        // * O
        .realj      (ex_realj)
    );

    assign ex_bp_error = ex_realj != ex_bp_take && ex_wait_seg == 2'b0
                       && ex_gshare_wen;

    alu u_alu(
        .A      (inAlu1),
        .B      (inAlu2),
        .func   (ex_func),
        .sa     (`GET_SA(ex_inst)),

        .IntegerOverflow    (ex_IntegerOverflow),
        .daddr              (ex_daddr), // * dcache的地址
        .res                (ex_res)
    );

    // * MUL and DIV
    wire [65:0] mul_res;
    wire mul_working, mul_finish;
    wire mul_cancel = mul_working && ex_mult;

    mul u_mul(
        .clk    (aclk),
        .resetn (aresetn),
        .en     (ex_mult && !ec_exc_oc),
        .cancel (mul_cancel),

        .A      ({ex_mdsign & inAlu1[31], inAlu1}),
        .B      ({ex_mdsign & inAlu2[31], inAlu2}),

        .res        (mul_res),
        .working    (mul_working),
        .finish     (mul_finish)
    );

    wire [31:0] quot, remainder;
    wire div_working, div_finish;
    wire div_cancel = div_working && ex_div;
    div u_div(
        .clk    (aclk),
        .resetn (aresetn),

        .en     (ex_div && !ec_exc_oc), // * 没发生异常
        .sign   (ex_mdsign),
        .A      (inAlu1),
        .B      (inAlu2),
        .cancel (div_cancel),

        .Q      (quot),
        .R      (remainder),

        .working(div_working),
        .finish (div_finish)
    );
    assign div_mul_stall = !ec_exc_oc && ((|ex_hiloren) || (|ex_hilowen)) && (div_working || mul_working);

    // * write HI LO
    // !TODO 如果变成关键路径可以将HI/LO放到 ec 段写
    wire [31:0] hiwdata =   ex_hilowen == 2'b10 ? inAlu1 : // *GPR[rs] -> HI
                            mul_finish ? mul_res[63:32] :
                            div_finish ? remainder : 32'b0;
    wire [31:0] lowdata =   ex_hilowen == 2'b01 ? inAlu1 : // *GPR[rs] -> LO
                            mul_finish ? mul_res[31:0] :
                            div_finish ? quot : 32'b0;
    wire [1:0] hilowen  =   ex_div || ex_mult || div_working || mul_working ? 2'b0 :
                            div_finish || mul_finish ? 2'b11 : ex_hilowen;
    hilo u_hilo(
        .clk    (aclk),
        .resetn (aresetn),
        
        .wen    (hilowen),
        .hiwdata(hiwdata),
        .lowdata(lowdata),
        .ren    (ex_hiloren),
        .exc_oc (ec_exc_oc && (|ex_hilowen)), // * mtc0指令且ec段异常发生
        .rdata  (ex_hilordata)
    );

    // *data_sram and cp0
    assign data_addr    = ex_daddr & 32'h1fff_ffff;
    assign data_wr      = |ex_data_wen;
    assign data_size    = ex_lsV[3] ? 2'b10 : {1'b0, ex_lsV[1]};
    wire notAlign       = (ex_data_wren[1] && data_addr[0] || data_addr[1:0] != 2'b00 && ex_data_wren[3]);
    assign ex_data_ADDRESS_ERROR =  notAlign && !(ec_data_req && ec_load) && ex_data_en;   

    wire [`EXBITS] EX_ex = {ex_ex[5:4], ex_IntegerOverflow, ex_ex[2:1], ex_data_ADDRESS_ERROR};
    assign data_req = !ec_exc_oc && !ex_data_ADDRESS_ERROR && ex_data_en;

    // * 重定向一致 ex_wdata, data_wdata
    assign data_wdata = {   {8{ex_lsV[3]}} & ex_wdata[31:24],
                            {8{ex_lsV[2]}} & ex_wdata[23:16],
                            {8{ex_lsV[1]}} & ex_wdata[15: 8],
                            {8{ex_lsV[0]}} & ex_wdata[7 : 0]} << {data_addr[1:0], 3'b0};
    assign data_wstrb = ex_data_wen << data_addr[1:0];

    // * cp0 addr compare here
    wire ex_cp0_badV_en        = ex_cp0addr == `CP0_BadVAddr;
    wire ex_cp0_count_en       = ex_cp0addr == `CP0_Count;
    wire ex_cp0_compare_en     = ex_cp0addr == `CP0_Compare;
    wire ex_cp0_status_en      = ex_cp0addr == `CP0_Status;
    wire ex_cp0_cause_en       = ex_cp0addr == `CP0_Cause;
    wire ex_cp0_epc_en         = ex_cp0addr == `CP0_EPC;

    ex_ec_seg u_ex_ec_seg(
        .clk    (aclk),
        .resetn (aresetn),

        .stall  (ex_ec_stall),
        .refresh(ex_ec_refresh),

        .ex_ex          (EX_ex),
        .ex_pc          (ex_pc),
        .ex_pc_8        (ex_pc_8),
        .ex_inst        (ex_inst),
        .ex_res         (ex_res),
        .ex_A           (inAlu1),
        .ex_B           (ex_wdata),
        .ex_load        (ex_load),
        .ex_loadX       (ex_loadX),
        .ex_lsV         (ex_lsV),
        .ex_bd          (ex_bd),
        .ex_data_addr   (ex_daddr[1:0]),
        .ex_regwen      (ex_regwen),
        .ex_wreg        (ex_wreg),
        .ex_data_req    (data_req),
        .ex_eret        (ex_eret),
        .ex_cp0wen      (ex_cp0wen),
        .ex_cp0addr     (ex_cp0addr),
        .ex_cp0ren      (ex_cp0ren),
        .ex_reorder_data(ex_reorder_data),

        .ex_cp0_badV_en     (ex_cp0_badV_en),
        .ex_cp0_count_en    (ex_cp0_count_en),
        .ex_cp0_compare_en  (ex_cp0_compare_en),
        .ex_cp0_status_en   (ex_cp0_status_en),
        .ex_cp0_cause_en    (ex_cp0_cause_en),
        .ex_cp0_epc_en      (ex_cp0_epc_en),

        .ex_btb_wen         (ex_btb_wen),
        .ex_btb_windex      (ex_btb_windex),
        .ex_btb_wtarget     (ex_btb_wtarget),

        .ex_gshare_wen      (ex_gshare_wen),
        .ex_gshare_windex   (ex_gshare_windex),
        .ex_bp_take         (ex_bp_take),

        .ex_op_bltz         (ex_op_bltz),
        .ex_op_bgez         (ex_op_bgez),
        .ex_op_beq          (ex_op_beq),
        .ex_op_bne          (ex_op_bne),
        .ex_op_blez         (ex_op_blez),
        .ex_op_bgtz         (ex_op_bgtz),
        .ex_wait_seg        (ex_wait_seg),

        // * O
        .ec_ex          (ec_ex),
        .ec_pc          (ec_pc),
        .ec_pc_8        (ec_pc_8),
        .ec_inst        (ec_inst),
        .ec_res         (ec_res),
        .ec_A           (ec_A),
        .ec_B           (ec_B),
        .ec_load        (ec_load),
        .ec_loadX       (ec_loadX),
        .ec_lsV         (ec_lsV),
        .ec_bd          (ec_bd),
        .ec_data_addr   (ec_data_addr),
        .ec_regwen      (ec_regwen),
        .ec_wreg        (ec_wreg),
        .ec_data_req    (ec_data_req),
        .ec_eret        (ec_eret),
        .ec_cp0wen      (ec_cp0wen),
        .ec_cp0addr     (ec_cp0addr),
        .ec_cp0ren      (ec_cp0ren),
        .ec_reorder_ex  (ec_reorder_ex),

        .ec_cp0_badV_en     (ec_cp0_badV_en),
        .ec_cp0_count_en    (ec_cp0_count_en),
        .ec_cp0_compare_en  (ec_cp0_compare_en),
        .ec_cp0_status_en   (ec_cp0_status_en),
        .ec_cp0_cause_en    (ec_cp0_cause_en),
        .ec_cp0_epc_en      (ec_cp0_epc_en),

        .ec_btb_wen         (ec_btb_wen),
        .ec_btb_windex      (ec_btb_windex),
        .ec_btb_wtarget     (ec_btb_wtarget),

        .ec_gshare_wen      (ec_gshare_wen),
        .ec_gshare_windex   (ec_gshare_windex),
        .ec_bp_take         (ec_bp_take),

        .ec_op_bltz         (ec_op_bltz),
        .ec_op_bgez         (ec_op_bgez),
        .ec_op_beq          (ec_op_beq),
        .ec_op_bne          (ec_op_bne),
        .ec_op_blez         (ec_op_blez),
        .ec_op_bgtz         (ec_op_bgtz),
        .ec_wait_seg        (ec_wait_seg)
    );

    // *EC
    wire [31:0] ec_ra = wb_wreg == ec_rs && wb_load ? wb_data_rdata : ec_A;
    check_branch u_check_branch_ec(
        .eq     (ec_ra == ec_wdata),
        .rega   (ec_ra),

        .op_bltz    (ec_op_bltz),
        .op_bgez    (ec_op_bgez),
        .op_beq     (ec_op_beq),
        .op_bne     (ec_op_bne),
        .op_blez    (ec_op_blez),
        .op_bgtz    (ec_op_bgtz),

        // * O
        .realj      (ec_realj)
    );

    assign ec_bp_error = ec_realj != ec_bp_take && ec_wait_seg == 2'b0
                       && ec_gshare_wen;

    // *mtc0的写入数据
    assign ec_wdata =   wb_wreg == ec_rt && wb_load ? wb_data_rdata : ec_B;
    // * load 
    wire [31:0] ec_data_rdata = data_rdata >> {ec_res[1:0], 3'b0};
    wire [31:0] ec_rdata;
    assign ec_rdata[7 : 0] =    {8{ec_lsV[0]}} & ec_data_rdata[7:0];
    assign ec_rdata[15: 8] =    {8{ec_lsV[1]}} & ec_data_rdata[15:8] |
                                {8{!ec_lsV[1] && ec_lsV[0] && ec_loadX && ec_data_rdata[7]}};
    assign ec_rdata[31:16] =    {16{ec_lsV[2] && ec_lsV[3]}} & ec_data_rdata[31:16]   |
                                {16{!ec_lsV[2] && !ec_lsV[3] && ec_lsV[1] && ec_loadX && ec_data_rdata[15]}} |
                                {16{!ec_lsV[2] && !ec_lsV[3] && !ec_lsV[1] && ec_lsV[0] && ec_loadX && ec_data_rdata[7]}};

    ec u_ec(
        .ext_int        (ext_int),
        .clk            (aclk),
        .resetn         (aresetn),

        .ec_ex          (ec_ex),
        .ec_pc          (ec_pc),
        .ec_res         (ec_res),
        .ec_load        (ec_load),

        .ex_cp0ren      (ex_cp0ren),
        .ex_cp0raddr    (ex_cp0addr),

        .ec_cp0wen      (ec_cp0wen),
        .ec_cp0waddr    (ec_cp0addr),
        .ec_wdata       (ec_wdata),
        
        .ec_bd          (ec_bd),
        .ec_eret        (ec_eret),
        // * EX 段读 EC 段写
        .rcp0_badV_en   (ex_cp0_badV_en),
        .rcp0_count_en  (ex_cp0_count_en),
        .rcp0_compare_en(ex_cp0_compare_en),
        .rcp0_status_en (ex_cp0_status_en),
        .rcp0_cause_en  (ex_cp0_cause_en),
        .rcp0_epc_en    (ex_cp0_epc_en),

        .wcp0_badV_en   (ec_cp0_badV_en),
        .wcp0_count_en  (ec_cp0_count_en),
        .wcp0_compare_en(ec_cp0_compare_en),
        .wcp0_status_en (ec_cp0_status_en),
        .wcp0_cause_en  (ec_cp0_cause_en),
        .wcp0_epc_en    (ec_cp0_epc_en),

        .ec_reorder_ex  (ec_reorder_ex),
        .wb_eret        (wb_eret),

        // * O
        .exc_oc             (ec_exc_oc),

        .ext_int_response   (ext_int_response),
        .cp0rdata           (ex_cp0rdata),
        .cp0_epc            (cp0_epc),
        .reorder_data       (ec_reorder_data)
    );

    ec_wb_seg u_ec_wb_seg(
        .clk    (aclk),
        .resetn (aresetn),

        .stall  (ec_wb_stall),
        .refresh(ec_wb_refresh),

        .ec_data_rdata  (ec_rdata),
        .ec_pc          (ec_pc),
        .ec_inst        (ec_inst),
        .ec_load        (ec_load),
        .ec_regwen      (ec_regwen),
        .ec_wreg        (ec_wreg),
        .ec_eret        (ec_eret),
        .ec_reorder_data(ec_reorder_data),

        .wb_data_rdata  (wb_data_rdata),
        .wb_pc          (wb_pc),
        .wb_inst        (wb_inst),
        .wb_load        (wb_load),
        .wb_regwen      (wb_regwen),
        .wb_wreg        (wb_wreg),
        .wb_eret        (wb_eret),
        .wb_reorder_ec  (wb_reorder_ec)
    );

    // *WB
    wb u_wb(
        .data_rdata     (wb_data_rdata),
        .wb_load        (wb_load),
        .wb_reorder_ec  (wb_reorder_ec),

        // * O
        .wb_reorder_data(wb_reorder_data)
    );

    // *debug
    assign debug_wb_pc          = wb_pc;
    assign debug_wb_rf_wen      = {4{wb_regwen && !ec_wb_stall}};
    assign debug_wb_rf_wnum     = wb_wreg;
    assign debug_wb_rf_wdata    = wb_reorder_data;

endmodule
