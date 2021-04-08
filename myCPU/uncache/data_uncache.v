`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/29/2020 09:32:32 PM
// Design Name: 
// Module Name: data_uncache
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


module data_uncache(
    input         clk,
    input         rstn, 
    
    //data sram-like 
    input         data_req     ,
    input         data_wr      ,
    input  [1 :0] data_size    ,
    input  [31:0] data_addr    ,
    input  [31:0] data_wdata   ,
    input  [3 :0] data_wstrb   ,
    output [31:0] data_rdata   ,
    output        data_addr_ok ,
    output        data_data_ok ,

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
reg        do_wr_r;
reg [1 :0] do_size_r;
reg [3 :0] do_strb_r;
reg [31:0] do_addr_r;
reg [31:0] do_wdata_r;
wire data_back;

assign data_addr_ok = (!do_req) & data_req;
always @(posedge clk)
begin
    do_req     <= !rstn                       ? 1'b0 : 
                  (data_req) & !do_req ? 1'b1 :
                  data_back                     ? 1'b0 : do_req;
    do_wr_r    <= data_req & data_addr_ok ? data_wr : do_wr_r;
    do_size_r  <= data_req & data_addr_ok ? data_size : do_size_r;
    do_addr_r  <= data_req & data_addr_ok ? data_addr : do_addr_r;
    do_strb_r  <= data_req & data_addr_ok ? data_wstrb : do_strb_r;
    do_wdata_r <= data_req & data_addr_ok ? data_wdata :do_wdata_r;
end

//inst sram-like
assign data_data_ok = do_req & data_back;
assign data_rdata   = rdata;

//---axi
reg addr_rcv;
reg wdata_rcv;

assign data_back = addr_rcv & ((rvalid & rready) | (bvalid & bready));
always @(posedge clk)
begin
    addr_rcv  <= !rstn          ? 1'b0 :
                 arvalid & arready ? 1'b1 :
                 awvalid & awready ? 1'b1 :
                 data_back        ? 1'b0 : addr_rcv;
    wdata_rcv <= !rstn        ? 1'b0 :
                 wvalid & wready ? 1'b1 :
                 data_back      ? 1'b0 : wdata_rcv;
end
//ar
assign arid    = 4'd5;
assign araddr  = do_addr_r;
assign arlen   = 8'd0;
assign arsize  = do_size_r;
assign arburst = 2'd0;
assign arlock  = 2'd0;
assign arcache = 4'd0;
assign arprot  = 3'd0;
assign arvalid = do_req & !do_wr_r & !addr_rcv;
//r
assign rready  = 1'b1;

//aw
assign awid    = 4'd6;
assign awaddr  = do_addr_r;
assign awlen   = 8'd0;
assign awsize  = do_size_r;
assign awburst = 2'd0;
assign awlock  = 2'd0;
assign awcache = 4'd0;
assign awprot  = 3'd0;
assign awvalid = do_req & do_wr_r & !addr_rcv;
//w
assign wid    = 4'd0;
assign wdata  = do_wdata_r;
assign wstrb  = do_strb_r;
assign wlast  = 1'd1;
assign wvalid = do_req & do_wr_r & !wdata_rcv;
//b
assign bready  = 1'b1;

endmodule
