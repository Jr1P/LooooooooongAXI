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
    wire    if_inst_ADDRESS_ERROR;
    wire    ex_IntegerOverflow;
    wire    ex_data_ADDRESS_ERROR;
    // * IF
    wire [31:0]     npc;
    // *ID
    wire [31:0]     regouta, regoutb;
    wire            id_addr_error;
    wire [`EXBITS]  id_ex;

    wire [31:0]     id_pc;
    wire            id_inst_req;
    wire [31:0]     id_inst;
    wire [4 :0]     id_rs = `GET_Rs(id_inst);
    wire [4 :0]     id_rt = `GET_Rt(id_inst);
    wire            id_bd;
    wire            id_jump;
    wire            id_branch;
    wire [31:0]     id_target;
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
    // *EX
    wire [`EXBITS]  ex_ex;
    wire [31:0]     ex_pc;
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
    wire            ex_bd;
    wire [5 :0]     ex_ifunc;
    wire            ex_regwen;
    wire [4 :0]     ex_wreg;
    wire            ex_data_en;
    wire [3 :0]     ex_data_ren;
    wire [3 :0]     ex_data_wen;
    wire [31:0]     ex_wdata;
    wire            ex_eret;
    wire            ex_cp0ren;
    wire            ex_cp0wen;
    wire [`CP0ADDR] ex_cp0addr;
    wire            ex_mult;
    wire            ex_div;
    wire            ex_mdsign;
    wire [1 :0]     ex_hilowen;
    wire [1 :0]     ex_hiloren;
    wire [31:0]     ex_hilordata;
    // *EC
    wire [`EXBITS]  ec_ex;
    wire [31:0]     ec_pc;
    wire [31:0]     ec_inst;
    wire [4 :0]     ec_rs = `GET_Rs(ec_inst);
    wire [4 :0]     ec_rt = `GET_Rt(ec_inst);
    wire [31:0]     ec_res;
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
    wire            ec_cp0ren;
    wire            ec_exc_oc;
    wire            ec_cp0wen;
    wire [`CP0ADDR] ec_cp0addr;
    wire [31:0]     ec_cp0rdata;
    wire [31:0]     ec_reorder_data;
    wire [31:0]     ec_reorder_ex;
    // * CP0
    wire [31:0]     cp0_epc;
    wire            ext_int_response;
    // *WB
    wire            wb_data_ok;
    wire [31:0]     wb_data_rdata;
    wire [31:0]     wb_pc;
    wire [31:0]     wb_inst;
    wire [31:0]     wb_res;
    wire            wb_load;
    wire            wb_loadX;
    wire [31:0]     wb_rdata;
    wire [3 :0]     wb_lsV;
    wire [1 :0]     wb_data_addr;
    wire            wb_regwen;
    wire [4 :0]     wb_wreg;
    wire            wb_eret;
    wire [31:0]     wb_reorder_data;
    wire [31:0]     wb_reorder_ec;

    // * CU
    wire    pre_ins;    // * 是否是要用前一次的指令
    wire    if_id_stall;
    wire    id_ex_stall;
    wire    ex_ec_stall;
    wire    ec_wb_stall;

    wire    if_id_refresh;
    wire    id_ex_refresh;
    wire    ex_ec_refresh;
    wire    ec_wb_refresh;

    wire    div_mul_stall;

    // * 重定向数据
    wire [31:0] ex_reorder_data =   ex_al           ?   ex_pc+32'd8     :
                                    (|ex_hiloren)   ?   ex_hilordata    :
                                                        ex_res          ;


    // * cache / uncache
    assign inst_cache   = 1'b1;
    assign data_cache   = !(ex_daddr[31:29] == 3'b101);
    assign cache_req    = 1'b0;
    assign cache_op     = 7'b0;
    assign cache_tag    = 32'b0;

    reg inst_cache_state;
    reg data_cache_state;
    parameter IDLE          =   1'b0;
    parameter BUSY          =   1'b1;
    always @(posedge aclk)
        inst_cache_state    <=  !aresetn        ? IDLE :
                                inst_addr_ok    ? BUSY :
                                inst_data_ok    ? IDLE :
                                inst_cache_state       ;

    always @(posedge aclk)
        data_cache_state    <=  !aresetn        ? IDLE :
                                data_addr_ok    ? BUSY :
                                data_data_ok    ? IDLE :
                                data_cache_state       ;

    assign inst_req = (!inst_cache_state || inst_data_ok) && !if_inst_ADDRESS_ERROR && !ec_exc_oc;
    
    cu u_cu(
        .id_pc          (id_pc),

        .inst_req       (inst_req),
        .inst_addr_ok   (inst_addr_ok),
        .inst_data_ok   (inst_data_ok),
        .id_inst_req    (id_inst_req),

        .ec_dload_req   (ec_data_req && ec_load),   // * ec取数请求
        .data_req       (data_req),
        .data_addr_ok   (data_addr_ok),
        .data_data_ok   (data_data_ok),
        .wb_regwen      (wb_regwen),
        .wb_wreg        (wb_wreg),
        .wb_data_ok     (wb_data_ok),

        .ex_rs_ren  (ex_rs_ren),
        .ex_rs      (ex_rs),
        .ex_rt_ren  (ex_rt_ren),
        .ex_rt      (ex_rt),

        .exc_oc     (ec_exc_oc),
        .eret       (id_eret),

        .id_branch  (id_branch),
        .id_rs_ren  (id_rs_ren),
        .id_rs      (id_rs),
        .id_rt_ren  (id_rt_ren),
        .id_rt      (id_rt),

        .ex_dload_req   (ex_load && data_req), // * load请求
        .ex_cp0ren      (ex_cp0ren),
        .ex_wreg        (ex_wreg),
 
        .ec_load    (ec_load),
        .ec_wreg    (ec_wreg),

        .div_mul_stall  (div_mul_stall),
        // * O
        .pre_ins    (pre_ins),

        .if_id_stall    (if_id_stall),
        .id_ex_stall    (id_ex_stall),
        .ex_ec_stall    (ex_ec_stall),
        .ec_wb_stall    (ec_wb_stall),

        .if_id_refresh  (if_id_refresh),
        .id_ex_refresh  (id_ex_refresh),
        .ex_ec_refresh  (ex_ec_refresh),
        .ec_wb_refresh  (ec_wb_refresh)
    );

    // *IF
    pc u_pc(
        .clk            (aclk),
        .resetn         (aresetn),
        .stall          (if_id_stall),
        .BranchTarget   (id_target),
        .BranchTake     (id_jump && id_branch),
        .exc_oc         (ec_exc_oc),

        .eret           (id_eret),  // * eret
        .epc            (cp0_epc),  // * epc from cp0

        .npc            (npc)
    );

    reg [31:0]  last_addr;
    always @(posedge aclk) begin
        if(!aresetn)    last_addr <= 32'h0;
        else            last_addr <= inst_addr;
    end

    // *               取前一条
    assign inst_addr =  pre_ins ? last_addr : npc;
    assign if_inst_ADDRESS_ERROR = npc[0] | npc[1];

    reg exc_oc_invalid; // * 异常发生后紧接着取出的指令不是正确指令
    always @(posedge aclk) begin
        if(!aresetn)    exc_oc_invalid <=   1'b0;
        else            exc_oc_invalid <=   ec_exc_oc || (exc_oc_invalid && (if_id_stall || if_id_refresh));
    end

    if_id_seg u_if_id_seg(
        .clk    (aclk),
        .resetn (aresetn),

        .stall  (if_id_stall),
        .refresh(if_id_refresh),

        .id_branch      (id_branch),
        .if_addr_error  (if_inst_ADDRESS_ERROR),
        .if_pc          (inst_addr),
        .if_inst_req    (inst_req),

        .id_bd          (id_bd),
        .id_addr_error  (id_addr_error),
        .id_pc          (id_pc),
        .id_inst_req    (id_inst_req)
    );

    // *ID   *          exc_oc 后一条以及inst_data_ok低和取指地址错时都是无效指令
    assign id_inst  =   exc_oc_invalid || !inst_data_ok || id_addr_error ? 32'b0 : inst_rdata;


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

    wire [31:0] re_rs =     ec_regwen && ec_wreg == id_rs   ? ec_reorder_data   : regouta;           

    wire [31:0] re_rt =     ec_regwen && ec_wreg == id_rt   ? ec_reorder_data   : regoutb;

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

        .wb_regwen          (wb_regwen && !ec_wb_stall),
        .wb_wreg            (wb_wreg),
        .wb_reorder_data    (wb_reorder_data),

        .id_ex      (id_ex),
        .id_pc      (id_pc),
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
    // *store命令写入的数据
    assign ex_wdata     =   ec_wreg == ex_rt && ec_regwen   ? ec_reorder_data   :
                            wb_wreg == ex_rt && wb_regwen   ? wb_reorder_data   : ex_B;

    wire [31:0] inAlu1  =   ec_wreg == ex_rs && ec_regwen   ? ec_reorder_data   :
                            wb_wreg == ex_rs && wb_regwen   ? wb_reorder_data   : ex_A;

    wire [31:0] inAlu2  =   ex_imm ? ex_Imm : ex_wdata;

    wire [5 :0] ex_func =   ex_SPEC ? `GET_FUNC(ex_inst) : ex_ifunc;

    alu u_alu(
        .A      (inAlu1),
        .B      (inAlu2),
        .func   (ex_func),
        .sa     (`GET_SA(ex_inst)),

        .IntegerOverflow    (ex_IntegerOverflow),
        .daddr              (ex_daddr), // * dcache的地址
        .res                (ex_res)
    );

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
    assign ex_data_ADDRESS_ERROR = !(ec_data_req && ec_load) && ex_data_en && (ex_load && (ex_data_ren == 4'b0011 && data_addr[0] || ex_data_ren == 4'b1111 && data_addr[1:0] != 2'b00)
                                    || !ex_load && (ex_data_wen == 4'b0011 && data_addr[0] || ex_data_wen == 4'b1111 && data_addr[1:0] != 2'b00));

    wire [`EXBITS] EX_ex = ex_ex | {2'b0, ex_IntegerOverflow, 2'b0, ex_data_ADDRESS_ERROR};
    assign data_req = ex_data_en && !(|EX_ex) && !ec_exc_oc;

    // * 重定向一致 ex_wdata, data_wdata
    assign data_wdata = {   {8{ex_lsV[3]}} & ex_wdata[31:24],
                            {8{ex_lsV[2]}} & ex_wdata[23:16],
                            {8{ex_lsV[1]}} & ex_wdata[15: 8],
                            {8{ex_lsV[0]}} & ex_wdata[7 : 0]} << {data_addr[1:0], 3'b0};
    assign data_wstrb = ex_data_wen << data_addr[1:0];

    ex_ec_seg u_ex_ec_seg(
        .clk    (aclk),
        .resetn (aresetn),

        .stall  (ex_ec_stall),
        .refresh(ex_ec_refresh),

        .ex_ex          (EX_ex),
        .ex_pc          (ex_pc),
        .ex_inst        (ex_inst),
        .ex_res         (ex_res),
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

        .ec_ex          (ec_ex),
        .ec_pc          (ec_pc),
        .ec_inst        (ec_inst),
        .ec_res         (ec_res),
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
        .ec_reorder_ex  (ec_reorder_ex)
    );

    // *mtc0的写入数据
    assign ec_wdata =   wb_wreg == ex_rt && wb_load ? wb_rdata : ec_B;
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
        .ec_cp0ren      (ec_cp0ren),
        .ec_cp0wen      (ec_cp0wen),
        .ec_cp0addr     (ec_cp0addr),
        .ec_wdata       (ec_wdata),
        .ec_bd          (ec_bd),
        .ec_eret        (ec_eret),
        .ec_reorder_ex  (ec_reorder_ex),
        .wb_eret        (wb_eret),

        // * O
        .exc_oc             (ec_exc_oc),

        .ext_int_response   (ext_int_response),
        .cp0rdata           (ec_cp0rdata),
        .cp0_epc            (cp0_epc),
        .reorder_data       (ec_reorder_data)
    );

    ec_wb_seg u_ec_wb_seg(
        .clk    (aclk),
        .resetn (aresetn),

        .stall  (ec_wb_stall),
        .refresh(ec_wb_refresh),

        .ec_data_ok     (data_data_ok),
        .ec_data_rdata  (ec_rdata),
        .ec_pc          (ec_pc),
        .ec_inst        (ec_inst),
        .ec_load        (ec_load),
        .ec_regwen      (ec_regwen),
        .ec_wreg        (ec_wreg),
        .ec_eret        (ec_eret),
        .ec_reorder_data(ec_reorder_data),

        .wb_data_ok     (wb_data_ok),
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
        .wb_rdata       (wb_rdata),
        .wb_reorder_data(wb_reorder_data)
    );

    // *debug
    assign debug_wb_pc          = wb_pc;
    assign debug_wb_rf_wen      = {4{wb_regwen && !ec_wb_stall}};
    assign debug_wb_rf_wnum     = wb_wreg;
    assign debug_wb_rf_wdata    = wb_reorder_data;

endmodule
