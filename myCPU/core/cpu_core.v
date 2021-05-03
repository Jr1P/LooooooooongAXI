`timescale 1ns / 1ps
`include "./head.vh"

// * five segment pipeline cpu
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

    // input           hit_when_refill_i,
    // input   [31:0]  hit_when_refill_word_i,

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
    // TODO: TLB exceptions refill, invalid, modified
    wire    if_inst_ADDRESS_ERROR;
    wire    id_ReservedIns;
    wire    ex_IntegerOverflow, id_BreakEx, id_SyscallEx;
    wire    ex_data_ADDRESS_ERROR;
    // *ID
    wire        id_addr_error;
    wire [31:0] id_pc;
    wire [31:0] id_inst;
    wire [4 :0] id_rs = `GET_Rs(id_inst);
    wire [4 :0] id_rt = `GET_Rt(id_inst);
    wire        id_bd;
    wire        id_jump;
    wire        id_branch;
    wire [31:0] id_target;
    wire        id_al;
    wire        id_SPEC;
    wire        id_rs_ren;
    wire        id_rt_ren;
    wire [5 :0] id_ifunc;
    wire        id_load;
    wire        id_loadX;
    wire [3 :0] id_lsV;
    wire        id_imm;
    wire [1 :0] id_immXtype;
    wire        id_eret;
    wire        id_data_en;
    wire [3 :0] id_data_ren;
    wire [3 :0] id_data_wen;
    wire        id_regwen;
    wire [4 :0] id_wreg;
    wire        id_cp0ren;
    wire        id_cp0wen;
    wire [7 :0] id_cp0addr;
    wire        id_mult;
    wire        id_div;
    wire        id_mdsign;
    wire [1 :0] id_hiloren;
    wire [1 :0] id_hilowen;
    // *EX
    wire ex_addr_error;
    wire [`NUM_EX_1-1:0] ex_ex;
    wire [31:0] ex_pc;
    wire [31:0] ex_inst;
    wire [4 :0] ex_rs = `GET_Rs(ex_inst);
    wire [4 :0] ex_rt = `GET_Rt(ex_inst);
    wire [31:0] ex_res;
    wire        ex_imm;
    wire [31:0] ex_Imm;
    wire [31:0] ex_A;
    wire [31:0] ex_B;
    wire        ex_rs_ren;
    wire        ex_rt_ren;
    wire        ex_al;
    wire        ex_SPEC;
    wire        ex_load;
    wire        ex_loadX;
    wire [3 :0] ex_lsV;
    wire        ex_bd;
    wire [5 :0] ex_ifunc;
    wire        ex_regwen;
    wire [4 :0] ex_wreg;
    wire        ex_data_en;
    wire [3 :0] ex_data_ren;
    wire [3 :0] ex_data_wen;
    wire [31:0] ex_wdata;
    wire        ex_eret;
    wire        ex_exc_oc;
    wire        ex_cp0ren;
    wire [31:0] ex_cp0rdata;
    wire        ex_cp0wen;
    wire [7 :0] ex_cp0addr;
    wire        ex_mult;
    wire        ex_div;
    wire        ex_mdsign;
    wire [1 :0] ex_hilowen;
    wire [1 :0] ex_hiloren;
    wire [31:0] ex_hilordata;
    // *WB
    wire [31:0] wb_pc;
    wire [31:0] wb_inst;
    wire [31:0] wb_res;
    wire [31:0] wb_rdata;
    wire        wb_load;
    wire        wb_loadX;
    wire [3 :0] wb_lsV;
    wire [1 :0] wb_data_addr;
    wire        wb_al;
    wire        wb_regwen;
    wire [4 :0] wb_wreg;
    wire        wb_data_req;
    wire        wb_eret;
    wire        wb_cp0ren;
    wire [31:0] wb_cp0rdata;
    wire [1 :0] wb_hiloren;
    wire [31:0] wb_hilordata;
    wire        wb_hit_when_refill;

    wire [31:0] cp0_epc;

    wire    pre_ins;

    wire    if_id_stall;
    wire    id_ex_stall;
    wire    ex_wb_stall;

    wire    if_id_refresh;
    wire    id_ex_refresh;
    wire    ex_wb_refresh;
    wire    ex_wb_write_disable;
    wire    wb_last_refresh;

    wire    div_stall;

    assign inst_cache = 1'b1; // * TLB相关，后续需要修改
    assign data_cache = !(ex_res[31:29] == 3'b101);
    assign cache_req = 1'b0;
    assign cache_op = 7'b0;
    assign cache_tag = 32'b0;

    reg inst_cache_state;
    reg data_cache_state;
    parameter IDLE          =   1'b0;
    parameter BUSY          =   1'b1;
    always @(posedge aclk)
        inst_cache_state    <=  !aresetn        ? IDLE :
                                inst_addr_ok    ? BUSY :
                                inst_data_ok    ? IDLE :
                                inst_cache_state       ;
    
    wire ext_int_response; // TODO:
    wire ext_int_soft;
    wire id_branch_target_address_error;  // * jump到的地址不对齐，取指异常
    assign inst_req = (!inst_cache_state || inst_data_ok) && !if_inst_ADDRESS_ERROR && !ext_int_response /*&& !id_branch_target_address_error*/;
    wire inst_stall;
    cu u_cu(
        .id_pc      (id_pc),

        .inst_req       (inst_req),
        .inst_addr_ok   (inst_addr_ok),
        .inst_data_ok   (inst_data_ok || (if_inst_ADDRESS_ERROR && !id_bd) || id_addr_error),

        .data_req_pre   (wb_data_req && wb_load),   // * 取数请求
        .data_req       (data_req || (data_cache_state && ex_data_en && !ext_int_response && !ex_data_ADDRESS_ERROR)), // * data_cache_state == 1 -> busy
        .data_addr_ok   (data_addr_ok),
        .data_data_ok   (data_data_ok),
        .data_wr        (data_wr),

        .ext_int_soft   (ext_int_soft),

        .ex_rs_ren  (ex_rs_ren),
        .ex_rs      (ex_rs),
        .ex_rt_ren  (ex_rt_ren),
        .ex_rt      (ex_rt),

        .exc_oc     (ex_exc_oc),
        .eret       (ex_eret),

        .id_branch  (id_branch),
        .id_rs_ren  (id_rs_ren),
        .id_rs      (id_rs),
        .id_rt_ren  (id_rt_ren),
        .id_rt      (id_rt),

        .ex_regwen  (ex_regwen),    
        .ex_load    (ex_load),
        .ex_cp0ren  (ex_cp0ren),
        .ex_wreg    (ex_wreg),

        .pre_ins    (pre_ins),
        .div_stall  (div_stall),

        .if_id_stall    (if_id_stall),
        .id_ex_stall    (id_ex_stall),
        .ex_wb_stall    (ex_wb_stall),

        .if_id_refresh  (if_id_refresh),
        .id_ex_refresh  (id_ex_refresh),
        .ex_wb_refresh  (ex_wb_refresh)
        // .ex_wb_write_disable    (ex_wb_write_disable)
    );

    // * 重定向数据
    wire [31:0] ex_reorder_data =   {32{|ex_hiloren}} & ex_hilordata    |   //* ex段读HI/LO写ex段的rs
                                    {32{ex_al}      } & (ex_pc+32'd8)   |   //* ex段al写GPR[31]
                                    {32{ex_cp0ren}  } & ex_cp0rdata     |
                                    {32{!ex_load && !ex_cp0ren && !(|ex_hiloren) && !ex_al}} & ex_res;

    wire [31:0] wb_reorder_data =   {32{wb_load}    } & wb_rdata        |   //* wb段load写rs
                                    {32{wb_cp0ren}  } & wb_cp0rdata     |   //* wb段读cp0写rs
                                    {32{|wb_hiloren}} & wb_hilordata    |   //* wb段读HI/LO写rs
                                    {32{wb_al}      } & (wb_pc+32'd8)   |   //* wb段al写GPR[31]
                                    {32{!wb_load && !wb_cp0ren && !(|wb_hiloren) && !wb_al}} & wb_res;

    // *IF
    wire [31:0] npc;

    pc u_pc(
        .clk            (aclk),
        .resetn         (aresetn),
        .stall          (if_id_stall),
        .BranchTarget   (id_target),
        .BranchTake     (id_jump && id_branch),
        .exc_oc         (ex_exc_oc),

        .eret           (id_eret),  // * eret
        .epc            (cp0_epc),  // * epc from cp0
        .npc            (npc)
    );

    assign inst_addr = !pre_ins ? npc : npc-32'd4;
    assign if_inst_ADDRESS_ERROR = inst_addr[1:0] != 2'b00;

    reg exc_oc_invalid; // * 异常发生后紧接着取出的指令不是正确指令
    always @(posedge aclk) begin
        if(!aresetn) exc_oc_invalid <= 1'b0;
        else exc_oc_invalid <=  ex_exc_oc ? 1'b1 :
                                exc_oc_invalid ? if_id_stall || if_id_refresh : 1'b0;
    end

    if_id_seg u_if_id_seg(
        .clk    (aclk),
        .resetn (aresetn),

        .stall  (if_id_stall),
        .refresh(if_id_refresh),

        .id_branch      (id_branch),
        .if_addr_error  (if_inst_ADDRESS_ERROR),
        .if_pc          (inst_addr),
        // .if_inst        (inst_rdata),

        .id_bd          (id_bd),
        .id_addr_error  (id_addr_error),
        .id_pc          (id_pc)
        // .id_inst        (last_inst)
    );

    // *ID
    wire [31:0] inRegData;
    wire [31:0] regouta, regoutb;
    wire [31:0] id_Imm  =   id_immXtype == 2'b00 ? {16'b0, `GET_Imm(id_inst)}           :   // zero extend
                            id_immXtype == 2'b01 ? {{16{id_inst[15]}}, `GET_Imm(id_inst)} : // signed extend
                            {`GET_Imm(id_inst), 16'b0};                                     // {imm, {16{0}}}
    
    assign id_inst  = exc_oc_invalid || !inst_data_ok ? 32'b0 : inst_rdata; // * exc_oc 后一条以及 inst_data_ok低时都是无效指令

    regfile u_regfile(
        .clk    (aclk),
        .resetn (aresetn),
        .rs     (id_rs),
        .rt     (id_rt),
        .wen    (wb_regwen && !ex_wb_stall), // * wb被暂停不写
        .wreg   (wb_wreg),
        .wdata  (inRegData),

        .outA   (regouta),
        .outB   (regoutb)
    );

    wire [31:0] re_rs = id_branch && id_rs_ren ? 
                            ex_regwen && ex_wreg == id_rs   ? ex_reorder_data   :
                            wb_regwen && wb_wreg == id_rs   ? wb_reorder_data   : regouta
                        : 32'b0;
    wire [31:0] re_rt = id_branch && id_rt_ren ?
                            ex_regwen && ex_wreg == id_rt   ? ex_reorder_data   :
                            wb_regwen && wb_wreg == id_rt   ? wb_reorder_data   : regoutb
                        : 32'b0;

    id u_id(
        .id_inst    (id_inst),
        .id_pc      (id_pc),
        .rega       (re_rs),
        .regb       (re_rt),

        .branch     (id_branch),
        .jump       (id_jump),
        .al         (id_al),
        .target     (id_target),
        .SPEC       (id_SPEC),
        .rs_ren     (id_rs_ren),
        .rt_ren     (id_rt_ren),
        .load       (id_load),
        .loadX      (id_loadX),
        .lsV        (id_lsV),
        .imm        (id_imm),
        .immXtype   (id_immXtype),
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
        .cp0ren     (id_cp0ren),
        .cp0wen     (id_cp0wen),
        .cp0addr    (id_cp0addr),
        .func       (id_ifunc),

        .eret       (id_eret),
        .ReservedIns(id_ReservedIns),
        .BreakEx    (id_BreakEx),
        .SyscallEx  (id_SyscallEx)
    );

    wire [`NUM_EX_1-1:0] id_ex = {id_ReservedIns, 1'b0, id_BreakEx, id_SyscallEx, 1'b0};
    assign id_branch_target_address_error = id_branch && id_jump && id_target[1:0] != 2'b00;

    id_ex_seg u_id_ex_seg(
        .clk    (aclk),
        .resetn (aresetn),

        .stall  (id_ex_stall),
        .refresh(id_ex_refresh),

        .id_addr_error(id_addr_error/* || id_branch_target_address_error*/),
        .id_ex      (id_ex),
        .id_pc      (id_pc),
        .id_inst    (id_inst), // * avoid timing loop
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
        .id_bd      (id_bd),
        .id_ifunc   (id_ifunc),
        .id_regwen  (id_regwen),
        .id_wreg    (id_wreg),
        .id_data_en (id_data_en),
        .id_data_ren(id_data_ren),
        .id_data_wen(id_data_wen),
        .id_eret    (id_eret),
        .id_cp0ren  (id_cp0ren),
        .id_cp0wen  (id_cp0wen),
        .id_cp0addr (id_cp0addr),
        .id_mult    (id_mult),
        .id_div     (id_div),
        .id_mdsign  (id_mdsign),
        .id_hiloren (id_hiloren),
        .id_hilowen (id_hilowen),

        .ex_addr_error(ex_addr_error),
        .ex_ex      (ex_ex),
        .ex_pc      (ex_pc),
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
        .ex_bd      (ex_bd),
        .ex_ifunc   (ex_ifunc),
        .ex_regwen  (ex_regwen),
        .ex_wreg    (ex_wreg),
        .ex_data_en (ex_data_en),
        .ex_data_ren(ex_data_ren),
        .ex_data_wen(ex_data_wen),
        .ex_eret    (ex_eret),
        .ex_cp0ren  (ex_cp0ren),
        .ex_cp0wen  (ex_cp0wen),
        .ex_cp0addr (ex_cp0addr),
        .ex_mult    (ex_mult),
        .ex_div     (ex_div),
        .ex_mdsign  (ex_mdsign),
        .ex_hiloren (ex_hiloren),
        .ex_hilowen (ex_hilowen)
    );

    // *EX
    wire [31:0] inAlu1  =   wb_wreg == ex_rs && wb_regwen ? wb_reorder_data : ex_A;
    wire [31:0] inAlu2  =   ex_imm ? ex_Imm : 
                            wb_wreg == ex_rt && wb_regwen ? wb_reorder_data : ex_B;
    wire [5 :0] ex_func =   ex_SPEC ? `GET_FUNC(ex_inst) : ex_ifunc;

    alu u_alu(
        .A      (inAlu1),
        .B      (inAlu2),
        .func   (ex_func),
        .sa     (`GET_SA(ex_inst)),

        .IntegerOverflow    (ex_IntegerOverflow),
        .res                (ex_res)
    );

    wire [63:0] mul_res, mul_signed_res;
    mul u_mul(
        .A      (inAlu1),
        .B      (inAlu2),

        .res        (mul_res),
        .signedres  (mul_signed_res)
    );

    wire [31:0] quot, remainder;
    wire div_working, div_finish;
    wire div_cancel = div_working && ex_div;
    assign div_stall = ((|ex_hiloren) || (|ex_hilowen)) && div_working;
    div u_div(
        .clk    (aclk),
        .resetn (aresetn),

        .en     (ex_div),
        .sign   (ex_mdsign),
        .A      (inAlu1),
        .B      (inAlu2),
        .cancel (div_cancel),

        .Q      (quot),
        .R      (remainder),

        .working(div_working),
        .finish (div_finish)
    );

    // * write HI LO
    wire [31:0] hiwdata =   ex_hilowen == 2'b10 ? inAlu1 : // *GPR[rs] -> HI
                            ex_mult ?
                                {32{!ex_mdsign} } & mul_res[63:32] |
                                {32{ex_mdsign}  } & mul_signed_res[63:32] :
                            remainder;
    wire [31:0] lowdata =   ex_hilowen == 2'b01 ? inAlu1 : // *GPR[rs] -> LO
                            ex_mult ?
                                {32{!ex_mdsign} } & mul_res[31:0] |
                                {32{ex_mdsign}  } & mul_signed_res[31:0] :
                            quot;
    wire [1:0] hilowen = ex_div || div_working ? 2'b0 : div_finish ? 2'b11 : ex_hilowen;
    hilo u_hilo(
        .clk    (aclk),
        .resetn (aresetn),
        
        .wen    (hilowen),
        .hiwdata(hiwdata),
        .lowdata(lowdata),
        .ren    (ex_hiloren),
        .exc_oc (ex_exc_oc),
        .rdata  (ex_hilordata)
    );

    // *store命令写入的数据, mtc0命令的写入数据
    assign ex_wdata = wb_wreg == ex_rt && wb_regwen ? wb_reorder_data : ex_B;

    always @(posedge aclk)
        data_cache_state    <=  !aresetn        ? IDLE :
                                data_addr_ok    ? BUSY :
                                data_data_ok    ? IDLE :
                                data_cache_state       ;

    // *data_sram and cp0
    assign data_addr = ex_res & 32'h1fff_fffc;
    assign data_wr = |ex_data_wen;
    assign data_size = ex_lsV[3] ? 2'b10 : ex_lsV[1] ? 2'b01 : 2'b00;
    assign ex_data_ADDRESS_ERROR = ex_data_en && (ex_load && (ex_data_ren == 4'b0011 && ex_res[0] || ex_data_ren == 4'b1111 && ex_res[1:0] != 2'b00)
                                    || !ex_load && (ex_data_wen == 4'b0011 && ex_res[0] || ex_data_wen == 4'b1111 && ex_res[1:0] != 2'b00));
    wire ex_data_req = data_req;

    wire [`EXBITS] EX_ex = {ex_addr_error, ex_ex} | {2'b0, ex_IntegerOverflow, 2'b0, ex_data_ADDRESS_ERROR};
    assign data_req = (!data_cache_state || data_data_ok) && ex_data_en && !ext_int_response && !(|EX_ex);
    wire [4:0] exc_excode = ext_int ? `EXC_INT :
                            EX_ex[5] ? `EXC_AdEL : // *取指地址错
                            EX_ex[4] ? `EXC_RI :   // *RI
                            EX_ex[3] ? `EXC_Ov :   // *Overflow
                            EX_ex[2] ? `EXC_Bp :   // *Break point
                            EX_ex[1] ? `EXC_Sys :  // *syscall
                            EX_ex[0] ? 
                                ex_load ? `EXC_AdEL : `EXC_AdES
                            : 5'b0;
    wire [31:0] exc_epc = ex_bd/* || ext_int_soft*/ ? ex_pc-32'd4 : ex_pc;
    wire [31:0] cp0_status, cp0_cause;  // * cp0cause not use for now
    wire exc_valid = cp0_status[`Status_EXL] ? !wb_eret : // * valid 1 : 表示有例外在处理, 刚传到ex段的例外也算属于在处理
                    ext_int_response ? 1'b1 : |EX_ex;
    wire [31:0] cp0_wdata = ex_wdata;

    // * 重定向一致 cp0_wdata, data_wdata
    assign data_wdata = {   {8{ex_lsV[3]}} & cp0_wdata[31:24],
                            {8{ex_lsV[2]}} & cp0_wdata[23:16],
                            {8{ex_lsV[1]}} & cp0_wdata[15: 8],
                            {8{ex_lsV[0]}} & cp0_wdata[7 : 0]} << {ex_res[1:0], 3'b0};
    assign data_wstrb = ex_data_wen << ex_res[1:0];

    assign ex_exc_oc = !cp0_status[`Status_EXL] && exc_valid;
    wire [31:0] exc_badvaddr = EX_ex[5] ? ex_pc : ex_res; // FIXME: ex_pc可能需要修改，取地址错误的地址不一定是ex_pc
    // * CP0 regs
    cp0 u_cp0(
        .clk    (aclk),
        .resetn (aresetn),

        .ext_int            (ext_int),
        .ext_int_response   (ext_int_response),
        .ext_int_soft       (ext_int_soft), // * 指示本条指令是否写ip_software且会在下一个周期产生软件中断

        .wen    (ex_cp0wen),
        .addr   (ex_cp0addr),
        .wdata  (cp0_wdata),
        .rdata  (ex_cp0rdata),

        .exc_valid      (exc_valid),
        .exc_excode     (exc_excode),
        .exc_bd         (ex_bd),
        .exc_epc        (exc_epc),   // * 中断的时候epc 也给ex段的pc
        .exc_badvaddr   (exc_badvaddr),
        .exc_eret       (ex_eret),

        .cause      (cp0_cause),
        .status     (cp0_status),
        .epc        (cp0_epc)
    );

    ex_wb_seg u_ex_wb_seg(
        .clk    (aclk),
        .resetn (aresetn),

        .stall  (ex_wb_stall),
        .refresh(ex_wb_refresh),

        .hit_when_refill_i  (hit_when_refill_i),

        .ex_pc          (ex_pc),
        .ex_inst        (ex_inst),
        .ex_res         (ex_res),
        .ex_load        (ex_load),
        .ex_loadX       (ex_loadX),
        .ex_lsV         (ex_lsV),
        .ex_data_addr   (ex_res[1:0]),
        .ex_al          (ex_al),
        .ex_regwen      (ex_regwen),
        .ex_wreg        (ex_wreg),
        .ex_data_req    (ex_data_req),
        .ex_eret        (ex_eret),
        .ex_cp0ren      (ex_cp0ren),
        .ex_cp0rdata    (ex_cp0rdata),
        .ex_hiloren     (ex_hiloren),
        .ex_hilordata   (ex_hilordata),

        .wb_hit_when_refill (wb_hit_when_refill),

        .wb_pc          (wb_pc),
        .wb_inst        (wb_inst),
        .wb_res         (wb_res),
        .wb_load        (wb_load),
        .wb_loadX       (wb_loadX),
        .wb_lsV         (wb_lsV),
        .wb_data_addr   (wb_data_addr),
        .wb_al          (wb_al),
        .wb_regwen      (wb_regwen),
        .wb_wreg        (wb_wreg),
        .wb_data_req    (wb_data_req),
        .wb_eret        (wb_eret),
        .wb_cp0ren      (wb_cp0ren),
        .wb_cp0rdata    (wb_cp0rdata),
        .wb_hiloren     (wb_hiloren),
        .wb_hilordata   (wb_hilordata)
    );

    wire [31:0] wb_data_rdata = data_rdata >> {wb_data_addr, 3'b0};

    assign wb_rdata[7 : 0] =    {8{wb_lsV[0]}} & wb_data_rdata[7:0];
    assign wb_rdata[15: 8] =    {8{wb_lsV[1]}} & wb_data_rdata[15:8] |
                                {8{!wb_lsV[1] && wb_lsV[0] && wb_loadX && wb_data_rdata[7]}};
    assign wb_rdata[31:16] =    {16{wb_lsV[2] && wb_lsV[3]}} & wb_data_rdata[31:16]   |
                                {16{!wb_lsV[2] && !wb_lsV[3] && wb_lsV[1] && wb_loadX && wb_data_rdata[15]}} |
                                {16{!wb_lsV[2] && !wb_lsV[3] && !wb_lsV[1] && wb_lsV[0] && wb_loadX && wb_data_rdata[7]}};

    // *WB
    assign inRegData = wb_reorder_data;

    // *debug
    assign debug_wb_pc          = wb_pc;
    assign debug_wb_rf_wen      = {4{wb_regwen && !ex_wb_stall}};
    assign debug_wb_rf_wnum     = wb_wreg;
    assign debug_wb_rf_wdata    = inRegData;

endmodule
