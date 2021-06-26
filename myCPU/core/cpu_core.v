`timescale 1ns / 1ps
`include "./head.vh"

// * four segment pipeline cpu
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
    // TODO: TLB exceptions refill, invalid, modified
    wire    if_inst_ADDRESS_ERROR;
    wire    ex_IntegerOverflow;
    wire    ex_data_ADDRESS_ERROR;
    // *ID
    wire [31:0]     regouta, regoutb;
    wire            id_addr_error;
    wire [`EXBITS]  id_ex;

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
    wire [31:0] id_Imm;
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
    wire [`EXBITS]  ex_ex;

    wire [31:0] ex_pc;
    wire [31:0] ex_inst;
    wire [4 :0] ex_rs = `GET_Rs(ex_inst);
    wire [4 :0] ex_rt = `GET_Rt(ex_inst);
    wire [31:0] ex_res;
    wire        ex_imm;
    wire [31:0] ex_Imm;
    wire [31:0] ex_A;
    wire [31:0] ex_B;
    wire [31:0] ex_daddr;
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

    // *cp0
    wire ext_int_response; // TODO:
    wire ext_int_soft;
    wire [31:0] cp0_epc;
    // *WB
    wire [31:0] wb_pc;
    wire [31:0] wb_inst;
    wire [31:0] wb_res;
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
    wire [31:0] wb_reorder_data;
    // * CU
    wire        pre_ins;
    wire [1:0]  id_recode;

    wire    inst_stall;

    wire    if_id_stall;
    wire    id_ex_stall;
    wire    ex_wb_stall;

    wire    if_id_refresh;
    wire    id_ex_refresh;
    wire    ex_wb_refresh;

    wire    div_mul_stall;

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

    assign inst_req = (!inst_cache_state || inst_data_ok) && !if_inst_ADDRESS_ERROR && !ext_int_response;
    cu u_cu(
        .id_pc      (id_pc),

        .inst_req       (inst_req),
        .inst_addr_ok   (inst_addr_ok),
        .inst_data_ok   (inst_data_ok || (if_inst_ADDRESS_ERROR && !id_bd) || id_addr_error),

        .wb_data_req    (wb_data_req && wb_load),   // * 取数请求
        .wb_regwen      (wb_regwen),
        .wb_wreg        (wb_wreg),
        .data_req       (data_req || (data_cache_state && ex_data_en && !ext_int_response && !ex_data_ADDRESS_ERROR)), // * data_cache_state == 1 -> busy
        .data_addr_ok   (data_addr_ok),
        .data_data_ok   (data_data_ok),

        .ext_int_soft   (ext_int_soft),

        .ex_rs_ren  (ex_rs_ren),
        .ex_rs      (ex_rs),
        .ex_rt_ren  (ex_rt_ren),
        .ex_rt      (ex_rt),

        .exc_oc     (ex_exc_oc),
        .eret       (id_eret),

        .id_branch  (id_branch),
        .id_rs_ren  (id_rs_ren),
        .id_rs      (id_rs),
        .id_rt_ren  (id_rt_ren),
        .id_rt      (id_rt),

        // .ex_regwen  (ex_regwen),    
        .ex_load    (ex_load && data_req),
        .ex_wreg    (ex_wreg),

        .div_mul_stall  (div_mul_stall),
        // * O
        .pre_ins        (pre_ins),
        .id_recode      (id_recode),
        .inst_stall     (inst_stall),

        .if_id_stall    (if_id_stall),
        .id_ex_stall    (id_ex_stall),
        .ex_wb_stall    (ex_wb_stall),

        .if_id_refresh  (if_id_refresh),
        .id_ex_refresh  (id_ex_refresh),
        .ex_wb_refresh  (ex_wb_refresh)
    );

    // * 重定向数据
    wire [31:0] ex_reorder_data =   (|ex_hiloren)   ?   ex_hilordata    :   //* ex段读HI/LO写ex段的rs
                                    ex_al           ?   ex_pc+32'd8     :   //* ex段al写GPR[31]
                                    ex_cp0ren       ?   ex_cp0rdata     :
                                                        ex_res          ;

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

    assign inst_addr = pre_ins/* || (id_recode && !inst_stall)*/ ? npc-32'd4 : npc;
    assign if_inst_ADDRESS_ERROR = npc[1]|npc[0];

    reg exc_oc_invalid; // * 异常发生后紧接着取出的指令不是正确指令
    always @(posedge aclk) begin
        if(!aresetn)    exc_oc_invalid <=   1'b0;
        else            exc_oc_invalid <=   ex_exc_oc || (exc_oc_invalid && (if_id_stall || if_id_refresh));
    end

    if_id_seg u_if_id_seg(
        .clk    (aclk),
        .resetn (aresetn),

        .stall  (if_id_stall),
        .refresh(if_id_refresh),

        .id_branch      (id_branch),
        .if_addr_error  (if_inst_ADDRESS_ERROR),
        .if_pc          (inst_addr),

        .id_bd          (id_bd),
        .id_addr_error  (id_addr_error),
        .id_pc          (id_pc)
    );

    // *ID 
    // *                exc_oc 后一条以及 inst_data_ok低时都是无效指令
    assign id_inst  =   exc_oc_invalid || !inst_data_ok || id_addr_error    ?   32'b0   : 
                        /*id_recode                                           ?   ex_inst :*/
                        inst_rdata;

    wire [4:0] regfile_rs = id_recode ? ex_rs : id_rs;
    wire [4:0] regfile_rt = id_recode ? ex_rt : id_rt;

    regfile u_regfile(
        .clk    (aclk),
        .resetn (aresetn),
        .rs     (regfile_rs),
        .rt     (regfile_rt),
        .wen    (wb_regwen && !ex_wb_stall), // * wb被暂停不写
        .wreg   (wb_wreg),
        .wdata  (wb_reorder_data),

        .outA   (regouta),
        .outB   (regoutb)
    );

    wire [31:0] re_rs =     ex_regwen && ex_wreg == id_rs   ? ex_reorder_data   :
                            wb_regwen && wb_wreg == id_rs   ? wb_reorder_data   : regouta;
    wire [31:0] re_rt =     ex_regwen && ex_wreg == id_rt   ? ex_reorder_data   :
                            wb_regwen && wb_wreg == id_rt   ? wb_reorder_data   : regoutb;

    // wire [31:0] id_rpc = id_recode ? ex_pc : id_pc;

    id u_id(
        .id_addr_error  (id_addr_error),

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
        .recode (id_recode),

        // .wb_reorder_data    (wb_reorder_data),

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
        .daddr              (ex_daddr),
        .res                (ex_res)
    );

    wire [65:0] mul_res;
    wire mul_working, mul_finish;
    wire mul_cancel = mul_working && ex_mult;

    mul u_mul(
        .clk    (aclk),
        .resetn (aresetn),
        .en     (ex_mult),
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
    assign div_mul_stall = !ex_exc_oc && ((|ex_hiloren) || (|ex_hilowen)) && (div_working || mul_working);
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
    assign data_addr = ex_daddr & 32'h1fff_ffff;
    assign data_wr = |ex_data_wen;
    assign data_size = ex_lsV[3] ? 2'b10 : ex_lsV[1] ? 2'b01 : 2'b00;
    assign ex_data_ADDRESS_ERROR = !(wb_data_req && wb_load && !data_data_ok) && ex_data_en && (ex_load && (ex_data_ren == 4'b0011 && data_addr[0] || ex_data_ren == 4'b1111 && data_addr[1:0] != 2'b00)
                                    || !ex_load && (ex_data_wen == 4'b0011 && data_addr[0] || ex_data_wen == 4'b1111 && data_addr[1:0] != 2'b00));
    wire ex_data_req = data_req;

    wire [`EXBITS] EX_ex = ex_ex | {2'b0, ex_IntegerOverflow, 2'b0, ex_data_ADDRESS_ERROR};
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
    wire [31:0] exc_epc = ex_bd ? ex_pc-32'd4 : ex_pc;
    wire [31:0] cp0_status, cp0_cause;  // * cp0cause not use for now
     // * 如果wb段eret了，就看ex段有没有新异常提交
    wire exc_valid =    cp0_status[`Status_EXL] && !wb_eret ? 1'b1 // * exl位高表示在异常处理
                        : (ext_int_response || (|EX_ex));
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

    // *WB
    wb u_wb(
        .data_rdata     (data_rdata),
        .wb_pc          (wb_pc),
        .wb_res         (wb_res),
        .wb_load        (wb_load),
        .wb_loadX       (wb_loadX),
        .wb_lsV         (wb_lsV),
        .wb_data_addr   (wb_data_addr),
        .wb_al          (wb_al),
        .wb_cp0ren      (wb_cp0ren),
        .wb_cp0rdata    (wb_cp0rdata),
        .wb_hiloren     (wb_hiloren),
        .wb_hilordata   (wb_hilordata),

        // * O
        .wb_reorder_data(wb_reorder_data)
    );

    // *debug
    assign debug_wb_pc          = wb_pc;
    assign debug_wb_rf_wen      = {4{wb_regwen && !ex_wb_stall}};
    assign debug_wb_rf_wnum     = wb_wreg;
    assign debug_wb_rf_wdata    = wb_reorder_data;

endmodule
