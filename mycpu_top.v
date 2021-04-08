`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/02/2020 11:26:24 PM
// Design Name: 
// Module Name: mycpu_top
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
module mycpu_top(
    input [5:0]   ext_int, 

    input         aclk,
    input         aresetn, 

    output [3:0]  arid,
    output [31:0] araddr,
    output [3:0]  arlen,
    output [2:0]  arsize,
    output [1:0]  arburst,
    output [1:0]  arlock,
    output [3:0]  arcache,
    output [2:0]  arprot,
    output        arvalid,
    input         arready,

    input [3:0]   rid,
    input [31:0]  rdata,
    input [1:0]   rresp,
    input         rlast,
    input         rvalid,
    output        rready,

    output [3:0]  awid,
    output [31:0] awaddr,
    output [3:0]  awlen,
    output [2:0]  awsize,
    output [1:0]  awburst,
    output [1:0]  awlock,
    output [3:0]  awcache,
    output [2:0]  awprot,
    output        awvalid,
    input         awready,

    output [3:0]  wid,
    output [31:0] wdata,
    output [3:0]  wstrb,
    output        wlast,
    output        wvalid,
    input         wready,
    //b              
    input [3:0]   bid,
    input [1:0]   bresp,
    input         bvalid,
    output        bready,

    //debug interface
    output  [31:0]   debug_wb_pc,
    output  [3 :0]   debug_wb_rf_wen,
    output  [4 :0]   debug_wb_rf_wnum,
    output  [31:0]   debug_wb_rf_wdata
    );

    //---------------------Cache Enable----------------------
    wire use_inst_cache;//1->inst_cache
    wire use_data_cache;//1->data_cache
   
    //-------------------Pipeline Singal-----------------------
    wire        inst_stall;
    wire        data_stall;
    //-------Simple mmu
    wire [31:0] redi_inst_addr;
    wire [31:0] redi_data_addr;
    
    //-------Inst and Data FIFO
    //------Inst
    reg [7:0] fifo_inst;
    reg [2:0] inst_ptr_wr;
    reg [2:0] inst_ptr_rd;
    //------Data
    reg [7:0] fifo_data;
    reg [2:0] data_ptr_wr;
    reg [2:0] data_ptr_rd;
    //-----------------Axi Singal------------------------------
    //------------Inst Cache-----------
    wire  [3 :0] inst_cache_arid   ;
    wire  [31:0] inst_cache_araddr ;
    wire  [7 :0] inst_cache_arlen  ;
    wire  [2 :0] inst_cache_arsize ;
    wire  [1 :0] inst_cache_arburst;
    wire  [1 :0] inst_cache_arlock ;
    wire  [3 :0] inst_cache_arcache;
    wire  [2 :0] inst_cache_arprot ;
    wire         inst_cache_arvalid;
    wire         inst_cache_arready;

    wire  [3 :0] inst_cache_rid    ;
    wire  [31:0] inst_cache_rdata  ;
    wire  [1 :0] inst_cache_rresp  ;
    wire         inst_cache_rlast  ;
    wire         inst_cache_rvalid ;
    wire         inst_cache_rready ;

    wire  [3 :0] inst_cache_awid   ;
    wire  [31:0] inst_cache_awaddr ;
    wire  [7 :0] inst_cache_awlen  ;
    wire  [2 :0] inst_cache_awsize ;
    wire  [1 :0] inst_cache_awburst;
    wire  [1 :0] inst_cache_awlock ;
    wire  [3 :0] inst_cache_awcache;
    wire  [2 :0] inst_cache_awprot ;
    wire         inst_cache_awvalid;
    wire         inst_cache_awready;

    wire  [3 :0] inst_cache_wid    ;
    wire  [31:0] inst_cache_wdata  ;
    wire  [3 :0] inst_cache_wstrb  ;
    wire         inst_cache_wlast  ;
    wire         inst_cache_wvalid ;
    wire         inst_cache_wready ;

    wire  [3 :0] inst_cache_bid    ;
    wire  [1 :0] inst_cache_bresp  ;
    wire         inst_cache_bvalid ;
    wire         inst_cache_bready ;

    //-----------Inst Uncache
    wire  [3 :0] inst_uncache_arid   ;
    wire  [31:0] inst_uncache_araddr ;
    wire  [7 :0] inst_uncache_arlen  ;
    wire  [2 :0] inst_uncache_arsize ;
    wire  [1 :0] inst_uncache_arburst;
    wire  [1 :0] inst_uncache_arlock ;
    wire  [3 :0] inst_uncache_arcache;
    wire  [2 :0] inst_uncache_arprot ;
    wire         inst_uncache_arvalid;
    wire         inst_uncache_arready;

    wire  [3 :0] inst_uncache_rid    ;
    wire  [31:0] inst_uncache_rdata  ;
    wire  [1 :0] inst_uncache_rresp  ;
    wire         inst_uncache_rlast  ;
    wire         inst_uncache_rvalid ;
    wire         inst_uncache_rready ;

    wire  [3 :0] inst_uncache_awid   ;
    wire  [31:0] inst_uncache_awaddr ;
    wire  [7 :0] inst_uncache_awlen  ;
    wire  [2 :0] inst_uncache_awsize ;
    wire  [1 :0] inst_uncache_awburst;
    wire  [1 :0] inst_uncache_awlock ;
    wire  [3 :0] inst_uncache_awcache;
    wire  [2 :0] inst_uncache_awprot ;
    wire         inst_uncache_awvalid;
    wire         inst_uncache_awready;

    wire  [3 :0] inst_uncache_wid    ;
    wire  [31:0] inst_uncache_wdata  ;
    wire  [3 :0] inst_uncache_wstrb  ;
    wire         inst_uncache_wlast  ;
    wire         inst_uncache_wvalid ;
    wire         inst_uncache_wready ;

    wire  [3 :0] inst_uncache_bid    ;
    wire  [1 :0] inst_uncache_bresp  ;
    wire         inst_uncache_bvalid ;
    wire         inst_uncache_bready ;

    //------------Data Cache
    wire  [3 :0] data_cache_arid   ;
    wire  [31:0] data_cache_araddr ;
    wire  [7 :0] data_cache_arlen  ;
    wire  [2 :0] data_cache_arsize ;
    wire  [1 :0] data_cache_arburst;
    wire  [1 :0] data_cache_arlock ;
    wire  [3 :0] data_cache_arcache;
    wire  [2 :0] data_cache_arprot ;
    wire         data_cache_arvalid;
    wire         data_cache_arready;

    wire  [3 :0] data_cache_rid    ;
    wire  [31:0] data_cache_rdata  ;
    wire  [1 :0] data_cache_rresp  ;
    wire         data_cache_rlast  ;
    wire         data_cache_rvalid ;
    wire         data_cache_rready ;

    wire  [3 :0] data_cache_awid   ;
    wire  [31:0] data_cache_awaddr ;
    wire  [7 :0] data_cache_awlen  ;
    wire  [2 :0] data_cache_awsize ;
    wire  [1 :0] data_cache_awburst;
    wire  [1 :0] data_cache_awlock ;
    wire  [3 :0] data_cache_awcache;
    wire  [2 :0] data_cache_awprot ;
    wire         data_cache_awvalid;
    wire         data_cache_awready;

    wire  [3 :0] data_cache_wid    ;
    wire  [31:0] data_cache_wdata  ;
    wire  [3 :0] data_cache_wstrb  ;
    wire         data_cache_wlast  ;
    wire         data_cache_wvalid ;
    wire         data_cache_wready ;

    wire  [3 :0] data_cache_bid    ;
    wire  [1 :0] data_cache_bresp  ;
    wire         data_cache_bvalid ;
    wire         data_cache_bready ;

    //-----------Data Uncache
    wire  [3 :0] data_uncache_arid   ;
    wire  [31:0] data_uncache_araddr ;
    wire  [7 :0] data_uncache_arlen  ;
    wire  [2 :0] data_uncache_arsize ;
    wire  [1 :0] data_uncache_arburst;
    wire  [1 :0] data_uncache_arlock ;
    wire  [3 :0] data_uncache_arcache;
    wire  [2 :0] data_uncache_arprot ;
    wire         data_uncache_arvalid;
    wire         data_uncache_arready;

    wire  [3 :0] data_uncache_rid    ;
    wire  [31:0] data_uncache_rdata  ;
    wire  [1 :0] data_uncache_rresp  ;
    wire         data_uncache_rlast  ;
    wire         data_uncache_rvalid ;
    wire         data_uncache_rready ;

    wire  [3 :0] data_uncache_awid   ;
    wire  [31:0] data_uncache_awaddr ;
    wire  [7 :0] data_uncache_awlen  ;
    wire  [2 :0] data_uncache_awsize ;
    wire  [1 :0] data_uncache_awburst;
    wire  [1 :0] data_uncache_awlock ;
    wire  [3 :0] data_uncache_awcache;
    wire  [2 :0] data_uncache_awprot ;
    wire         data_uncache_awvalid;
    wire         data_uncache_awready;

    wire  [3 :0] data_uncache_wid    ;
    wire  [31:0] data_uncache_wdata  ;
    wire  [3 :0] data_uncache_wstrb  ;
    wire         data_uncache_wlast  ;
    wire         data_uncache_wvalid ;
    wire         data_uncache_wready ;

    wire  [3 :0] data_uncache_bid    ;
    wire  [1 :0] data_uncache_bresp  ;
    wire         data_uncache_bvalid ;
    wire         data_uncache_bready ;

    //------------------------Module Singal---------------------
    //----------Cpu
    //-----Cpu Inst Singal
    wire        cpu_inst_req;
    wire [31:0] cpu_inst_addr;
    wire [31:0] cpu_inst_rdata;
    wire        cpu_inst_addr_ok;
    wire        cpu_inst_data_ok;
    //-----Cpu Data Singal
    wire        cpu_data_req;
    wire        cpu_data_wr;
    wire [3:0]  cpu_data_wstrb;
    wire [31:0] cpu_data_addr;
    wire [2 :0] cpu_data_size;
    wire [31:0] cpu_data_wdata;
    wire [31:0] cpu_data_rdata;
    wire        cpu_data_addr_ok;
    wire        cpu_data_data_ok;

    wire cpu_inst_cache_addr_ok;
    wire cpu_inst_cache_data_ok;
    wire [31:0] cpu_inst_cache_rdata;

    wire cpu_data_cache_addr_ok;
    wire cpu_data_cache_data_ok;
    wire [31:0] cpu_data_cache_rdata;

    wire cpu_inst_uncache_addr_ok;
    wire cpu_inst_uncache_data_ok;
    wire [31:0] cpu_inst_uncache_rdata;

    wire cpu_data_uncache_addr_ok;
    wire cpu_data_uncache_data_ok;
    wire [31:0] cpu_data_uncache_rdata;
    wire        inst_cache;
    wire        data_cache;
    //Cache
    wire               cache_req;
    wire  [6 :0]       cache_op;
    wire  [31:0]       cache_tag;
    wire               cache_op_ok;
    wire               inst_cache_op_ok;
    wire               data_cache_op_ok;
    assign cache_op_ok = inst_cache_op_ok | data_cache_op_ok;
    //----------Inst Cache
    wire        inst_req;
    wire        inst_wr;
    wire [1 :0] inst_size;
    wire [31:0] inst_addr;
    wire [31:0] inst_wdata;
    wire [3 :0] inst_wstrb;
    wire [31:0] inst_rdata;
    wire        inst_addr_ok;
    wire        inst_data_ok;
    //----------Inst Uncache
    wire        un_inst_req;
    wire        un_inst_wr;
    wire [1 :0] un_inst_size;
    wire [31:0] un_inst_addr;
    wire [31:0] un_inst_wdata;
    wire [3 :0] un_inst_wstrb;
    wire [31:0] un_inst_rdata;
    wire        un_inst_addr_ok;
    wire        un_inst_data_ok;
    //----------Data Cache
    wire        data_req;
    wire        data_wr;
    wire [1 :0] data_size;
    wire [31:0] data_addr;
    wire [31:0] data_wdata;
    wire [3 :0] data_wstrb;
    wire [31:0] data_rdata;
    wire        data_addr_ok;
    wire        data_data_ok;
    //----------Data Uncache
    wire        un_data_req;
    wire        un_data_wr;
    wire [1 :0] un_data_size;
    wire [31:0] un_data_addr;
    wire [31:0] un_data_wdata;
    wire [3 :0] un_data_wstrb;
    wire [31:0] un_data_rdata;
    wire        un_data_addr_ok;
    wire        un_data_data_ok;
    //---------Store Buffer---------
    wire        store_buffer_write_req;
    wire        store_buffer_write_wr;
    wire [1 :0] store_buffer_write_size;
    wire [31:0] store_buffer_write_addr;
    wire [31:0] store_buffer_write_wdata;
    wire [3 :0] store_buffer_write_wstrb;
    wire [31:0] store_buffer_write_rdata;
    wire        store_buffer_write_addr_ok;
    wire        store_buffer_write_data_ok;
    //-------------Pipeline FIFO-----------------
    //------Enable
    //TODO: req
    assign use_inst_cache = (cpu_inst_req)?inst_cache:1'b0;
    assign use_data_cache = data_cache;
    //-----Stall
    assign inst_stall = (!(fifo_inst[inst_ptr_rd] ^ use_inst_cache))?1'b1:(!(inst_ptr_wr ^ inst_ptr_rd));
    assign data_stall = (!(fifo_data[data_ptr_rd] ^ use_data_cache))?1'b1:(!(data_ptr_wr ^ data_ptr_rd));
    //-----Redi
    //Simple mmu
    assign redi_inst_addr = {3'b000, cpu_inst_addr[28:0]};
    assign redi_data_addr = {3'b000, cpu_data_addr[28:0]};
    //-----Rdata Addr Data
    assign cpu_inst_rdata   = fifo_inst[inst_ptr_rd]?cpu_inst_cache_rdata:cpu_inst_uncache_rdata;
    assign cpu_inst_data_ok = cpu_inst_cache_data_ok | cpu_inst_uncache_data_ok;
    assign cpu_inst_addr_ok = (use_inst_cache)?cpu_inst_cache_addr_ok:cpu_inst_uncache_addr_ok;
  
    assign cpu_data_rdata   = fifo_data[data_ptr_rd]?cpu_data_cache_rdata:cpu_data_uncache_rdata;
    assign cpu_data_data_ok = cpu_data_cache_data_ok | cpu_data_uncache_data_ok;
    assign cpu_data_addr_ok = (use_data_cache)?cpu_data_cache_addr_ok:cpu_data_uncache_addr_ok;
    //-----Inst
    always @(posedge aclk) begin
        if (!aresetn) begin
            inst_ptr_wr <= 3'b0;
            //fifo_inst <= 8'b0;
        end        
        else if (cpu_inst_addr_ok & cpu_inst_req & inst_stall) begin
            inst_ptr_wr <= inst_ptr_wr + 3'b1;
            //fifo_inst[inst_ptr_wr] <= use_inst_cache;
        end
        else begin
        end
    end

    always @(posedge aclk) begin
        if (!aresetn) begin
            fifo_inst <= 8'b0;
        end        
        else if (cpu_inst_addr_ok & cpu_inst_req & inst_stall) begin
            fifo_inst[inst_ptr_wr] <= use_inst_cache;
        end
        else begin
        end
    end


    always @(posedge aclk) begin
        if (!aresetn) begin
            inst_ptr_rd <= 3'b0;
        end
        else if (cpu_inst_data_ok) begin
            inst_ptr_rd <= inst_ptr_rd + 3'b1;
        end
        else begin
        end
    end

    //-----Data
    always @(posedge aclk) begin
        if (!aresetn) begin
            data_ptr_wr <= 3'b0;
            //fifo_data <= 8'b0;
        end        
        else if (cpu_data_addr_ok & cpu_data_req & data_stall) begin
            data_ptr_wr <= data_ptr_wr + 3'b1;
            //fifo_data[data_ptr_wr] <= use_data_cache;
        end
        else begin
        end
    end

    always @(posedge aclk) begin
        if (!aresetn) begin
            fifo_data <= 8'b0;
        end        
        else if (cpu_data_addr_ok & cpu_data_req & data_stall) begin
            fifo_data[data_ptr_wr] <= use_data_cache;
        end
        else begin
        end
    end

    always @(posedge aclk) begin
        if (!aresetn) begin
            data_ptr_rd <= 3'b0;
        end
        else if (cpu_data_data_ok) begin
            data_ptr_rd <= data_ptr_rd + 3'b1;
        end
        else begin
        end
    end
    //------------------------Module Singal Assignment----------------------

    //----------Inst Cache
    assign inst_req   = cpu_inst_req & use_inst_cache & inst_stall;
    assign inst_wr    = 1'b0;
    assign inst_size  = 2'b0;
    assign inst_addr  = redi_inst_addr;
    assign inst_wdata = 32'b0;
    assign inst_wstrb = 4'b0;
    assign cpu_inst_cache_rdata   = inst_rdata;
    assign cpu_inst_cache_addr_ok = inst_addr_ok;
    assign cpu_inst_cache_data_ok = inst_data_ok;
    //----------Inst Uncache
    assign un_inst_req   = cpu_inst_req & !use_inst_cache & inst_stall;
    assign un_inst_wr    = 1'b0;
    assign un_inst_size  = 2'b00;
    assign un_inst_addr  = cpu_inst_addr;
    assign un_inst_wdata = 32'b0;
    assign un_inst_wstrb = 4'b0;
    assign cpu_inst_uncache_rdata   = un_inst_rdata;
    assign cpu_inst_uncache_addr_ok = un_inst_addr_ok;
    assign cpu_inst_uncache_data_ok = un_inst_data_ok;
    //----------Data Cache
    assign data_req   = cpu_data_req & use_data_cache & data_stall;
    assign data_wr    = cpu_data_wr;
    assign data_size  = cpu_data_size;
    assign data_addr  = cpu_data_addr;
    assign data_wdata = cpu_data_wdata;
    assign data_wstrb = cpu_data_wstrb;
    assign cpu_data_cache_rdata   = data_rdata;
    assign cpu_data_cache_addr_ok = data_addr_ok;
    assign cpu_data_cache_data_ok = data_data_ok;
    //---------Store Buffer---------
    assign store_buffer_write_req   = cpu_data_req & !use_data_cache & data_stall;
    assign store_buffer_write_wr    = cpu_data_wr;
    assign store_buffer_write_size  = cpu_data_size;
    assign store_buffer_write_addr  = cpu_data_addr;
    assign store_buffer_write_wdata = cpu_data_wdata;
    assign store_buffer_write_wstrb = cpu_data_wstrb;
    assign cpu_data_uncache_rdata   = store_buffer_write_rdata;
    assign cpu_data_uncache_addr_ok = store_buffer_write_addr_ok;
    assign cpu_data_uncache_data_ok = store_buffer_write_data_ok;
    //-------------------------Module----------------------------------------
    //-------------CPU Core
    cpu_core cpu(
        .ext_int(ext_int),
        .aclk    (aclk),
        .aresetn (aresetn),

        .inst_req    (cpu_inst_req  ),
        .inst_addr   (cpu_inst_addr ),
        .inst_rdata  (cpu_inst_rdata),
        .inst_addr_ok(cpu_inst_addr_ok & inst_stall),
        .inst_data_ok(cpu_inst_data_ok),

        .data_req    (cpu_data_req  ),
        .data_wr     (cpu_data_wr   ),
        .data_wstrb  (cpu_data_wstrb),
        .data_addr   (cpu_data_addr ),
        .data_size   (cpu_data_size ),
        .data_wdata  (cpu_data_wdata),
        .data_rdata  (cpu_data_rdata),
        .data_addr_ok(cpu_data_addr_ok & data_stall),
        .data_data_ok(cpu_data_data_ok),

        .cache_req  (cache_req),
        .cache_op   (cache_op),
        .cache_tag  (cache_tag),
        .cache_over(cache_op_ok),

        .debug_wb_pc      (debug_wb_pc      ),
        .debug_wb_rf_wen  (debug_wb_rf_wen  ),
        .debug_wb_rf_wnum (debug_wb_rf_wnum ),
        .debug_wb_rf_wdata(debug_wb_rf_wdata),
        
        .inst_cache(inst_cache),
        .data_cache(data_cache)
    );
    //-------------Inst Cache
    inst_cache u_inst_cache (
        .clk (aclk),   
        .rstn(aresetn),   

        .cache_req  (cache_req),
        .cache_op   (cache_op),
        .cache_op_ok(inst_cache_op_ok),
        .cache_tag  (32'b0),

        .inst_req     (inst_req    ),
        .inst_size    (inst_size   ),
        .inst_addr    (inst_addr   ),
        .inst_rdata   (inst_rdata  ),
        .inst_addr_ok (inst_addr_ok),
        .inst_data_ok (inst_data_ok),

        .arid         (inst_cache_arid   ),
        .araddr       (inst_cache_araddr ),
        .arlen        (inst_cache_arlen  ),
        .arsize       (inst_cache_arsize ),
        .arburst      (inst_cache_arburst),
        .arlock       (inst_cache_arlock ),
        .arcache      (inst_cache_arcache),
        .arprot       (inst_cache_arprot ),
        .arvalid      (inst_cache_arvalid),
        .arready      (inst_cache_arready),

        .rid          (inst_cache_rid   ),
        .rdata        (inst_cache_rdata ),
        .rresp        (inst_cache_rresp ),
        .rlast        (inst_cache_rlast ),
        .rvalid       (inst_cache_rvalid),
        .rready       (inst_cache_rready),

        .awid         (inst_cache_awid   ),
        .awaddr       (inst_cache_awaddr ),
        .awlen        (inst_cache_awlen  ),
        .awsize       (inst_cache_awsize ),
        .awburst      (inst_cache_awburst),
        .awlock       (inst_cache_awlock ),
        .awcache      (inst_cache_awcache),
        .awprot       (inst_cache_awprot ),
        .awvalid      (inst_cache_awvalid),
        .awready      (inst_cache_awready),

        .wid          (inst_cache_wid   ),
        .wdata        (inst_cache_wdata ),
        .wstrb        (inst_cache_wstrb ),
        .wlast        (inst_cache_wlast ),
        .wvalid       (inst_cache_wvalid),
        .wready       (inst_cache_wready),

        .bid          (inst_cache_bid   ),
        .bresp        (inst_cache_bresp ),
        .bvalid       (inst_cache_bvalid),
        .bready       (inst_cache_bready)
    );
    //-------------Data Cache
    data_cache u_data_cache (
        .clk (aclk),   
        .rstn(aresetn),   

        .cache_req  (cache_req),
        .cache_op   (cache_op),
        .cache_op_ok(data_cache_op_ok),
        .cache_tag  (32'b0),

        .data_req     (data_req     ),
        .data_wr      (data_wr     ),
        .data_size    (data_size   ),
        .data_addr    (data_addr   ),
        .data_wdata   (data_wdata  ),
        .data_wstrb   (data_wstrb  ),
        .data_rdata   (data_rdata  ),
        .data_addr_ok (data_addr_ok),
        .data_data_ok (data_data_ok),

        .arid         (data_cache_arid   ),
        .araddr       (data_cache_araddr ),
        .arlen        (data_cache_arlen  ),
        .arsize       (data_cache_arsize ),
        .arburst      (data_cache_arburst),
        .arlock       (data_cache_arlock ),
        .arcache      (data_cache_arcache),
        .arprot       (data_cache_arprot ),
        .arvalid      (data_cache_arvalid),
        .arready      (data_cache_arready),

        .rid          (data_cache_rid   ),
        .rdata        (data_cache_rdata ),
        .rresp        (data_cache_rresp ),
        .rlast        (data_cache_rlast ),
        .rvalid       (data_cache_rvalid),
        .rready       (data_cache_rready),

        .awid         (data_cache_awid   ),
        .awaddr       (data_cache_awaddr ),
        .awlen        (data_cache_awlen  ),
        .awsize       (data_cache_awsize ),
        .awburst      (data_cache_awburst),
        .awlock       (data_cache_awlock ),
        .awcache      (data_cache_awcache),
        .awprot       (data_cache_awprot ),
        .awvalid      (data_cache_awvalid),
        .awready      (data_cache_awready),

        .wid          (data_cache_wid   ),
        .wdata        (data_cache_wdata ),
        .wstrb        (data_cache_wstrb ),
        .wlast        (data_cache_wlast ),
        .wvalid       (data_cache_wvalid),
        .wready       (data_cache_wready),

        .bid          (data_cache_bid   ),
        .bresp        (data_cache_bresp ),
        .bvalid       (data_cache_bvalid),
        .bready       (data_cache_bready)
    );
    //--------Inst Uncache
    inst_uncache u_inst_uncache (
        .clk (aclk),   
        .rstn(aresetn),   

        .inst_req     (un_inst_req    ),
        .inst_size    (un_inst_size   ),
        .inst_addr    (un_inst_addr   ),
        .inst_wdata   (un_inst_wdata  ),
        .inst_rdata   (un_inst_rdata  ),
        .inst_addr_ok (un_inst_addr_ok),
        .inst_data_ok (un_inst_data_ok),

        //axi 
        .arid         (inst_uncache_arid   ),
        .araddr       (inst_uncache_araddr ),
        .arlen        (inst_uncache_arlen  ),
        .arsize       (inst_uncache_arsize ),
        .arburst      (inst_uncache_arburst),
        .arlock       (inst_uncache_arlock ),
        .arcache      (inst_uncache_arcache),
        .arprot       (inst_uncache_arprot ),
        .arvalid      (inst_uncache_arvalid),
        .arready      (inst_uncache_arready),

        .rid          (inst_uncache_rid   ),
        .rdata        (inst_uncache_rdata ),
        .rresp        (inst_uncache_rresp ),
        .rlast        (inst_uncache_rlast ),
        .rvalid       (inst_uncache_rvalid),
        .rready       (inst_uncache_rready),

        .awid         (inst_uncache_awid   ),
        .awaddr       (inst_uncache_awaddr ),
        .awlen        (inst_uncache_awlen  ),
        .awsize       (inst_uncache_awsize ),
        .awburst      (inst_uncache_awburst),
        .awlock       (inst_uncache_awlock ),
        .awcache      (inst_uncache_awcache),
        .awprot       (inst_uncache_awprot ),
        .awvalid      (inst_uncache_awvalid),
        .awready      (inst_uncache_awready),

        .wid          (inst_uncache_wid   ),
        .wdata        (inst_uncache_wdata ),
        .wstrb        (inst_uncache_wstrb ),
        .wlast        (inst_uncache_wlast ),
        .wvalid       (inst_uncache_wvalid),
        .wready       (inst_uncache_wready),

        .bid          (inst_uncache_bid   ),
        .bresp        (inst_uncache_bresp ),
        .bvalid       (inst_uncache_bvalid),
        .bready       (inst_uncache_bready)
    );
    //-----Data Uncache
    data_uncache u_data_uncache (
        .clk (aclk),   
        .rstn(aresetn),   

        .data_req     (un_data_req    ),
        .data_wr      (un_data_wr     ),
        .data_size    (un_data_size   ),
        .data_addr    (un_data_addr   ),
        .data_wdata   (un_data_wdata  ),
        .data_wstrb   (un_data_wstrb  ),
        .data_rdata   (un_data_rdata  ),
        .data_addr_ok (un_data_addr_ok),
        .data_data_ok (un_data_data_ok),

        //axi 
        .arid         (data_uncache_arid   ),
        .araddr       (data_uncache_araddr ),
        .arlen        (data_uncache_arlen  ),
        .arsize       (data_uncache_arsize ),
        .arburst      (data_uncache_arburst),
        .arlock       (data_uncache_arlock ),
        .arcache      (data_uncache_arcache),
        .arprot       (data_uncache_arprot ),
        .arvalid      (data_uncache_arvalid),
        .arready      (data_uncache_arready),

        .rid          (data_uncache_rid   ),
        .rdata        (data_uncache_rdata ),
        .rresp        (data_uncache_rresp ),
        .rlast        (data_uncache_rlast ),
        .rvalid       (data_uncache_rvalid),
        .rready       (data_uncache_rready),

        .awid         (data_uncache_awid   ),
        .awaddr       (data_uncache_awaddr ),
        .awlen        (data_uncache_awlen  ),
        .awsize       (data_uncache_awsize ),
        .awburst      (data_uncache_awburst),
        .awlock       (data_uncache_awlock ),
        .awcache      (data_uncache_awcache),
        .awprot       (data_uncache_awprot ),
        .awvalid      (data_uncache_awvalid),
        .awready      (data_uncache_awready),

        .wid          (data_uncache_wid   ),
        .wdata        (data_uncache_wdata ),
        .wstrb        (data_uncache_wstrb ),
        .wlast        (data_uncache_wlast ),
        .wvalid       (data_uncache_wvalid),
        .wready       (data_uncache_wready),

        .bid          (data_uncache_bid   ),
        .bresp        (data_uncache_bresp ),
        .bvalid       (data_uncache_bvalid),
        .bready       (data_uncache_bready)
    );

    //-----Store Buffer
    store_buffer u_store_buffer(
        .clk   (aclk),
        .rstn(aresetn),

        .store_buffer_write_req       (store_buffer_write_req    ),
        .store_buffer_write_wr        (store_buffer_write_wr     ),
        .store_buffer_write_size      (store_buffer_write_size   ),
        .store_buffer_write_addr      (store_buffer_write_addr   ),
        .store_buffer_write_wdata     (store_buffer_write_wdata  ),
        .store_buffer_write_wstrb     (store_buffer_write_wstrb  ),
        .store_buffer_write_rdata     (store_buffer_write_rdata  ),
        .store_buffer_write_addr_ok   (store_buffer_write_addr_ok),
        .store_buffer_write_data_ok   (store_buffer_write_data_ok),

        .store_buffer_read_req    (un_data_req    ),
        .store_buffer_read_wr     (un_data_wr     ),
        .store_buffer_read_size   (un_data_size   ),
        .store_buffer_read_addr   (un_data_addr   ),
        .store_buffer_read_wdata  (un_data_wdata  ),
        .store_buffer_read_wstrb  (un_data_wstrb  ),
        .store_buffer_read_rdata  (un_data_rdata  ),
        .store_buffer_read_addr_ok(un_data_addr_ok),
        .store_buffer_read_data_ok(un_data_data_ok)
    );
    //-----Axi Bridge
    axi_cache_bridge u_axi_cache_bridge (

        .aclk             (aclk   ),                
        .aresetn          (aresetn),                

        .s_axi_arid       ({data_cache_arid,       inst_cache_arid,       data_uncache_arid,       inst_uncache_arid}      ),
        .s_axi_araddr     ({data_cache_araddr,     inst_cache_araddr,     data_uncache_araddr,     inst_uncache_araddr}    ),
        .s_axi_arlen      ({data_cache_arlen[3:0], inst_cache_arlen[3:0], data_uncache_arlen[3:0], inst_uncache_arlen[3:0]}),
        .s_axi_arsize     ({data_cache_arsize,     inst_cache_arsize,     data_uncache_arsize,     inst_uncache_arsize}    ),
        .s_axi_arburst    ({data_cache_arburst,    inst_cache_arburst,    data_uncache_arburst,    inst_uncache_arburst}   ),
        .s_axi_arlock     ({data_cache_arlock,     inst_cache_arlock,     data_uncache_arlock,     inst_uncache_arlock}    ),
        .s_axi_arcache    ({data_cache_arcache,    inst_cache_arcache,    data_uncache_arcache,    inst_uncache_arcache}   ),
        .s_axi_arprot     ({data_cache_arprot,     inst_cache_arprot,     data_uncache_arprot,     inst_uncache_arprot}    ),
        .s_axi_arqos      ({4'd0,4'd0,4'd0,4'd0}),
        .s_axi_arvalid    ({data_cache_arvalid,    inst_cache_arvalid,    data_uncache_arvalid,    inst_uncache_arvalid}   ),
        .s_axi_arready    ({data_cache_arready,    inst_cache_arready,    data_uncache_arready,    inst_uncache_arready}   ),

        .s_axi_rid        ({data_cache_rid,        inst_cache_rid,        data_uncache_rid,        inst_uncache_rid}       ),
        .s_axi_rdata      ({data_cache_rdata,      inst_cache_rdata,      data_uncache_rdata,      inst_uncache_rdata}     ),
        .s_axi_rresp      ({data_cache_rresp,      inst_cache_rresp,      data_uncache_rresp,      inst_uncache_rresp}     ),
        .s_axi_rlast      ({data_cache_rlast,      inst_cache_rlast,      data_uncache_rlast,      inst_uncache_rlast}     ),
        .s_axi_rvalid     ({data_cache_rvalid,     inst_cache_rvalid,     data_uncache_rvalid,     inst_uncache_rvalid}    ),
        .s_axi_rready     ({data_cache_rready,     inst_cache_rready,     data_uncache_rready,     inst_uncache_rready}    ),

        .s_axi_awid       ({data_cache_awid,       inst_cache_awid,       data_uncache_awid,       inst_uncache_awid}      ),
        .s_axi_awaddr     ({data_cache_awaddr,     inst_cache_awaddr,     data_uncache_awaddr,     inst_uncache_awaddr}    ),
        .s_axi_awlen      ({data_cache_awlen[3:0], inst_cache_awlen[3:0], data_uncache_awlen[3:0], inst_uncache_awlen[3:0]}),
        .s_axi_awsize     ({data_cache_awsize,     inst_cache_awsize,     data_uncache_awsize,     inst_uncache_awsize}    ),
        .s_axi_awburst    ({data_cache_awburst,    inst_cache_awburst,    data_uncache_awburst,    inst_uncache_awburst}   ),
        .s_axi_awlock     ({data_cache_awlock,     inst_cache_awlock,     data_uncache_awlock,     inst_uncache_awlock}    ),
        .s_axi_awcache    ({data_cache_awcache,    inst_cache_awcache,    data_uncache_awcache,    inst_uncache_awcache}   ),
        .s_axi_awprot     ({data_cache_awprot,     inst_cache_awprot,     data_uncache_awprot,     inst_uncache_awprot}    ),
        .s_axi_awqos      ({4'd0,4'd0,4'd0,4'd0}),
        .s_axi_awvalid    ({data_cache_awvalid,    inst_cache_awvalid,    data_uncache_awvalid,    inst_uncache_awvalid}   ),
        .s_axi_awready    ({data_cache_awready,    inst_cache_awready,    data_uncache_awready,    inst_uncache_awready}   ),

        .s_axi_wid        ({data_cache_wid,        inst_cache_wid,        data_uncache_wid,        inst_uncache_wid}       ),
        .s_axi_wdata      ({data_cache_wdata,      inst_cache_wdata,      data_uncache_wdata,      inst_uncache_wdata}     ),
        .s_axi_wstrb      ({data_cache_wstrb,      inst_cache_wstrb,      data_uncache_wstrb,      inst_uncache_wstrb}     ),
        .s_axi_wlast      ({data_cache_wlast,      inst_cache_wlast,      data_uncache_wlast,      inst_uncache_wlast}     ),
        .s_axi_wvalid     ({data_cache_wvalid,     inst_cache_wvalid,     data_uncache_wvalid,     inst_uncache_wvalid}    ),
        .s_axi_wready     ({data_cache_wready,     inst_cache_wready,     data_uncache_wready,     inst_uncache_wready}    ),
        .s_axi_bid        ({data_cache_bid,        inst_cache_bid,        data_uncache_bid,        inst_uncache_bid}       ),
        .s_axi_bresp      ({data_cache_bresp,      inst_cache_bresp,      data_uncache_bresp,      inst_uncache_bresp}     ),
        .s_axi_bvalid     ({data_cache_bvalid,     inst_cache_bvalid,     data_uncache_bvalid,     inst_uncache_bvalid}    ),
        .s_axi_bready     ({data_cache_bready,     inst_cache_bready,     data_uncache_bready,     inst_uncache_bready}    ),

        .m_axi_arid       (arid   ),
        .m_axi_araddr     (araddr ),
        .m_axi_arlen      (arlen  ),
        .m_axi_arsize     (arsize ),
        .m_axi_arburst    (arburst),
        .m_axi_arlock     (arlock ),
        .m_axi_arcache    (arcache),
        .m_axi_arprot     (arprot ),
        .m_axi_arqos      (       ),
        .m_axi_arvalid    (arvalid),
        .m_axi_arready    (arready),
        .m_axi_rid        (rid    ),
        .m_axi_rdata      (rdata  ),
        .m_axi_rresp      (rresp  ),
        .m_axi_rlast      (rlast  ),
        .m_axi_rvalid     (rvalid ),
        .m_axi_rready     (rready ),
        .m_axi_awid       (awid   ),
        .m_axi_awaddr     (awaddr ),
        .m_axi_awlen      (awlen  ),
        .m_axi_awsize     (awsize ),
        .m_axi_awburst    (awburst),
        .m_axi_awlock     (awlock ),
        .m_axi_awcache    (awcache),
        .m_axi_awprot     (awprot ),
        .m_axi_awqos      (       ),
        .m_axi_awvalid    (awvalid),
        .m_axi_awready    (awready),
        .m_axi_wid        (wid    ),
        .m_axi_wdata      (wdata  ),
        .m_axi_wstrb      (wstrb  ),
        .m_axi_wlast      (wlast  ),
        .m_axi_wvalid     (wvalid ),
        .m_axi_wready     (wready ),
        .m_axi_bid        (bid    ),
        .m_axi_bresp      (bresp  ),
        .m_axi_bvalid     (bvalid ),
        .m_axi_bready     (bready )
    );
endmodule
