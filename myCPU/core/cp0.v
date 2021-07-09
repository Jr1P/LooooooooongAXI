`timescale 1ns / 1ps
`include "./head.vh"

module cp0 (
    input           clk,
    input           resetn,

    // * interrput
    input  [5 :0]   ext_int,

    input           wen,    // *write engine
    // input  [7 :0]   addr,   // *write/read address
    input  [31:0]   wdata,  // *write in data

    input           rcp0_badV_en,
    input           rcp0_count_en,
    input           rcp0_compare_en,
    input           rcp0_status_en,
    input           rcp0_cause_en,
    input           rcp0_epc_en,
    // input           rcp0_lo1_en,
    // input           rcp0_lo2_en,
    // input           rcp0_pagemask_en,
    // input           rcp0_index_en,

    input           wcp0_badV_en,
    input           wcp0_count_en,
    input           wcp0_compare_en,
    input           wcp0_status_en,
    input           wcp0_cause_en,
    input           wcp0_epc_en,
    // input           wcp0_lo1_en,
    // input           wcp0_lo2_en,
    // input           wcp0_pagemask_en,
    // input           wcp0_index_en,

    // * exception occur
    input           exc_valid,   // * 1: 例外处理
    input [4 :0]    exc_excode,  // * exception code
    input           exc_bd,      // * 1: branch delay slot
    input [31:0]    exc_epc,     // * exception pc
    input [31:0]    exc_badvaddr,// * exception BadVAddr
    input           exc_eret,    // * 1: eret
    // * O
    output [31:0]   rdata,  // *read out data
    
    output          ext_int_response,   // *中断响应
    // * cp0 regs
    output [31:0]       index,
    output [31:0]       cause,
    output [31:0]       status,
    output reg [31:0]   epc         // * read and write | reset val : null
);

    // * address wrong (if seg, ex seg)
    wire exc_addr   = exc_excode == `EXC_AdEL
                    | exc_excode == `EXC_AdES;

    // // *Index (0, 0)
    // reg Index_P;            // * r      reset value: null
    // // * 32项的TLB
    // reg [4:0] Index_Index;  // * r/w    reset value: null
    // assign index = {Index_P, 26'b0, Index_Index};
    // wire index_wen = wen && wcp0_index_en;
    // always @(posedge clk) begin
    //     if(index_wen)   Index_Index = wdata[4:0];
    // end

    // // * Entrylo 0,1:(2, 0), (3, 0)
    // reg [19:0] EntryLo1_PFN, EntryLo2_PFN;      // * r/w    reset value: null
    // reg [5 :0] EntryLo1_Flags, EntryLo2_Flags;  // * r/w    reset value: null
    // wire [31:0] lo1rdata = {6'b0, EntryLo1_PFN, EntryLo1_Flags};
    // wire [31:0] lo2rdata = {6'b0, EntryLo2_PFN, EntryLo2_Flags};
    // wire lo1_wen = wen && wcp0_lo1_en;
    // wire lo2_wen = wen && wcp0_lo2_en;
    // always @(posedge clk) begin
    //     if(lo1_wen) begin
    //         EntryLo1_PFN    <= wdata[`EntryLo_PFN];
    //         EntryLo1_Flags  <= wdata[`EntryLo_Flags];
    //     end
    // end

    //  always @(posedge clk) begin
    //     if(lo2_wen) begin
    //         EntryLo2_PFN    <= wdata[`EntryLo_PFN];
    //         EntryLo2_Flags  <= wdata[`EntryLo_Flags];
    //     end
    // end

    // // * PageMask (5, 0) 屏蔽特定位, 某个位为1则屏蔽
    // reg [11:0] Page_Mask;   // * r/w    reset value: null
    // wire [31:0] pagemask = {7'b0, Page_Mask, 13'b0};
    // wire pagemask_wen = wen && wcp0_pagemask_en;
    // always @(posedge clk) begin
    //     if(pagemask_wen) Page_Mask <= wdata[`PageMask_Mask];
    // end

    // *BadVAddr (8, 0) | read only | reset val: null
    reg [31:0] badvaddr;
    always @(posedge clk) begin
        if(exc_valid && exc_addr) badvaddr <= exc_badvaddr;
    end

    // *Count (9, 0) | read/write | reset val: null
    reg [31:0] count;
    reg inter_tik;
    wire count_wen = wen && wcp0_count_en;
    always @(posedge clk) begin
        if(!resetn) inter_tik <= 1'b0;
        else        inter_tik <= ~inter_tik;
        if(count_wen)       count <= wdata;
        else if(inter_tik)  count <= count + 32'd1;
    end

    // *Compare (11, 0) | read/write | reset val: null
    reg [31:0] compare;
    wire compare_wen = wen && wcp0_compare_en;
    always @(posedge clk) begin
        if(compare_wen) compare <= wdata;
    end
    reg timer_int;
    always @(posedge clk) begin
        if(!resetn || compare_wen)  timer_int <= 1'b0;
        else if(count == compare)   timer_int <= 1'b1;
    end

    // *Status (12, 0) | read and partially writeable
    reg Status_Bev;             // *read only   | reset val: 1
    reg Status_EXL, Status_IE;  // *read/write  | reset val: 0
    reg [7:0] Status_IM;        // *read/write  | reset val: null
    // *                       22               15:8              1          0
    assign status = {9'b0, Status_Bev, 6'b0, Status_IM, 6'b0, Status_EXL, Status_IE};
    wire status_wen = wen && wcp0_status_en;
    always @(posedge clk) begin
        // * Bev
        if(!resetn)         Status_Bev <= 1'b1;
        else if(status_wen) Status_Bev <= wdata[`Status_Bev];
        // * IM
        if(status_wen) Status_IM <= wdata[`Status_IM];
        // * EXL
        if(!resetn)         Status_EXL <= 1'b0;
        else if(exc_valid)  Status_EXL <= !exc_eret;
        else if(status_wen) Status_EXL <= wdata[`Status_EXL];
        // *IE
        if(!resetn)         Status_IE <= 1'b0;
        else if(status_wen) Status_IE <= wdata[`Status_IE];
    end

    // *Cause (13, 0) | read and parially writeable
    reg Cause_BD, Cause_TI; // *read only   | reset val: 0
    reg [5:0] ip_hardware;  // *read only   | reset val: 0
    reg [1:0] ip_software;  // *read/write  | reset val: 0
    reg [4:0] Cause_ExcCode;
    // *                31       30                15:10        9:8                 6:2
    assign cause = {Cause_BD, Cause_TI, 14'b0, ip_hardware, ip_software, 1'b0, Cause_ExcCode, 2'b0};
    wire cause_wen = wen && wcp0_cause_en;
    wire [5:0] hardware_int = ext_int/* | {timer_int, 5'b0}*/; // * 取消了时钟中断
    always @(posedge clk) begin
        // *BD
        if(!resetn)                         Cause_BD <= 1'b0;
        else if(exc_valid && !Status_EXL)   Cause_BD <= exc_bd;
        // *TI
        if(!resetn) Cause_TI <= 1'b0;
        else        Cause_TI <= timer_int;
        // *IP
        if(!resetn) ip_hardware <= 6'b0;
        else        ip_hardware <= hardware_int;
        if(!resetn)         ip_software <= 2'b0;
        else if(cause_wen)  ip_software <= wdata[`Cause_IP_SOFTWARE];
        // *ExcCode
        if(!resetn)                         Cause_ExcCode <= 5'b0;
        else if(exc_valid && !Status_EXL)   Cause_ExcCode <= exc_excode;
    end

    // * EPC (14, 0) | read/write | reset val: null
    wire epc_wen = wen && wcp0_epc_en;
    always @(posedge clk) begin
        if(epc_wen)                         epc <= wdata;
        else if(exc_valid && !Status_EXL)   epc <= exc_epc;  // *exc_epc: if Cause.BD is 1, exc_epc == pc-4
    end
    wire [1:0] ext_int_soft     = {2{cause_wen}} & wdata[`Cause_IP_SOFTWARE];
    // *                            存在未被屏蔽的中断                 没有例外在处理   中断使能开启
    assign  ext_int_response    = ({hardware_int, ext_int_soft} & Status_IM) && !Status_EXL && Status_IE;

    // // * Config0 (16, 0) | read and partially writeable |
    // wire config0_wen = wen && addr == `CP0_Config0;
    // // *                    M            BE    AT    AR    MT
    // wire [31:0] config0 = {1'b1, 15'b0, 1'b0, 2'b0, 3'b0, 3'b1, 4'b0, config0_k0};

    // always @(posedge clk) begin
    //     // * config_k0
    //     if(!resetn) config0_k0 <= 3'b011;
    //     else if(config0_wen) config0_k0 <= wdata[`Config0_k0];
    // end

    // * Config1 (16, 1) | read only
    // TODO: 配置修改
    wire [31:0] config1 = {
        1'b0,
        `TLB_SIZE,  // *TLB entries
        3'd1,       // *Icache组数
        3'd1,       // *Icache行大小
        3'd3,       // *Icache相联度
        3'd1,       // *Dcache组数
        3'd1,       // *Dcache行大小
        3'd3,       // *Dcache相联度
        1'b0,       // *C2
        1'b0,       // *MD
        1'b0,       // *PC
        1'b0,       // *WR
        1'b0,       // *CA
        1'b0,       // *EP
        1'b0        // *FP
    };

    assign rdata = 
            // {32{rcp0_index_en   }} & index      |
            // {32{rcp0_lo1_en     }} & lo1rdata   |
            // {32{rcp0_lo2_en     }} & lo2rdata   |
            // {32{rcp0_pagemask_en}} & pagemask   |
            {32{rcp0_badV_en    }} & badvaddr   |
            {32{rcp0_count_en   }} & count      |
            {32{rcp0_compare_en }} & compare    |
            {32{rcp0_status_en  }} & status     |
            {32{rcp0_cause_en   }} & cause      |
            {32{rcp0_epc_en     }} & epc        ;

endmodule