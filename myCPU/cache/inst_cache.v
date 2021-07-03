`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/26/2020 04:04:41 PM
// Design Name: 
// Module Name: inst_cache
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
`include "../include/Parameter.vh"
`include "../include/Cache.vh"
`define B2 2
`define B1 1
`define B0 0

module inst_cache(
    input         clk,
    input         rstn,
    //cache op
    input		  cache_req,
    input	[6:0] cache_op,
    input   [31:0]cache_tag,
    output		  cache_op_ok,
    // from cpu, sram like
    input         inst_req,
    input  [1:0]  inst_size,
    input  [`PC_WIDTH-1:0] inst_addr,
    output [`INS_LEN-1:0] inst_rdata,
    output        inst_addr_ok,
    output        inst_data_ok,
    //axi
    output [3 :0] arid   ,
    output [31:0] araddr ,
    output [7 :0] arlen  ,
    output [2 :0] arsize ,
    output [1 :0] arburst,
    output [1 :0] arlock ,
    output [3 :0] arcache,
    output [2 :0] arprot ,
    output        arvalid,
    input         arready,

    input  [3 :0] rid    ,
    input  [31:0] rdata  ,
    input  [1 :0] rresp ,
    input         rlast ,
    input         rvalid ,
    output        rready,

    output [3 :0] awid   ,
    output [31:0] awaddr ,
    output [7 :0] awlen  ,
    output [2 :0] awsize ,
    output [1 :0] awburst,
    output [1 :0] awlock ,
    output [3 :0] awcache,
    output [2 :0] awprot ,
    output        awvalid,
    input         awready,

    output [3 :0] wid    ,
    output [31:0] wdata  ,
    output [3 :0] wstrb  ,
    output        wlast  ,
    output        wvalid ,
    input         wready ,

    input  [3 :0] bid    ,
    input  [1 :0] bresp  ,
    input         bvalid ,
    output        bready 
    );
    //------------------------------------------------
     wire [`INST_CACHE_TAG_WIDTH-1   :0] tag;
     wire [`INST_CACHE_INDEX_WIDTH-1 :0] index;
     wire [`INST_CACHE_OFFSET_WIDTH-1:0] offset;
    assign tag    = inst_addr[`INST_CACHE_TAG];
    assign index  = inst_addr[`INST_CACHE_INDEX];
    assign offset = inst_addr[`INST_CACHE_OFFSET];
    //-------------State--------------------
    parameter IDLE   = 4'b0000;
    parameter RUN    = 4'b0001;
    parameter MISS   = 4'b0010;
    parameter WAIT_FOR_AXI = 4'b0011;
    parameter REFILL = 4'b0100;
    parameter FINISH = 4'b0101;
    parameter WRITE_BACK          = 4'b0110;
    parameter WAIT_FOR_PRE_AXI    = 4'b1000; 
    parameter WAIT_FOR_PRE_REFILL = 4'b1001;

   parameter RESETN = 4'b1111;

     reg  [3:0] state;
    wire [3:0] state_d;
    assign state_d = state;

    wire idle   = !(state_d ^ IDLE);
    wire run    = !(state_d ^ RUN);
    wire miss   = !(state_d ^ MISS);
    wire wait_for_axi = !(state_d ^ WAIT_FOR_AXI);
    wire finish = !(state_d ^ FINISH);
    wire refill = !(state_d ^ REFILL);
    wire write_back = !(state_d ^ WRITE_BACK);
    wire resetn = !(state_d ^ RESETN);  

    wire wait_for_pre_axi    = !(state_d ^ WAIT_FOR_PRE_AXI);
    wire wait_for_pre_refill = !(state_d ^ WAIT_FOR_PRE_REFILL);


    //-------------Pre State---------------------
    parameter PRE_IDLE = 4'b0000;
    parameter PRE_RUN  = 4'b0001;
    parameter PRE_GET_ADDR = 4'b0010;
    parameter PRE_MISS = 4'b0011;
    // parameter PRE_MISS_NEXT_LINE = 4'b0100;
    parameter PRE_WAIT_FOR_AXI = 4'b0101;
    parameter PRE_REFILL       = 4'b0110;
    parameter PRE_FINISH       = 4'b0111;
    parameter PRE_WRITE_BACK   = 4'b1000;
    parameter PRE_RESETN       = 4'b1111;

     reg [3 :0]  pre_state;
    wire [3 :0] pre_state_d;
    assign pre_state_d = pre_state;

    wire pre_idle   = !(pre_state_d ^ PRE_IDLE);
    wire pre_run    = !(pre_state_d ^ PRE_RUN);
    wire pre_get_addr = !(pre_state_d ^ PRE_GET_ADDR);
    wire pre_miss   = !(pre_state_d ^ PRE_MISS);
    // wire pre_miss_next_line = !(pre_state_d ^ PRE_MISS_NEXT_LINE);
    wire pre_wait_for_axi = !(pre_state_d ^ PRE_WAIT_FOR_AXI);
    wire pre_finish = !(pre_state_d ^ PRE_FINISH);
    wire pre_refill = !(pre_state_d ^ PRE_REFILL);
    wire pre_write_back   = !(pre_state_d ^ PRE_WRITE_BACK);

    wire pre_fetching_d;//Whether prefetcher is fetching the target line
    reg  pre_fetching;
    //--------------Inst Cache------------
    reg ok_ready;
    //---------------Reset----------------
    reg  [6:0] rstn_cnt;
    wire [6:0] rstn_cnt_d;
    assign rstn_cnt_d = rstn_cnt;

    always @(posedge clk) begin
        if (!rstn) begin
            rstn_cnt <= 7'b0;
        end
        else if (resetn) begin
            rstn_cnt <= rstn_cnt_d + 7'b1;
        end
        else begin
        end
    end
    //----------------TagV----------------------
     wire [`INST_CACHE_ASSO-1:0]        tagv_wen;
     wire [`INST_CACHE_INDEX_WIDTH-1:0] tagv_index_in;
     wire [`INST_CACHE_TAG_WIDTH-1:0]   tag_wdata;
     wire [`INST_CACHE_ASSO-1:0]        hit_array;
     wire                               hit;
    assign hit = !(!hit_array) & (run);
     wire                               valid_wdata;
    //----------------Data---------------------
     wire [`INST_CACHE_BANK_WIDTH-1:0]                        data_wen[`INST_CACHE_ASSO-1:0];
     wire [`INST_CACHE_INDEX_WIDTH-1:0]                       data_index_in;
     wire [`INST_CACHE_BANK_WIDTH-1:0]                        data_rdata[`INST_CACHE_ASSO-1:0];
    wire [`INST_CACHE_BANK_WIDTH * `INST_CACHE_BANK_NUM-1:0] data_wdata;
    wire [`INST_CACHE_OFFSET_WIDTH-1:0] data_offset;
    wire [2:0]                                               bank_sel;
    assign bank_sel = {(hit_array[3] | hit_array[2]),(hit_array[3] | hit_array[1])};
    //-------------LRU------------------------
     reg [`INST_CACHE_ASSO-1:0]      way_sel;
    reg [`INST_CACHE_LRU_WIDTH-1:0] lru[`INST_CACHE_GROUP_NUM-1:0];
    //---------------Continous---------------------------
     wire cont_mem;//Is continous memory access,1 -> cont,0 -> not cont
    //-----------Write Buffer---------------
    reg [31:0] write_buffer[7:0];
    reg [7:0]  write_buffer_valid;

    reg    [`INST_CACHE_BANK_SIZE-1:0]  refill_cnt;
    wire   [`INST_CACHE_BANK_SIZE-1:0]  refill_cnt_d;
    assign refill_cnt_d = refill_cnt;

     reg         hit_when_refill;
    wire        hit_when_refill_d;
    reg  [31:0] hit_when_refill_word;
    wire [`INST_CACHE_OFFSET_WIDTH-1:0] refill_offset;
    wire [31:0]                         refill_wen;
    assign      refill_offset = refill_cnt_d << 2; 
    assign      refill_wen    = 32'hf000_0000 >> refill_offset;
    //------------Prefetcher---------------------
    reg [`INS_LEN-1:0]                 pre_last_addr;
    reg [`INST_CACHE_TAG_WIDTH-1:0]    pre_last_tag;
    reg [`INST_CACHE_INDEX_WIDTH-1 :0] pre_last_index;

    reg [`INS_LEN-1:0]                 pre_waddr;
    reg [`INST_CACHE_TAG_WIDTH-1:0]    pre_wtag;
    reg [`INST_CACHE_INDEX_WIDTH-1 :0] pre_windex;
    wire [`INST_CACHE_ASSO-1:0] pre_found_array;
     wire pre_found;
    assign pre_found = !(!pre_found_array);

    reg [31:0]  pre_write_buffer[7:0];
    reg [7:0]   pre_write_buffer_valid;
    reg [255:0] pre_write_line;

    reg    [`INST_CACHE_BANK_SIZE-1:0]  pre_refill_cnt;
    wire   [`INST_CACHE_BANK_SIZE-1:0]  pre_refill_cnt_d;
    assign pre_refill_cnt_d = pre_refill_cnt;

     reg         pre_hit;
    wire        pre_hit_d;
    reg  [31:0] pre_hit_word;
    wire [`INST_CACHE_OFFSET_WIDTH-1:0] pre_refill_offset;
    wire [31:0]                         pre_refill_wen;
    assign      pre_refill_offset = pre_refill_cnt_d << 2; 
    assign      pre_refill_wen    = 32'hf000_0000 >> pre_refill_offset;
    //--------------Last Value----------------
     reg                                last_req;
     reg [`INS_LEN-1:0]                 last_addr;
    reg [`INST_CACHE_TAG_WIDTH-1   :0] last_tag;
    reg [`INST_CACHE_INDEX_WIDTH-1 :0] last_index;
    reg [`INST_CACHE_OFFSET_WIDTH-1:0] last_offset;
    reg [`INST_CACHE_ASSO-1:0]         last_way_sel;
    reg                                last_hit;
    reg [`INST_CACHE_ASSO-1:0]         last_hit_array;
    reg                                last_hit_when_refill;

    always @ (posedge clk) begin
        if (!rstn) begin
            last_addr     <= `INS_LEN'b0;
            last_tag      <= `INST_CACHE_TAG_WIDTH'b0;
            last_index    <= `INST_CACHE_INDEX_WIDTH'b0;
            last_offset   <= `INST_CACHE_OFFSET_WIDTH'b0;
            last_way_sel  <= `INST_CACHE_ASSO'b0;
        end
        else if (inst_addr_ok) begin//((run & inst_addr_ok) | hit_when_refill | !cont_mem) begin
            last_addr     <= inst_addr;
            last_tag      <= tag;
            last_index    <= index;
            last_offset   <= offset;
            last_way_sel  <= way_sel;
        end
        else begin
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            last_req <= 1'b0;
        end        
        else if (inst_addr_ok) begin
            last_req <= inst_req;
        end
        else if (inst_data_ok) begin
            last_req <= 1'b0;
        end
    end 
    //--------------Stored Value-------------
    reg                                wreq;
     reg [`INS_LEN-1:0]                 waddr;
    reg [`INST_CACHE_TAG_WIDTH-1   :0] wtag;
    reg [`INST_CACHE_INDEX_WIDTH-1 :0] windex;
    reg [`INST_CACHE_OFFSET_WIDTH-1:0] woffset;
    reg [`INST_CACHE_ASSO-1:0]         wway_sel;
    reg                                whit;
    reg [`INST_CACHE_ASSO-1:0]         whit_array;

    always @ (posedge clk) begin
        if (!rstn) begin
            waddr      <= `INS_LEN'b0;
            wtag       <= `INST_CACHE_TAG_WIDTH'b0;
            windex     <= `INST_CACHE_INDEX_WIDTH'b0;
            woffset    <= `INST_CACHE_OFFSET_WIDTH'b0;
            wway_sel   <= `INST_CACHE_ASSO'b0;
            whit       <= 0;
            whit_array <= `INST_CACHE_ASSO'b0;
        end
        else if (miss) begin
            waddr      <= last_addr;
            wtag       <= last_tag;
            windex     <= last_index;
            woffset    <= last_offset;
            wway_sel   <= last_way_sel;
            whit       <= last_hit;
            whit_array <= last_hit_array;
        end
        else begin
        end
    end
    //------------------Continous----------------
    assign cont_mem = (!ok_ready | hit | hit_when_refill | pre_hit);
    //------------------Axi--------------------
    wire data_back      = !(rid ^ 4'd3);
    wire data_ready     = !(arid ^ 4'd3);
    wire pre_data_back  = !(rid ^ 4'd2);
    wire pre_data_ready = !(arid ^ 4'd2);

    reg [31:0] rdata_r;
    reg        rvalid_r;
    reg        rlast_r;

    reg [31:0] pre_rdata_r;
    reg        pre_rvalid_r;
    reg        pre_rlast_r;

    always @(posedge clk) begin
        if (!rstn) begin
            rdata_r  <= 32'b0;
            rvalid_r <= 1'b0;
            rlast_r  <= 1'b0;
        end        
        else if (data_back) begin
            rdata_r  <= rdata;
            rvalid_r <= rvalid;
            rlast_r  <= rlast;
        end
        else begin
            rdata_r  <= 32'b0;
            rvalid_r <= 1'b0;
            rlast_r  <= 1'b0;
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            pre_rdata_r  <= 32'b0;
            pre_rvalid_r <= 1'b0;
            pre_rlast_r  <= 1'b0;
        end        
        else if (pre_data_back) begin
            pre_rdata_r  <= rdata;
            pre_rvalid_r <= rvalid;
            pre_rlast_r  <= rlast;
        end
        else begin
            pre_rdata_r  <= 32'b0;
            pre_rvalid_r <= 1'b0;
            pre_rlast_r  <= 1'b0;
        end
    end
    //--------------LRU Way_Sel---------------
    always @(posedge clk) begin
        if (!rstn) begin        
            way_sel <= `INST_CACHE_ASSO'b0;
        end
        else if (hit) begin
            way_sel <= hit_array;
        end
        else if (run) begin
            case (lru[index]) // P-LRU
                3'b000,3'b001: way_sel <= `INST_CACHE_ASSO'b0001; // B2,B1 = 00
                3'b010,3'b011: way_sel <= `INST_CACHE_ASSO'b0010; // B2,B1 = 01
                3'b110,3'b100: way_sel <= `INST_CACHE_ASSO'b0100; // B2,B0 = 10
                3'b101,3'b111: way_sel <= `INST_CACHE_ASSO'b1000; // B2,B0 = 11
                default:       way_sel <= `INST_CACHE_ASSO'b0000;
            endcase
        end
        else begin
        end
    end

    reg [6:0] last_last_index;
    always @(posedge clk) begin
        if (!rstn) begin
            last_last_index <= 7'b0;
        end
        else begin
            last_last_index <= last_index;        
        end
    end

    always @(posedge clk) begin
        if (resetn) begin
            lru[rstn_cnt_d] <= `INST_CACHE_LRU_WIDTH'b0;
        end        
        else if (run | miss | wait_for_pre_refill) begin
            case(way_sel) //P-LRU
                `INST_CACHE_ASSO'b0001: begin//Select line 0
                    {lru[last_last_index][`B2],lru[last_last_index][`B1]} <= 2'b11;
                end
                `INST_CACHE_ASSO'b0010: begin//Select line 1
                    {lru[last_last_index][`B2],lru[last_last_index][`B1]} <= 2'b10;
                end
                `INST_CACHE_ASSO'b0100: begin//Select line 2
                    {lru[last_last_index][`B2],lru[last_last_index][`B0]} <= 2'b01;
                end
                `INST_CACHE_ASSO'b1000: begin//Select line 3
                    {lru[last_last_index][`B2],lru[last_last_index][`B0]} <= 2'b00;
                end
                default:;
            endcase
        end
        else begin
        end
    end
    //---------------Write Buffer---------------------
    assign hit_when_refill_d = (cont_mem)?  (write_buffer_valid[offset[4:2]]      & !(tag ^ wtag)      & !(index ^ windex)):
                                            (write_buffer_valid[last_offset[4:2]] & !(last_tag ^ wtag) & !(last_index ^ windex));
    always @(posedge clk) begin
        if (!rstn) begin
            hit_when_refill <= 1'b0;
        end
        else begin
            hit_when_refill <= hit_when_refill_d;
            // hit_when_refill <= 1'b0;
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            hit_when_refill_word <= 32'b0;
        end        
        else if (cont_mem) begin
            hit_when_refill_word <= write_buffer[offset[4:2]];
        end
        else begin
            hit_when_refill_word <= write_buffer[last_offset[4:2]];
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            refill_cnt <= `INST_CACHE_BANK_SIZE'b0;
        end         
        else if (miss) begin
            refill_cnt <= last_offset[4:2];
        end
        else if (rvalid_r) begin
            refill_cnt <= refill_cnt_d + `INST_CACHE_BANK_SIZE'b1;
        end
        else begin
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            write_buffer_valid <= 8'b0;
        end        
        else if (rvalid_r) begin
            write_buffer_valid[refill_cnt_d] <= 1'b1;
        end
        else if (write_back) begin
            write_buffer_valid <= 8'b0;
        end
        else begin
        end
    end

    always @(posedge clk) begin
        if (rvalid_r) begin
            write_buffer[refill_cnt_d] <= rdata_r;
        end 
        else begin
        end
    end
    //----------------Prefetcher------------------
    reg pre_valid;
    reg last_inst_addr_ok;
    always @(posedge clk) begin
        last_inst_addr_ok <= inst_addr_ok;        
    end
    wire [`INS_LEN-1:0] next_addr = (last_addr + `INS_LEN'h20);
    always @(posedge clk) begin
        if (!rstn) begin    
            pre_last_addr  <= `INS_LEN'b0;
            pre_last_tag   <= `INST_CACHE_TAG_WIDTH'b0;
            pre_last_index <= `INST_CACHE_INDEX_WIDTH'b0;
        end
        else if (last_inst_addr_ok) begin //FIXME: time !!!Q
            pre_last_addr  <= next_addr;
            pre_last_tag   <= next_addr[`INST_CACHE_TAG];
            pre_last_index <= next_addr[`INST_CACHE_INDEX];
        end
        else begin
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin    
            pre_waddr  <= `INS_LEN'b0;
            pre_wtag   <= `INST_CACHE_TAG_WIDTH'b0;
            pre_windex <= `INST_CACHE_INDEX_WIDTH'b0;
        end
        else if (pre_get_addr) begin
            pre_waddr  <= pre_last_addr;
            pre_wtag   <= pre_last_tag;
            pre_windex <= pre_last_index;
        end
        else begin
        end
    end

    assign pre_hit_d = ((cont_mem)? (pre_write_buffer_valid[offset[4:2]] & !(tag ^ pre_wtag) & !(index ^ pre_windex)):
                                            (pre_write_buffer_valid[last_offset[4:2]] & !(last_tag ^ pre_wtag) & !(last_index ^ pre_windex))) & !(pre_get_addr | pre_miss);
    always @(posedge clk) begin
        if (!rstn) begin
            pre_hit <= 1'b0;
        end
        else begin
            // pre_hit <= 1'b0;
            pre_hit <= pre_hit_d;
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            pre_hit_word <= 32'b0;
        end        
        else if (cont_mem) begin
            pre_hit_word <= pre_write_buffer[offset[4:2]];
        end
        else begin
            pre_hit_word <= pre_write_buffer[last_offset[4:2]];
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            pre_refill_cnt <= `INST_CACHE_BANK_SIZE'b0;
        end         
        else if (pre_miss) begin
            pre_refill_cnt <= pre_waddr[4:2];
        end
        else if (pre_rvalid_r) begin
            pre_refill_cnt <= pre_refill_cnt_d + `INST_CACHE_BANK_SIZE'b1;
        end
        else begin
        end
    end

    parameter CACHE_INST = 4'b1100;
    wire cache_inst = !(state_d ^ CACHE_INST);
    always @(posedge clk) begin
        if (!rstn) begin
            pre_write_buffer_valid <= 8'b0;
        end        
        else if (pre_get_addr) begin //could pre_hit whenever it is ready
            pre_write_buffer_valid <= 8'b0;
        end
        else if (cache_inst) begin
            pre_write_buffer_valid <= 8'b0;
        end
        else if (pre_rvalid_r) begin
            pre_write_buffer_valid[pre_refill_cnt_d] <= 1'b1;
        end
        else begin
        end
    end

    always @(posedge clk) begin
        if (pre_rvalid_r) begin
            pre_write_buffer[pre_refill_cnt_d] <= pre_rdata_r;
        end 
        else begin
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            pre_write_line <= 256'b0;
        end        
        else if (pre_miss) begin
            pre_write_line <= 256'b0;
        end
        else if (pre_rvalid_r) begin
            case (pre_refill_cnt_d)
                3'd7: pre_write_line[31:0]    <= pre_rdata_r;
                3'd6: pre_write_line[63:32]   <= pre_rdata_r;
                3'd5: pre_write_line[95:64]   <= pre_rdata_r;
                3'd4: pre_write_line[127:96]  <= pre_rdata_r;
                3'd3: pre_write_line[159:128] <= pre_rdata_r;
                3'd2: pre_write_line[191:160] <= pre_rdata_r;
                3'd1: pre_write_line[223:192] <= pre_rdata_r;
                3'd0: pre_write_line[255:224] <= pre_rdata_r;
                default:;
            endcase
        end
        else begin
        end
    end
    //-----------Cache Inst--------------

    parameter CACHE_IDLE            = 3'b000;
    parameter CACHE_INDEX_INVALID   = 3'b001;
    parameter CACHE_INDEX_STORE_TAG = 3'b010;
    parameter CACHE_HIT_INVALID     = 3'b011;
    parameter CACHE_HIT_INVALID_READ_HIT = 3'b100;
    parameter CACHE_HIT_INVALID_HIT = 3'b101;
    parameter CACHE_IDLE_FINISH     = 3'b110;
    parameter CACHE_FINISH          = 3'b111;

     reg  [2:0] cache_state;
    wire [2:0] cache_state_d;
    assign cache_state_d = cache_state;

    wire cache_idle            = !(cache_state_d ^ CACHE_IDLE);
    wire cache_index_invalid   = !(cache_state_d ^ CACHE_INDEX_INVALID);
    wire cache_index_store_tag = !(cache_state_d ^ CACHE_INDEX_STORE_TAG);
    wire cache_hit_invalid     = !(cache_state_d ^ CACHE_HIT_INVALID);
    wire cache_hit_invalid_read_hit = !(cache_state_d ^ CACHE_HIT_INVALID_READ_HIT);
    wire cache_hit_invalid_hit = !(cache_state_d ^ CACHE_HIT_INVALID_HIT);
    wire cache_idle_finish     = !(cache_state_d ^ CACHE_IDLE_FINISH);
    wire cache_finish          = !(cache_state_d ^ CACHE_FINISH);

     wire [3:0] op_wen;
     wire [1:0] op_way;
    wire [3:0] op_way_sel;
    wire [19:0] op_tag;
    wire [6:0] op_index;
    wire [4:0] op_offset;

     wire cache_hit;
    assign cache_hit = !(!hit_array);

     reg [31:0] cache_last_addr;
    reg inst_valid;
    always @(posedge clk) begin
        if (!rstn) begin
            cache_last_addr <= 32'b0;
        end        
        else if (cache_inst & cache_idle) begin
            cache_last_addr <= inst_addr;
        end
        else begin
        end
    end

    assign op_way = cache_last_addr[13:12];
    assign op_tag = cache_last_addr[31:12];
    assign op_index = cache_last_addr[11:5];
    assign op_offset = cache_last_addr[4:0];
    assign op_way_sel = 4'b0001 << op_way;

     wire   is_op_wen;
    assign is_op_wen = (cache_state == CACHE_INDEX_INVALID) || (cache_state == CACHE_INDEX_STORE_TAG);
// assign is_op_wen = (cache_state == CACHE_INDEX_INVALID) || (cache_state == CACHE_INDEX_STORE_TAG) || ((cache_state == CACHE_HIT_INVALID_HIT));
    // assign is_op_wen = cache_index_invalid | cache_index_store_tag | cache_hit_invalid_hit;
    assign op_wen = (is_op_wen)?op_way_sel:(cache_hit & (cache_state == CACHE_HIT_INVALID_HIT))?hit_array:4'b0;
    
    reg cache_op_ok_r;
    always @(posedge clk) begin
        if (!rstn) begin
            cache_op_ok_r <= 1'b0;
        end
        else if (cache_finish) begin
            cache_op_ok_r <= 1'b1;
        end
        else begin
            cache_op_ok_r <= 1'b0;
        end
    end

    // assign cache_op_ok = cache_op_ok_r;

    assign cache_op_ok = cache_finish;
    //----------------Inst Cache--------------------
    always @(posedge clk) begin
        if (!rstn) begin
            ok_ready <= 1'b0;
        end        
        else if (inst_addr_ok & !inst_data_ok) begin
            ok_ready <= 1'b1;
        end
        else if (!inst_addr_ok & inst_data_ok) begin
            ok_ready <= 1'b0;
        end
        else begin
        end
    end

    assign inst_addr_ok = inst_req & !cache_req & (run | hit_when_refill | pre_hit) & (ok_ready?inst_data_ok:1'b1);
    assign inst_data_ok = last_req & (hit | hit_when_refill | pre_hit);
    // assign inst_addr_ok = inst_req & !cache_req & (run | hit_when_refill_d | pre_hit_d) & (ok_ready?inst_data_ok:1'b1);
    // assign inst_data_ok = /*last_req & */(hit | hit_when_refill_d | pre_hit_d);
    assign inst_rdata = (hit_when_refill)? hit_when_refill_word:
                                (pre_hit)? pre_hit_word: 
                                        data_rdata[bank_sel];
    //--------------TagV and Data---------------
    assign tagv_wen = (resetn)?`INST_CACHE_ASSO'b1111:
                        (miss | wait_for_pre_refill)?way_sel://FIXME:
                        `INST_CACHE_ASSO'b0;
                        //TODO: Add cache instruction
    assign data_wen[0] = (way_sel[0])?
                            (rvalid_r)?refill_wen:
                            (wait_for_pre_refill)?32'hffff_ffff:32'b0:32'b0;                   
    assign data_wen[1] = (way_sel[1])?
                            (rvalid_r)?refill_wen:
                            (wait_for_pre_refill)?32'hffff_ffff:32'b0:32'b0;
    assign data_wen[2] = (way_sel[2])?
                            (rvalid_r)?refill_wen:
                            (wait_for_pre_refill)?32'hffff_ffff:32'b0:32'b0;
    assign data_wen[3] = (way_sel[3])?
                            (rvalid_r)?refill_wen:
                            (wait_for_pre_refill)?32'hffff_ffff:32'b0:32'b0;

    assign tag_wdata     = (wait_for_pre_refill)?pre_wtag:(cont_mem)?tag:last_tag;
    assign data_wdata    = (wait_for_pre_refill)?pre_write_line:{8{rdata_r}};
    assign data_offset   = (cont_mem)?offset:last_offset;
    assign valid_wdata   = (resetn)?1'b0:(cache_inst)?1'b0:1'b1;
    assign tagv_index_in = (resetn)?rstn_cnt_d:
                            (wait_for_pre_refill)?pre_windex:
                            (miss)?last_index:
                            (cache_inst)?op_index:
                            (cont_mem)?index:
                                        last_index;
    assign data_index_in = (rvalid_r)?windex:
                            (wait_for_pre_refill)?pre_windex:
                            (cont_mem)?index:
                                        last_index;
    //-------------------AXI-----------------------
    //axi
    assign arid    = (miss)?4'd3:(pre_miss)?4'd2:4'd0;
    assign araddr  = (miss)?last_addr:pre_waddr;//Request Word First
    assign arlen   = 8'd7;
    assign arsize  = 3'd2;
    assign arburst = 2'b10;//Wrap Mode
    assign arlock  = 2'b0;
    assign arcache = 4'b0;
    assign arprot  = 3'b0;
    assign arvalid = miss | pre_miss;
    assign rready  = wait_for_axi | refill | pre_wait_for_axi | pre_refill;
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
    //-------------------FSM----------------------
    assign pre_fetching_d = (cont_mem)?!(pre_waddr[31:5] ^ inst_addr[31:5]):!(pre_waddr[31:5] ^ last_addr[31:5]);
    always @(posedge clk) begin
        if (!rstn) begin
            pre_fetching <= 1'b0;
        end        
        else begin
            pre_fetching <= 1'b0;
            // pre_fetching <= pre_fetching_d;
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            state <= RESETN;
        end
        else begin
            case (state_d) //TODO: add pre support
                IDLE:    state <= RUN;
                RUN:     state <=   
                            (cache_req && (cache_op[2:0] != 3'b0))?CACHE_INST:
                                    (!hit & last_req)?//FIXME: add !pre_hit
                                        (
                                            (pre_fetching)?
                                                (pre_run | pre_finish | pre_write_back)?
                                                            WAIT_FOR_PRE_REFILL:
                                                            WAIT_FOR_PRE_AXI:
                                            (pre_miss)?RUN:MISS
                                        ): 
                                        RUN;
                                        // * !pre_hit ? MISS : RUN;
                MISS:    state <= (arready & data_ready)? WAIT_FOR_AXI:MISS;
                WAIT_FOR_AXI: state <= (rvalid & data_back)?REFILL:WAIT_FOR_AXI;
                WAIT_FOR_PRE_AXI: state <= (pre_finish | pre_write_back | pre_run)?WAIT_FOR_PRE_REFILL:WAIT_FOR_PRE_AXI;
                REFILL:  state <= (rlast & rvalid & data_back)?FINISH:REFILL;
                WAIT_FOR_PRE_REFILL: state <= WRITE_BACK;
                FINISH:  state <= WRITE_BACK;
                WRITE_BACK: state <= RUN;
                CACHE_INST : state <= (cache_finish)?IDLE:CACHE_INST;
                RESETN:  state <= (!(rstn_cnt_d ^ (`INST_CACHE_GROUP_NUM-1)))?IDLE:RESETN;
                //TODO: Add instruction support
                default: state <= IDLE;
            endcase 
        end
    end
    //-----------------Pre FSM--------------------  
    always @(posedge clk) begin
        if (!rstn) begin
            pre_state <= PRE_RESETN;
        end        
        else begin
            case (pre_state_d)
                PRE_IDLE:   pre_state <= PRE_IDLE;
                PRE_RUN :   pre_state <= (last_req)?
                                            (
                                                ((refill | finish) & !hit_when_refill & cont_mem)?PRE_GET_ADDR:
                                                (!pre_found & !pre_hit)?PRE_GET_ADDR:PRE_RUN
                                            ):PRE_RUN;
                PRE_GET_ADDR : pre_state <= PRE_MISS;
                PRE_MISS:   pre_state    <= (arready & pre_data_ready)?PRE_WAIT_FOR_AXI:PRE_MISS;
                // PRE_MISS_NEXT_LINE: pre_state <= (arready & pre_data_ready)?PRE_WAIT_FOR_AXI:PRE_MISS_NEXT_LINE;
                PRE_WAIT_FOR_AXI: pre_state   <= (rvalid & pre_data_back)?PRE_REFILL:PRE_WAIT_FOR_AXI;
                PRE_REFILL: pre_state <= (rlast & rvalid & pre_data_back)?PRE_FINISH:PRE_REFILL;
                PRE_FINISH: pre_state <= PRE_WRITE_BACK;
                PRE_WRITE_BACK: pre_state <= PRE_RUN; //TODO: reduce
                PRE_RESETN: pre_state <= (!(rstn_cnt_d ^ (`INST_CACHE_GROUP_NUM-1)))?PRE_IDLE:PRE_RESETN;
                default: pre_state    <= IDLE;
            endcase
        end
    end
    //---------------Cache State------------------
    always @(posedge clk) begin
        if (!rstn) begin
            cache_state <= CACHE_IDLE;
        end
        else begin//FIXME: cache_hit
            case (cache_state_d)
                CACHE_IDLE: cache_state <= 
                                (cache_inst)?
                                (
                                    (cache_op[0])?CACHE_INDEX_INVALID:
                                    (cache_op[1])?CACHE_INDEX_STORE_TAG:
                                    (cache_op[2])?CACHE_HIT_INVALID:
                                    CACHE_FINISH
                                    // CACHE_IDLE_FINISH
                                ):CACHE_IDLE;     
                CACHE_INDEX_INVALID: cache_state <= CACHE_FINISH;
                CACHE_INDEX_STORE_TAG: cache_state <= CACHE_FINISH; 
                CACHE_HIT_INVALID: cache_state <= CACHE_HIT_INVALID_READ_HIT;//FIXME: could not remove
                CACHE_HIT_INVALID_READ_HIT: cache_state <= (cache_hit)?CACHE_HIT_INVALID_HIT:CACHE_FINISH;
                CACHE_HIT_INVALID_HIT: cache_state <= CACHE_FINISH;
                CACHE_FINISH: cache_state <= CACHE_IDLE;
                default:;
            endcase
        end
    end
    //----------------Sub Module------------------
    generate 
        genvar k;
        for (k = 0; k < `INST_CACHE_ASSO; k = k + 1) begin
            inst_cache_tagv Inst_Cache_TagV (
                .hit(hit_array[k]),
                .pre_found(pre_found_array[k]),
                .clk(clk),
                .en(1'b1),
                .op_wen(op_wen[k]),
                .wen(tagv_wen[k]),
                .tag_wdata(tag_wdata),
                .index(tagv_index_in),
                .valid_wdata(valid_wdata)
            );

            inst_cache_data Inst_Cache_Data (
                .data_rdata(data_rdata[k]),

                .clk(clk),
                .en(1'b1),
                .wen(data_wen[k]),
                .index(data_index_in),
                .offset(data_offset),
                .data_wdata(data_wdata)
            );
        end
    endgenerate

endmodule

