`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/29/2020 08:54:33 PM
// Design Name: 
// Module Name: inst_uncache
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module inst_uncache(
    input         clk,
    input         rstn, 

    //inst sram-like 
    input         inst_req     ,
    input         inst_wr      ,
    input  [1 :0] inst_size    ,
    input  [31:0] inst_addr    ,
    input  [31:0] inst_wdata   ,
    output [31:0] inst_rdata   ,
    output        inst_addr_ok ,
    output        inst_data_ok ,
    
    //axi
    //ar
    output [3 :0] arid         ,
    output [31:0] araddr       ,
    output [7 :0] arlen        ,
    output [2 :0] arsize       ,
    output [1 :0] arburst      ,
    output [1 :0] arlock        ,
    output [3 :0] arcache      ,
    output [2 :0] arprot       ,
    output        arvalid      ,
    input         arready      ,
    //r           
    input  [3 :0] rid          ,
    input  [31:0] rdata        ,
    input  [1 :0] rresp        ,
    input         rlast        ,
    input         rvalid       ,
    output        rready       ,
    //aw          
    output [3 :0] awid         ,
    output [31:0] awaddr       ,
    output [7 :0] awlen        ,
    output [2 :0] awsize       ,
    output [1 :0] awburst      ,
    output [1 :0] awlock       ,
    output [3 :0] awcache      ,
    output [2 :0] awprot       ,
    output        awvalid      ,
    input         awready      ,
    //w          
    output [3 :0] wid          ,
    output [31:0] wdata        ,
    output [3 :0] wstrb        ,
    output        wlast        ,
    output        wvalid       ,
    input         wready       ,
    //b           
    input  [3 :0] bid          ,
    input  [1 :0] bresp        ,
    input         bvalid       ,
    output        bready       
    );

    reg do_req;
    reg [31:0] do_addr_r;
    wire data_back;

    assign inst_addr_ok = (!do_req) & inst_req;
    always @(posedge clk)
    begin
        do_req     <= !rstn              ? 1'b0 : 
                      inst_req & !do_req ? 1'b1 :
                      data_back          ? 1'b0 : do_req;
        do_addr_r  <= inst_req & inst_addr_ok ? inst_addr : do_addr_r;
    end

    reg addr_rcv;

    assign data_back = addr_rcv && (rvalid&&rready||bvalid&&bready);
    always @(posedge clk)
    begin
        addr_rcv  <= !rstn          ? 1'b0 :
                     arvalid&&arready ? 1'b1 :
                     data_back        ? 1'b0 : addr_rcv;
    end

    //inst sram-like
    assign inst_data_ok = do_req & data_back;
    assign inst_rdata   = rdata;

    assign arid    = 4'd7;
    assign araddr  = do_addr_r;
    assign arlen   = 8'd0;
    assign arsize  = 3'd2;
    assign arburst = 2'd0;
    assign arlock  = 2'd0;
    assign arcache = 4'd0;
    assign arprot  = 3'd0;
    assign arvalid = do_req & !addr_rcv;
    //r
    assign rready  = 1'b1;
    //Don't Care
    assign awid    = 4'd0;
    assign awlen   = 8'd0;
    assign awburst = 2'b00;
    assign awsize  = 3'd2;
    assign awlock  = 2'b0;
    assign awcache = 4'b0;
    assign awprot  = 3'b0;
    assign awaddr  = 32'b0;
    assign awvalid = 4'b0;
    assign wdata   = 32'b0;
    assign wvalid  = 4'b0;
    assign wid     = 4'd0;
    assign wlast   = 3'b0;
    assign bready  = 4'b0;




endmodule
