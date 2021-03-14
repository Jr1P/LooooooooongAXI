`timescale 1ns / 1ps
`include "./head.vh"

module cp0 (
    input           clk,
    input           resetn,

    // * interrput
    input  [5 :0]   ext_int,
    output          ext_int_response, // *中断响应

    input           wen,    // *write engine
    input  [7 :0]   addr,   // *write/read address
    input  [31:0]   wdata,  // *write in data
    output [31:0]   rdata,  // *read out data

    // * exception occur
    input           exc_valid,   // * 1: 例外处理
    input [4 :0]    exc_excode,  // * exception code
    input           exc_bd,      // * 1: branch delay slot
    input [31:0]    exc_epc,     // * exception pc
    input [31:0]    exc_badvaddr,// * exception BadVAddr
    input           exc_eret,    // * 1: eret

    // * cp0 regs
    output [31:0]       cause,
    output [31:0]       status,
    output [31:0]       index,
    output reg [31:0]   epc
);

    // * address wrong (if seg, ex seg)
    wire exc_addr   = exc_excode == `EXC_AdEL
                    | exc_excode == `EXC_AdES;

    // *Index (4, 0) | read and partially writeable
    reg Index_P;
    reg [`Index_IndexBITs] Index_Index;
    assign index = {Index_P, 31'b0} | Index_Index;
    wire index_wen = wen && addr == `CP0_Index;
    always @(posedge clk) begin
        // TODO: INDEX
    end

    // *BadVAddr (8, 0) | read only | reset val: null
    reg [31:0] badvaddr;
    always @(posedge clk) begin
        if(exc_valid && exc_addr) badvaddr <= exc_badvaddr;
    end

    // *Count (9, 0) | read/write | reset val: null
    reg [31:0] count;
    reg inter_tik;
    wire count_wen = wen && addr == `CP0_Count;
    always @(posedge clk) begin
        if(!resetn) inter_tik <= 1'b0;
        else        inter_tik <= ~inter_tik;
        if(count_wen)       count <= wdata;
        else if(inter_tik)  count <= count + 32'd1;
    end

    // *Compare (13, 0) | read/write | reset val: null
    reg [31:0] compare;
    wire compare_wen = wen && addr == `CP0_Compare;
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
    wire status_wen = wen && addr == `CP0_Status;
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
    wire cause_wen = wen && addr == `CP0_Cause;
    wire [5:0] hardware_int = ext_int | {timer_int, 5'b0};
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
    wire epc_wen = wen && addr == `CP0_EPC;
    always @(posedge clk) begin
        if(epc_wen)                         epc <= wdata;
        else if(exc_valid && !Status_EXL)   epc <= exc_epc;  // *exc_epc: if Cause.BD is 1, exc_epc == pc-4
    end
    // *                            存在未被屏蔽的中断                 没有例外在处理   中断使能开启
    assign ext_int_response = ({hardware_int, ip_software} & Status_IM) && !Status_EXL && Status_IE;

    assign rdata = 
            {32{addr == `CP0_Index      }} & index      |
            {32{addr == `CP0_BadVAddr   }} & badvaddr   |
            {32{addr == `CP0_Count      }} & count      |
            {32{addr == `CP0_Compare    }} & compare    |
            {32{addr == `CP0_Status     }} & status     |
            {32{addr == `CP0_Cause      }} & cause      |
            {32{addr == `CP0_EPC        }} & epc        ;

endmodule