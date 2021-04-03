`timescale 1ns / 1ps
`include "./head.vh"

// * five segment pipeline cpu
module mycpu_top(
    input   [5 :0]  ext_int,        // *硬件中断

    input           aclk,
    input           aresetn,

    output  [3 :0]  arid,
    output  [31:0]  araddr,
    output  [3 :0]  arlen,
    output  [2 :0]  arsize,
    output  [1 :0]  arburst,
    output  [1 :0]  arlock,
    output  [3 :0]  arcache,
    output  [2 :0]  arprot,
    output          arvalid,
    input           arready,

    input   [3 :0]  rid,
    input   [31:0]  rdata,
    input   [1 :0]  rresp,
    input           rlast,
    input           rvalid,
    output          rready,

    output  [3 :0]  awid,
    output  [31:0]  awaddr,
    output  [3 :0]  awlen,
    output  [2 :0]  awsize,
    output  [1 :0]  awburst,
    output  [1 :0]  awlock,
    output  [3 :0]  awcache,
    output  [2 :0]  awprot,
    output          awvalid,
    input           awready,

    input   [3 :0]  wid,
    input   [31:0]  wdata,
    input   [3 :0]  wstrb,
    input           wlast,
    input           wvalid,
    output          wready,

    input   [3 :0]  bid,
    input   [1 :0]  bresp,
    input           bvalid,
    input           bready,

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
    wire        wb_eret;
    wire        wb_cp0ren;
    wire [31:0] wb_cp0rdata;
    wire [1 :0] wb_hiloren;
    wire [31:0] wb_hilordata;

    wire [31:0] cp0_epc;

    wire    cu_stall;

    wire    if_id_stall;
    wire    id_ex_stall;
    wire    ex_wb_stall;

    wire    if_id_refresh;
    wire    id_ex_refresh;
    wire    ex_wb_refresh;

    wire    div_stall;

    //inst sram-like 
    wire        inst_req;
    wire [31:0] inst_addr   ;
    wire [31:0] inst_wdata  ;
    wire [31:0] inst_rdata  ;
    wire        inst_addr_ok;
    wire        inst_data_ok;
    
    //data sram-like 
    wire        data_req    ;
    wire        data_wr     ;
    wire [1 :0] data_size   ;
    wire [31:0] data_addr   ;
    wire [31:0] data_wdata  ;
    wire [31:0] data_rdata  ;
    wire        data_addr_ok;
    wire        data_data_ok;

    reg reg_aresetn;
    always @(posedge aclk)
        reg_aresetn <= aresetn;
    assign inst_req = !reg_aresetn || (inst_addr_ok && !inst_data_ok) || inst_data_ok;

    cpu_axi_interface u_cpu_axi_interface(
        .clk        (aclk),
        .resetn     (aresetn),

        // *sram-like
        .inst_req   (inst_req),
        .inst_wr    (1'b0),     // * not write
        .inst_size  (2'b11),    // * 4 bytes
        .inst_addr  (inst_addr),
        .inst_wdata (32'b0),
        .inst_rdata (inst_rdata),
        .inst_addr_ok   (inst_addr_ok),
        .inst_data_ok   (inst_data_ok),

        .data_req   (data_req),
        .data_wr    (data_wr),
        .data_size  (data_size),
        .data_addr  (data_addr),
        .data_wdata (data_wdata),
        .data_rdata (data_rdata),
        .data_addr_ok   (data_addr_ok),
        .data_data_ok   (data_data_ok),

        // * axi
        // * ar
        .arid   (arid),
        .araddr (araddr),
        .arlen  (arlen),
        .arsize (arsize),
        .arburst(arburst),
        .arlock (arlock),
        .arcache(arcache),
        .arprot (arprot),
        .arvalid(arvalid),
        .arready(arready),

        // * r
        .rid    (rid),
        .rdata  (rdata),
        .rresp  (rresp),
        .rlast  (rlast),
        .rvalid (rvalid),
        .rready (rready),

        // * aw
        .awid   (awid),
        .awaddr (awaddr),
        .awlen  (awlen),
        .awsize (awsize),
        .awburst(awburst),
        .awlock (awlock),
        .awcache(awcache),
        .awprot (awprot),
        .awvalid(awvalid),
        .awready(awready),

        // * w
        .wid    (wid),
        .wdata  (wdata),
        .wstrb  (wstrb),
        .wlast  (wlast),
        .wvalid (wvalid),
        .wready (wready),
        
        // * b
        .bid    (bid),
        .bresp  (bresp),
        .bvalid (bvalid),
        .bready (bready)
    );

    reg reg_inst_data_ok;
    always @(posedge aclk)
        reg_inst_data_ok <= inst_data_ok;

    cu u_cu(
        .id_pc      (id_pc),

        .inst_req       (inst_req),
        .inst_data_ok   (reg_inst_data_ok),
        .data_req       (data_req),
        .data_data_ok   (data_data_ok),

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

        .ex_regwen  (ex_regwen),    
        .ex_load    (ex_load),
        .ex_cp0ren  (ex_cp0ren),
        .ex_wreg    (ex_wreg),

        .ex_stall   (cu_stall),
        .div_stall  (div_stall),

        .if_id_stall    (if_id_stall),
        .id_ex_stall    (id_ex_stall),
        .ex_wb_stall    (ex_wb_stall),

        .if_id_refresh  (if_id_refresh),
        .id_ex_refresh  (id_ex_refresh),
        .ex_wb_refresh  (ex_wb_refresh)
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
        .BranchTake     (id_branch && id_jump),
        .exc_oc         (ex_exc_oc),

        .eret           (id_eret),  // * eret
        .epc            (cp0_epc),  // * epc from cp0
        .npc            (npc)
    );

    assign inst_addr = !cu_stall ? npc : npc-32'd4;
    // assign inst_addr = npc-32'd4;
    assign if_inst_ADDRESS_ERROR = inst_addr[1:0] != 2'b00;

    reg exc_oc_invalid; // * 异常发生后紧接着取出的指令不是正确指令
    always @(posedge aclk) exc_oc_invalid <= !aresetn ? 1'b0 : ex_exc_oc;

    wire id_bd_tmp;

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
    wire [31:0] inRegData;
    wire [31:0] regouta, regoutb;
    wire [31:0] id_Imm  =   id_immXtype == 2'b00 ? {16'b0, `GET_Imm(id_inst)}           :   // zero extend
                            id_immXtype == 2'b01 ? {{16{id_inst[15]}}, `GET_Imm(id_inst)} : // signed extend
                            {`GET_Imm(id_inst), 16'b0};                                     // {imm, {16{0}}}
    
    assign id_inst  = exc_oc_invalid ? 32'b0 : inst_rdata;

    regfile u_regfile(
        .clk    (aclk),
        .resetn (aresetn),
        .rs     (id_rs),
        .rt     (id_rt),
        .wen    (wb_regwen),
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

    id_ex_seg u_id_ex_seg(
        .clk    (aclk),
        .resetn (aresetn),

        .stall  (id_ex_stall),
        .refresh(id_ex_refresh),

        .id_addr_error(id_addr_error),
        .id_ex      (id_ex),
        .id_pc      (id_pc),
        .id_inst    (inst_rdata), // * avoid timing loop
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

    // *data_sram and cp0
    assign data_req = ex_data_en && !ex_data_ADDRESS_ERROR;
    assign data_addr = ex_res & 32'h1fff_ffff;
    assign data_wr = |ex_data_wen;
    assign data_size = ex_data_wen;
    assign ex_data_ADDRESS_ERROR = ex_data_en && (ex_load && (ex_data_ren == 4'b0011 && data_addr[0] || ex_data_ren == 4'b1111 && data_addr[1:0] != 2'b00)
                                    || !ex_load && (ex_data_wen == 4'b0011 && data_addr[0] || ex_data_wen == 4'b1111 && data_addr[1:0] != 2'b00));
 

    wire [`EXBITS] EX_ex = {ex_addr_error, ex_ex} | {2'b0, ex_IntegerOverflow, 2'b0, ex_data_ADDRESS_ERROR};
    wire [4:0] exc_excode = ext_int ? `EXC_INT :
                            EX_ex[5] ? `EXC_AdEL : // *取指地址错
                            EX_ex[4] ? `EXC_RI :   // *RI
                            EX_ex[3] ? `EXC_Ov :   // *Overflow
                            EX_ex[2] ? `EXC_Bp :   // *Break point
                            EX_ex[1] ? `EXC_Sys :  // *syscall
                            EX_ex[0] ? 
                                ex_load ? `EXC_AdEL : `EXC_AdES
                            : 5'b0;

    wire ext_int_response;
    wire [31:0] exc_epc = ex_bd ? ex_pc-32'd4 : ex_pc;
    wire [31:0] cp0_status, cp0_cause;  // * cp0cause not use for now
    wire exc_valid = cp0_status[`Status_EXL] ? !wb_eret : // * valid 1 : 表示有例外在处理, 刚传到ex段的例外也算属于在处理
                    ext_int_response ? 1'b1 : |EX_ex;
    wire [31:0] cp0_wdata = wb_regwen && ex_rt == wb_wreg ? wb_reorder_data : ex_wdata;
    // * 重定向一致 cp0_wdata, data_sram_wdata
    assign data_sram_wdata = {  {8{ex_lsV[3]}} & cp0_wdata[31:24],
                                {8{ex_lsV[2]}} & cp0_wdata[23:16],
                                {8{ex_lsV[1]}} & cp0_wdata[15: 8],
                                {8{ex_lsV[0]}} & cp0_wdata[7 : 0]} << {data_addr[1:0], 3'b000};

    assign ex_exc_oc = !cp0_status[`Status_EXL] && exc_valid;
    wire [31:0] exc_badvaddr = EX_ex[5] ? ex_pc : ex_res;
    // * CP0 regs
    cp0 u_cp0(
        .clk    (aclk),
        .resetn (aresetn),

        .ext_int            (ext_int),
        .ext_int_response   (ext_int_response),

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

        .stall  (ex_wb_stall || (data_req && !data_data_ok)),
        .refresh(ex_wb_refresh),

        .ex_pc          (ex_pc),
        .ex_inst        (ex_inst),
        .ex_res         (ex_res),
        .ex_load        (ex_load),
        .ex_loadX       (ex_loadX),
        .ex_lsV         (ex_lsV),
        .ex_data_addr   (data_addr[1:0]),
        .ex_al          (ex_al),
        .ex_regwen      (ex_regwen),
        .ex_wreg        (ex_wreg),
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
    assign inRegData =  {32{wb_al}      } & (wb_pc + 32'd8) |   // *al: pc+8 -> GPR[31]
                        {32{wb_load}    } & wb_rdata        |   // *load: data from data sram -> GPR[rt]
                        {32{wb_cp0ren}  } & wb_cp0rdata     |   // *MFC0: data from CP0 -> GPR[rt]
                        {32{|wb_hiloren}} & wb_hilordata    |   // *MFHI/LO: data from HI/LO -> GPR[rd]
                        {32{!wb_al && !wb_load && !wb_cp0ren && !(|wb_hiloren)}} & wb_res; // *SPEC: data from ALU -> GPR[rd]

    // *debug
    assign debug_wb_pc          = wb_pc;
    assign debug_wb_rf_wen      = {4{wb_regwen}};
    assign debug_wb_rf_wnum     = wb_wreg;
    assign debug_wb_rf_wdata    = inRegData;

endmodule
