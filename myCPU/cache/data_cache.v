`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/27/2020 07:39:31 PM
// Design Name: 
// Module Name: data_cache
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
`include "../Head_Files/Parameter.vh"
`include "../Head_Files/Cache.vh"
`include "../Head_Files/Interface.vh"


module data_cache(
    input         clk,
    input         rstn,
    // input         en,
	input  cache_req,
	input  [6:0] cache_op,
	input  [31:0]cache_tag,
	output  cache_op_ok,
    //------DATA Sram-Like-------
    //From CPU
    input data_req,
    input data_wr,
    input [`SRAM_SIZE_WIDTH-1:0] data_size,
    input [`SRAM_ADDR_WIDTH-1 :0] data_addr,
    input [`SRAM_WDATA_WIDTH-1 :0] data_wdata,
    input [3:0] data_wstrb,//FIXME:TODO:
    output [`SRAM_WDATA_WIDTH-1:0] data_rdata,
    output data_addr_ok,
    output data_data_ok,
    // output hit_when_refill_o,
    // output  [31:0] hit_when_refill_word_o,
    //AXI
    //ar
    output  [3 :0] arid,
    output  [31:0] araddr,
    output  [7 :0] arlen,
    output  [2 :0] arsize,
    output  [1 :0] arburst,
    output  [1 :0] arlock,
    output  [3 :0] arcache,
    output  [2 :0] arprot,
    output         arvalid,
    input          arready,
    //r
    input [3 :0] rid,
    input [31:0] rdata,
    input [1 :0] rresp,
    input        rlast,
    input        rvalid,
    output       rready,
    //aw
    output  [3 :0] awid,
    output  [31:0] awaddr,
    output  [7 :0] awlen,
    output  [2 :0] awsize,
    output  [1 :0] awburst,
    output  [1 :0] awlock,
    output  [3 :0] awcache,
    output  [2 :0] awprot,
    output         awvalid,
    input          awready,
    //w
    output  [3 :0] wid,
    output  [31:0] wdata,
    output  [3 :0] wstrb,
    output         wlast,
    output         wvalid,
    input          wready,
    //b
    input [3 :0] bid,
    input [1 :0] bresp,
    input        bvalid,
    output       bready
    );
    //TODO:
    /**
    FIXME:
        修改dirty，lru的last_last_index
        修改araddr的边界对�?
        修改write_hit_array，使wns为正，放在data_wen�?
        修改定向，last_wr
        写合�?
        性能测试 5 drystone�?6 quicksort�?9 streamcopy
    */
    //------------------------------------------------
    wire [`DATA_CACHE_TAG_WIDTH-1   :0] tag;
    wire [`DATA_CACHE_INDEX_WIDTH-1 :0] index;
    wire [`DATA_CACHE_OFFSET_WIDTH-1:0] offset;
    assign tag    = data_addr[`DATA_CACHE_TAG];
    assign index  = data_addr[`DATA_CACHE_INDEX];
    assign offset = data_addr[`DATA_CACHE_OFFSET];
    //-------------State--------------------
    parameter IDLE   = 4'b0000;
    parameter RUN    = 4'b0001;
    parameter MISS   = 4'b0010;
    parameter WAIT_FOR_AXI = 4'b0011;
    parameter REFILL = 4'b0100;
    parameter FINISH = 4'b0101;
    parameter WAIT_FLUSH = 4'b0110;
    parameter GET_WRITE_LINE = 4'b0111;
    parameter WRITE_BACK          = 4'b1000;
    parameter WAIT_FOR_PRE_AXI    = 4'b1001; 
    parameter WAIT_FOR_PRE_REFILL = 4'b1010;
    parameter CACHE_INST = 4'b1100;
    parameter WAIT_MISS = 4'b1101;//FIXME:
    // parameter INDEX_INVALID   = 4'b1100;
    // parameter INDEX_STORE_TAG = 4'b1101;
    // parameter HIT_INVALID     = 4'b1110;
    //TODO: add cache DATAruction support
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
    wire wait_flush = !(state_d ^ WAIT_FLUSH);
    wire get_write_line = !(state_d ^ GET_WRITE_LINE);
    wire write_back = !(state_d ^ WRITE_BACK);
    wire resetn = !(state_d ^ RESETN);  
    wire wait_miss = !(state_d ^ WAIT_MISS);

    wire wait_for_pre_axi    = !(state_d ^ WAIT_FOR_PRE_AXI);
    wire wait_for_pre_refill = !(state_d ^ WAIT_FOR_PRE_REFILL);

    wire cache_inst = !(state_d ^ CACHE_INST);
    // wire index_invalid   = !(state_d ^ INDEX_INVALID);
    // wire index_store_tag = !(state_d ^ INDEX_STORE_TAG);
    // wire hit_invalid     = !(state_d ^ HIT_INVALID);
    //------------Pre State----------------------
    parameter PRE_IDLE         = 4'b0000;
    parameter PRE_RUN          = 4'b0001;
    parameter PRE_GET_ADDR     = 4'b0010;
    parameter PRE_MISS         = 4'b0011;
    parameter PRE_WAIT_FOR_AXI = 4'b0100;
    parameter PRE_REFILL       = 4'b0101;
    parameter PRE_FINISH       = 4'b0110;
    parameter PRE_WAIT_FLUSH   = 4'b0111;
    parameter PRE_GET_WRITE_LINE = 4'b1000;
    parameter PRE_WRITE_BACK   = 4'b1001;
    parameter PRE_RESETN       = 4'b1111;

    reg [3 :0]  pre_state;
    wire [3 :0] pre_state_d;
    assign pre_state_d = pre_state;

    wire pre_idle   = !(pre_state_d ^ PRE_IDLE);
    wire pre_run    = !(pre_state_d ^ PRE_RUN);
    wire pre_get_addr = !(pre_state_d ^ PRE_GET_ADDR);
    wire pre_miss   = !(pre_state_d ^ PRE_MISS);
    wire pre_wait_for_axi = !(pre_state_d ^ PRE_WAIT_FOR_AXI);
    wire pre_finish = !(pre_state_d ^ PRE_FINISH);
    wire pre_wait_flush = !(pre_state_d ^ PRE_WAIT_FLUSH);
    wire pre_get_write_line = !(pre_state_d ^ PRE_GET_WRITE_LINE);
    wire pre_refill = !(pre_state_d ^ PRE_REFILL);
    wire pre_write_back   = !(pre_state_d ^ PRE_WRITE_BACK);

    reg  pre_fetching;//Whether prefetcher is fetching the target line
    wire pre_fetching_d;//Whether prefetcher is fetching the target line

    reg  need_pre_fetching;//FIXME: may have bug
    wire need_pre_fetching_d;//FIXME: may have bug
    //------------Cache State--------------------
    parameter CACHE_IDLE = 4'b0000;
    parameter CACHE_INDEX_WRITEBACK_INVALID = 4'b0001;
    parameter CACHE_INDEX_WRITEBACK_INVALID_START = 4'b0010;
    parameter CACHE_INDEX_STORE_TAG = 4'b0011;
    parameter CACHE_HIT_INVALID = 4'b0100;
    parameter CACHE_HIT_INVALID_READ_HIT = 4'b0101;
    parameter CACHE_HIT_INVALID_HIT = 4'b0110;
    parameter CACHE_HIT_WRITEBACK_INVALID = 4'b0111;
    parameter CACHE_HIT_WRITEBACK_INVALID_READ_HIT = 4'b1000;

    parameter CACHE_WAIT = 4'b1001;
    parameter CACHE_START      = 4'b1100;
    parameter CACHE_START_AXI  = 4'b1101;
    parameter CACHE_WRITE_BACK = 4'b1110;
    parameter CACHE_FINISH     = 4'b1111;

    reg [3:0]  cache_state;
    wire [3:0] cache_state_d;
    assign cache_state_d = cache_state;

    wire cache_idle = !(cache_state ^ CACHE_IDLE);
    wire cache_index_writeback_invalid    = !(cache_state ^ CACHE_INDEX_WRITEBACK_INVALID);
    wire cache_index_writeback_invalid_start = !(cache_state ^ CACHE_INDEX_WRITEBACK_INVALID_START);
    wire cache_index_store_tag = !(cache_state ^ CACHE_INDEX_STORE_TAG);
    wire cache_hit_invalid = !(cache_state ^ CACHE_HIT_INVALID);
    wire cache_hit_invalid_read_hit = !(cache_state ^ CACHE_HIT_INVALID_READ_HIT);
    wire cache_hit_invalid_hit = !(cache_state ^ CACHE_HIT_INVALID_HIT);
    wire cache_hit_writeback_invalid = !(cache_state ^ CACHE_HIT_WRITEBACK_INVALID);
    wire cache_hit_writeback_invalid_read_hit = !(cache_state ^ CACHE_HIT_WRITEBACK_INVALID_READ_HIT);
    wire cache_wait = !(cache_state ^ CACHE_WAIT);
    wire cache_start = !(cache_state ^ CACHE_START);
    wire cache_start_axi = !(cache_state ^ CACHE_START_AXI);
    wire cache_write_back = !(cache_state ^ CACHE_WRITE_BACK);
    wire cache_finish = !(cache_state ^ CACHE_FINISH);
    //------------Cache Instruction--------------------
    wire [1:0]  op_wen;
    wire        op_way;
    wire [1:0]  op_way_sel;
    wire [19:0] op_tag;
    wire [6:0]  op_index;
    wire [4:0]  op_offset;
    //decode
    wire data_index_writeback_invalid   = !(cache_op ^ 5'b00001);
    wire data_index_store_tag = !(cache_op ^ 5'b01001);
    wire data_hit_invalid     = !(cache_op ^ 5'b10001);
    wire data_hit_writeback_invalid = !(cache_op ^ 5'b10101);
    //----------------Data Cache-----------------------
    reg ok_ready;
    //---------------Reset----------------
    reg  [`DATA_CACHE_INDEX_WIDTH-1:0] rstn_cnt;
    wire [`DATA_CACHE_INDEX_WIDTH-1:0] rstn_cnt_d;
    assign rstn_cnt_d = rstn_cnt;

    always @(posedge clk) begin
        if (!rstn) begin
            rstn_cnt <= `DATA_CACHE_INDEX_WIDTH'b0;
        end
        else if (resetn) begin
            rstn_cnt <= rstn_cnt_d + `DATA_CACHE_INDEX_WIDTH'b1;
        end
        else begin
        end
    end
    //----------------TagV----------------------
    wire [`DATA_CACHE_ASSO-1:0]        tagv_wen;
    wire [`DATA_CACHE_INDEX_WIDTH-1:0] tagv_index_in;
    wire [`DATA_CACHE_TAG_WIDTH-1:0]   tag_wdata;
    wire [`DATA_CACHE_ASSO-1:0]        hit_array;
    wire [`DATA_CACHE_ASSO-1:0]        valid_array;
    wire [`DATA_CACHE_TAG_WIDTH-1:0]   tag_rdata[`DATA_CACHE_ASSO-1:0];
    wire                               valid_wdata;
    wire hit = !(!hit_array) & (run);
    wire cache_hit;
    assign cache_hit = !(!hit_array);
    wire write_hit;
    reg last_wr;
    assign write_hit = hit & last_wr & ok_ready; 
    wire [1:0] write_hit_array = (ok_ready & last_wr)?hit_array:`DATA_CACHE_ASSO'b0;//FIXME:

    //----------------Data---------------------
    wire [31:0]   data_wen[`DATA_CACHE_ASSO-1:0];
    wire [`DATA_CACHE_INDEX_WIDTH-1:0] data_index_in_a;
    wire [`DATA_CACHE_INDEX_WIDTH-1:0] data_index_in_b;
    wire [255:0] bank_rdata[`DATA_CACHE_ASSO-1:0];
    wire [255:0] bank_wdata;
    wire [`DATA_CACHE_BANK_WIDTH-1:0] data_rdata_buf_0[`DATA_CACHE_BANK_NUM-1:0];
    wire [`DATA_CACHE_BANK_WIDTH-1:0] data_rdata_buf_1[`DATA_CACHE_BANK_NUM-1:0];
    wire [`DATA_CACHE_BANK_WIDTH-1:0] data_data[`DATA_CACHE_ASSO-1:0];

    assign {data_rdata_buf_0[0],data_rdata_buf_0[1],data_rdata_buf_0[2],data_rdata_buf_0[3],
                    data_rdata_buf_0[4],data_rdata_buf_0[5],data_rdata_buf_0[6],data_rdata_buf_0[7]} = bank_rdata[0];
    assign {data_rdata_buf_1[0],data_rdata_buf_1[1],data_rdata_buf_1[2],data_rdata_buf_1[3],
                    data_rdata_buf_1[4],data_rdata_buf_1[5],data_rdata_buf_1[6],data_rdata_buf_1[7]} = bank_rdata[1];
    reg [`DATA_CACHE_OFFSET_WIDTH-1:0] last_offset;
    assign data_data[0] = data_rdata_buf_0[last_offset[4:2]];
    assign data_data[1] = data_rdata_buf_1[last_offset[4:2]];

    //-------------LRU------------------------
    reg [`DATA_CACHE_ASSO-1:0]      way_sel;
    reg [`DATA_CACHE_GROUP_NUM-1:0] lru;
    //---------------Continous---------------------------
    wire cont_mem;//Is continous memory access,1 -> cont,0 -> not cont
    //----------Dirty And Victim Cache------------------------
    reg [255:0] replace_line;
    wire        pick_and_replace;
    reg [`DATA_CACHE_GROUP_NUM-1:0] dirty[`DATA_CACHE_ASSO-1:0];
    reg [1:0]   valid_dirty_r;
    wire        write_merge;
    wire        could_read;
    wire        found;
    reg [31:0]  found_word;
    reg [31:0]  victim_last_addr;
    reg [`DATA_CACHE_TAG_WIDTH-1:0]    victim_last_tag;
    reg [`DATA_CACHE_INDEX_WIDTH-1:0]  victim_last_index;
    reg         victim_last_valid;

    reg [31:0] victim_waddr[1:0];
    reg [`DATA_CACHE_TAG_WIDTH-1:0]   victim_wtag[1:0];
    reg [`DATA_CACHE_INDEX_WIDTH-1:0] victim_windex[1:0];
    reg        victim_wvalid;

   wire       spare;
    wire       empty;
   wire       spare_line;
    reg [1:0]  victim_valid;
    reg [31:0] victim_cache_0[7:0];
    reg [31:0] victim_cache_1[7:0];
    reg [2:0]  victim_cnt;
    wire [2:0] victim_cnt_d;
    reg        writing_line;
   reg [31:0] write_back_addr;
    reg [31:0] write_back_word;

    assign victim_cnt_d = victim_cnt;

    parameter VICTIM_IDLE       = 3'b000;
    parameter VICTIM_START_AXI  = 3'b001;
    parameter VICTIM_WRITE_BACK = 3'b010;
    parameter VICTIM_FINISH     = 3'b011;
    reg  [2:0] victim_state;
    wire [2:0] victim_state_d;
    assign victim_state_d = victim_state;

    wire victim_idle       = !(victim_state ^ VICTIM_IDLE);
    wire victim_start_axi  = !(victim_state ^ VICTIM_START_AXI);
    wire victim_write_back = !(victim_state ^ VICTIM_WRITE_BACK);
    wire victim_finish     = !(victim_state ^ VICTIM_FINISH);
    //-----------Write Buffer---------------
    reg [31:0]  write_buffer[`DATA_CACHE_BANK_NUM-1:0];
    reg [`DATA_CACHE_BANK_NUM-1:0]  write_buffer_valid;
    reg [255:0] write_line;

    reg    [`DATA_CACHE_BANK_SIZE-1:0]  refill_cnt;
    wire   [`DATA_CACHE_BANK_SIZE-1:0]  refill_cnt_d;
    assign refill_cnt_d = refill_cnt;

    reg         hit_when_refill;
    reg         read_hit_when_refill;
    wire        write_hit_when_refill;     
    wire        hit_when_refill_d;
    wire        read_hit_when_refill_d;
    wire        write_hit_when_refill_d;

    reg  [31:0] hit_when_refill_word;
    reg         write_data_ok_return;
    //--------------Prefetcher---------------
    reg [31:0]                 pre_last_addr;
    reg [`DATA_CACHE_TAG_WIDTH-1:0]    pre_last_tag;
    reg [`DATA_CACHE_INDEX_WIDTH-1 :0] pre_last_index;
    reg [`DATA_CACHE_ASSO-1 :0]        pre_last_way_sel;

    reg [31:0]                         pre_waddr;
    reg [`DATA_CACHE_TAG_WIDTH-1:0]    pre_wtag;
    reg [`DATA_CACHE_INDEX_WIDTH-1 :0] pre_windex;
    reg [`DATA_CACHE_ASSO-1 :0]        pre_wway_sel;

    reg [31:0]  pre_write_buffer[`DATA_CACHE_BANK_NUM-1:0];
    reg [`DATA_CACHE_BANK_NUM-1:0]  pre_write_buffer_valid;
    reg [255:0] pre_write_line;

    reg    [`DATA_CACHE_BANK_SIZE-1:0]  pre_refill_cnt;
    wire   [`DATA_CACHE_BANK_SIZE-1:0]  pre_refill_cnt_d;
    assign pre_refill_cnt_d = pre_refill_cnt;

    reg         pre_hit;
    wire        pre_read_hit;
    wire        pre_write_hit;     
    wire        pre_hit_d;

    reg  [31:0] pre_hit_word;
    reg         pre_write_data_ok_return;
    //--------------Last Value----------------
    reg                                last_req;
    reg [3:0]                          last_wstrb;
    reg [31:0]                         last_addr;
    reg [31:0]                         last_wdata;
    reg [`DATA_CACHE_TAG_WIDTH-1   :0] last_tag;
    reg [`DATA_CACHE_INDEX_WIDTH-1 :0] last_index;

    reg [`DATA_CACHE_ASSO-1:0]         last_way_sel;
    reg                                last_hit;
    reg [`DATA_CACHE_ASSO-1:0]         last_hit_array;
    reg                                last_hit_when_refill;

    reg [19:0]                         write_hit_tag; 
    reg [3:0]                          write_hit_wstrb;
    reg [31:0]                         write_hit_wdata;
    reg [`DATA_CACHE_INDEX_WIDTH-1 :0] write_hit_index;
    reg [`DATA_CACHE_OFFSET_WIDTH-1 :0] write_hit_offset;
 
    always @(posedge clk) begin
        if (!rstn) begin
            write_hit_tag    <= 20'b0;
            write_hit_wstrb  <= 4'b0;
            write_hit_index  <= `DATA_CACHE_INDEX_WIDTH'b0;
            write_hit_wdata  <= 32'b0;
            write_hit_offset <= `DATA_CACHE_OFFSET_WIDTH'b0;
        end        
        else if (cont_mem) begin
            write_hit_tag    <= tag;
            write_hit_wstrb  <= data_wstrb;
            write_hit_wdata  <= data_wdata;
            write_hit_index  <= index;
            write_hit_offset <= offset;
        end 
        else begin
            write_hit_tag    <= last_tag;
            write_hit_wstrb  <= last_wstrb;
            write_hit_wdata  <= last_wdata;
            write_hit_index  <= last_index;
            write_hit_offset <= last_offset;
        end
    end

    always @ (posedge clk) begin
        if (!rstn) begin
            last_addr     <= 32'b0;
            last_tag      <= `DATA_CACHE_TAG_WIDTH'b0;
            last_index    <= `DATA_CACHE_INDEX_WIDTH'b0;
            last_offset   <= `DATA_CACHE_OFFSET_WIDTH'b0;
            last_way_sel  <= `DATA_CACHE_ASSO'b0;
            last_wdata    <= 32'b0;
            last_wstrb    <= 4'b0;
            last_wr       <= 1'b0;
        end
        else if (data_addr_ok) begin//((run & data_addr_ok) | hit_when_refill | !cont_mem) begin
            last_addr     <= data_addr;
            last_tag      <= tag;
            last_index    <= index;
            last_offset   <= offset;
            last_way_sel  <= way_sel;
            last_wdata    <= data_wdata;
            last_wstrb    <= data_wstrb;
            last_wr       <= data_wr;
        end
        else begin
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            last_req <= 1'b0;
        end        
        else if (data_addr_ok) begin
            last_req <= data_req;
        end
        else if (data_data_ok) begin
            last_req <= 1'b0;
        end
        else begin
        end
    end 
    assign bank_sel = last_offset[4:2];
     //--------------Stored Value-------------
    reg                                wreq;
    reg [31:0]                         waddr;
    reg [`DATA_CACHE_TAG_WIDTH-1   :0] wtag;
    reg [`DATA_CACHE_INDEX_WIDTH-1 :0] windex;
    reg [31:0]                         wwdata;
    reg [31:0]                         wwstrb;
    reg [`DATA_CACHE_OFFSET_WIDTH-1:0] woffset;
    reg [`DATA_CACHE_ASSO-1:0]         wway_sel;
    reg                                whit;
    reg [`DATA_CACHE_ASSO-1:0]         whit_array;

    always @ (posedge clk) begin
        if (!rstn) begin
            waddr      <= 32'b0;
            wtag       <= `DATA_CACHE_TAG_WIDTH'b0;
            windex     <= `DATA_CACHE_INDEX_WIDTH'b0;
            woffset    <= `DATA_CACHE_OFFSET_WIDTH'b0;
            wway_sel   <= `DATA_CACHE_ASSO'b0;
            whit       <= 0;
            whit_array <= `DATA_CACHE_ASSO'b0;
            wwdata     <= 32'b0;
            wwstrb     <= 32'b0;
            wway_sel   <= `DATA_CACHE_ASSO'b0;
        end
        else if (miss) begin
            waddr      <= last_addr;
            wtag       <= last_tag;
            windex     <= last_index;
            woffset    <= last_offset;
            wway_sel   <= last_way_sel;
            whit       <= last_hit;
            whit_array <= last_hit_array;
            wwdata     <= last_wdata;
            wwstrb     <= last_wstrb;
            wway_sel   <= way_sel;
        end
        else begin
        end
    end
    //------------------Continous----------------
    assign cont_mem = (!ok_ready | hit | hit_when_refill | pre_hit);
    //------------------Redirector--------------
    /*
        design to fix read after write problem
    */
    wire is_writting_d;
    reg  is_writting;
    reg [31:0] redi_word;
    //------------------Axi--------------------
    wire data_back      = !(rid ^ 4'd1);
    wire data_ready     = !(arid ^ 4'd1);
    wire pre_data_back  = !(rid ^ 4'd0);
    wire pre_data_ready = !(arid ^ 4'd0);

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
    //--------------LRU Way_Sel---------------//FIXME: not work
    always @(posedge clk) begin
        if (!rstn) begin        
            way_sel <= `DATA_CACHE_ASSO'b0;
        end
        else if (run) begin//FIXME: add hit
            // case (lru[last_index]) // P-LRU//FIXME:TODO:
            case (lru[index]) // P-LRU
                1'b1: way_sel <= `DATA_CACHE_ASSO'b10;
                1'b0: way_sel <= `DATA_CACHE_ASSO'b01;
                default: way_sel <= 1'b0;
            endcase
        end
        else if (cache_state == CACHE_INDEX_WRITEBACK_INVALID) begin
            way_sel <= op_way_sel;
        end
        else if (cache_state == CACHE_HIT_WRITEBACK_INVALID) begin
            way_sel <= hit_array;
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
            lru[rstn_cnt_d] <= `DATA_CACHE_LRU_WIDTH'b0;
        end      
        else if (hit) begin
            case (hit_array)
                2'b01: lru[last_index] <= 1'b1;
                2'b10: lru[last_index] <= 1'b0;
            endcase
        end
        else if (miss) begin
            case(way_sel) //P-LRU
                2'b01: lru[last_index] <= 1'b1;
                2'b10: lru[last_index] <= 1'b0;
                default:;
            endcase
        end
        else begin
        end
    end
    //------------------Dirty-----------------------//FIXME: serious bug
    assign pick_and_replace = (miss | pre_miss) & valid_dirty_r[way_sel[1]];
    assign spare = victim_valid[0] | victim_valid[1];
    assign empty = victim_valid[0] & victim_valid[1];
    assign spare_line = victim_valid[1];

    always @(posedge clk) begin
        if (!rstn) begin
            dirty[0] <= 128'b0;
            dirty[1] <= 128'b0;
        end
        else if (write_hit) begin
            dirty[hit_array[1]][write_hit_index] <= 1'b1; 
        end 
        else if (write_hit_when_refill) begin
            dirty[way_sel[1]][write_hit_index] <= 1'b1; 
        end 
        else if (wait_for_axi) begin//TODO: FIXME: change state miss to wait for axi
            dirty[wway_sel[1]][windex] <= 1'b0;
        end 
        else if (cache_start_axi) begin
            dirty[way_sel[1]][op_index] <= 1'b0;
        end
        else begin
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            valid_dirty_r <= 2'b0;
        end        
        else begin
            valid_dirty_r[0] <= dirty[0][last_index] & valid_array[0];
            valid_dirty_r[1] <= dirty[1][last_index] & valid_array[1];
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin        
            victim_last_addr  <= 32'b0;
            victim_last_tag   <= `DATA_CACHE_TAG_WIDTH'b0;
            victim_last_index <= `DATA_CACHE_INDEX_WIDTH'b0;
            replace_line      <= 256'b0;
        end
        else if (pick_and_replace) begin
            victim_last_addr  <= {tag_rdata[way_sel[1]],last_index,5'd0};//FIXME: fix bug
            victim_last_tag   <= tag_rdata[way_sel[1]];
            victim_last_index <= last_index;
            replace_line      <= bank_rdata[way_sel[1]];
        end
        else if (cache_start) begin//FIXME: check wns here, merge way_sel and op_way_selFIXME:TODO: condition
            victim_last_addr  <= {tag_rdata[way_sel[1]],op_index,5'd0};
            victim_last_tag   <= tag_rdata[way_sel[1]];
            victim_last_index <= op_index;
            replace_line      <= bank_rdata[way_sel[1]];
        end
        else begin
        end
    end
    
    always @(posedge clk) begin //TODO: check wns of victim_last_valid
        if (!rstn) begin
            victim_last_valid <= 1'b0; 
        end 
        else if (victim_wvalid) begin
            victim_last_valid <= 1'b0;
        end
        else if (pick_and_replace & !victim_last_valid) begin
            victim_last_valid <= 1'b1;
        end
        else if (cache_start) begin// & dirty[way_sel[1]][op_index] & valid_array[way_sel[1]]) begin
            victim_last_valid <= 1'b1;
        end
        else begin
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            victim_wvalid <= 1'b0;            
        end
        else if (victim_wvalid) begin
            victim_wvalid <= 1'b0;
        end
        else if (spare & victim_last_valid) begin
            victim_wvalid <= 1'b1;
        end
        else begin//TODO:
            victim_wvalid <= 1'b0;
        end
    end 

    always @(posedge clk) begin
        if (spare & victim_wvalid) begin
            victim_waddr[spare_line]  <= victim_last_addr;  
            victim_wtag [spare_line]  <= victim_last_tag;
            victim_windex[spare_line] <= victim_last_index;
        end 
        else begin
        end
    end

    always @(posedge clk) begin
        if (spare & victim_wvalid & !spare_line) begin
            {victim_cache_0[0],victim_cache_0[1],victim_cache_0[2],victim_cache_0[3],victim_cache_0[4],victim_cache_0[5],victim_cache_0[6],victim_cache_0[7]} <= replace_line;
        end 
        else begin
        end
    end

    always @(posedge clk) begin
        if (spare & victim_wvalid & spare_line) begin
            {victim_cache_1[0],victim_cache_1[1],victim_cache_1[2],victim_cache_1[3],victim_cache_1[4],victim_cache_1[5],victim_cache_1[6],victim_cache_1[7]} <= replace_line;
        end 
        else begin
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            victim_valid <= 2'b11;
        end
        else if (spare & victim_wvalid) begin
            victim_valid[spare_line] <= 1'b0;
        end
        
        if (victim_finish) begin//FIXME: change victim_finish
            victim_valid[writing_line] <= 1'b1;
        end 
        else begin
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            writing_line <= 1'b1;//line 1 first
        end        
        else if (empty) begin
            writing_line <= 1'b1;
        end
        else if (victim_finish) begin//FIXME: should add a state or use bvalid
            writing_line <= ~writing_line;
        end
        else begin
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            victim_cnt <= 3'b0;
        end        
        else if (victim_start_axi) begin //TODO: could remove 
            victim_cnt <= 3'b0;
        end
        else if (wready) begin
            victim_cnt <= victim_cnt_d + 3'b1;
        end
        else begin
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            write_back_addr <= 32'b0;
        end        
        else begin
            write_back_addr <= victim_waddr[writing_line];
        end
    end

    wire [2:0] next_victim_cnt = victim_cnt_d + 3'b1;

    always @(posedge clk) begin
        if (!rstn) begin
            write_back_word <= 32'b0;
        end        
        else if (victim_start_axi) begin
            write_back_word <= (writing_line)?victim_cache_1[0]:victim_cache_0[1];
        end
        else if (wready) begin
            write_back_word <= (writing_line)?victim_cache_1[next_victim_cnt]:
                                            victim_cache_0[next_victim_cnt];
        end
        else begin
        end
    end
    // TODO: add random memory access

    //--------------------Write Buffer---------------------
    assign hit_when_refill_d = (cont_mem)?  (write_buffer_valid[offset[4:2]] &
                                                             !(tag ^ wtag) & !(index ^ windex)):
                                            (write_buffer_valid[last_offset[4:2]] &
                                                             !(last_tag ^ wtag) & !(last_index ^ windex));

    // assign write_hit_when_refill_d = hit_when_refill_d & ((cont_mem)?data_wr:last_wr);
    assign write_hit_when_refill = hit_when_refill & ok_ready & last_wr;
    assign read_hit_when_refill_d  = hit_when_refill_d & ((cont_mem)?!data_wr:!last_wr);

    always @(posedge clk) begin
        if (!rstn) begin
            hit_when_refill       <= 1'b0;
            read_hit_when_refill  <= 1'b0;
            // write_hit_when_refill <= 1'b0;
        end        
        else begin
            hit_when_refill      <= hit_when_refill_d;
            read_hit_when_refill <= read_hit_when_refill_d;
            // write_hit_when_refill <= write_hit_when_refill_d;
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
            refill_cnt <= `DATA_CACHE_BANK_SIZE'b0;
        end         
        else if (miss) begin
            refill_cnt <= last_offset[4:2];
        end
        else if (rvalid_r) begin
            refill_cnt <= refill_cnt_d + `DATA_CACHE_BANK_SIZE'b1;
        end
        else begin
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            write_buffer_valid <= `DATA_CACHE_BANK_NUM'b0;
        end        
        else if (finish) begin
            write_buffer_valid <= `DATA_CACHE_BANK_NUM'b0;
        end
        else if (rvalid_r) begin
            write_buffer_valid[refill_cnt_d] <= 1'b1;
        end
        else begin
        end
    end

    integer i;
    integer j;
    always @(posedge clk) begin
        //Write hit when refill
        if (write_hit_when_refill) begin//FIXME: may have bug,delete cont_mem,use write_hit_when_refill
            for (i=0,j=0;j<32;i=i+1,j=j+8) begin
                if (write_hit_wstrb[i]) begin
                    write_buffer[write_hit_offset[4:2]][j+:8] <= write_hit_wdata[j+:8];
                end
                else begin
                end
            end
        end
        else begin
        end

        //From Axi
        if (rvalid_r) begin
            write_buffer[refill_cnt_d] <= rdata_r;
        end 
        else begin
        end
    end

    always @(posedge clk) begin
        if (get_write_line) begin
            write_line <= {write_buffer[0],write_buffer[1],write_buffer[2],write_buffer[3],write_buffer[4],write_buffer[5],write_buffer[6],write_buffer[7]};
        end        
        else begin
        end
    end
    //------------PreFectcher---------------------
    reg last_data_addr_ok;
    always @(posedge clk) begin
        last_data_addr_ok <= data_addr_ok;        
    end

    always @(posedge clk) begin
        if (!rstn) begin    
            pre_last_addr  <= 32'b0;
            pre_last_tag   <= `DATA_CACHE_TAG_WIDTH'b0;
            pre_last_index <= `DATA_CACHE_INDEX_WIDTH'b0;
            pre_last_way_sel <= `DATA_CACHE_ASSO'b0;
        end
        else if (last_data_addr_ok) begin //FIXME: time
            pre_last_addr  <= last_addr;
            pre_last_tag   <= last_tag;
            pre_last_index <= last_index;
            pre_last_way_sel <= way_sel;
        end
        else begin
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin    
            pre_waddr  <= 32'b0;
            pre_wtag   <= `DATA_CACHE_TAG_WIDTH'b0;
            pre_windex <= `DATA_CACHE_INDEX_WIDTH'b0;
            pre_wway_sel <= `DATA_CACHE_ASSO'b0;
        end
        else if (pre_get_addr) begin
            pre_waddr  <= pre_last_addr;
            pre_wtag   <= pre_last_tag;
            pre_windex <= pre_last_index;
            pre_wway_sel  <= pre_last_way_sel;
        end
        else begin
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

    assign pre_hit_d = ((cont_mem)? (pre_write_buffer_valid[offset[4:2]] 
                                        & !(tag ^ pre_wtag) & !(index ^ pre_windex)):
                                    (pre_write_buffer_valid[last_offset[4:2]] 
                                        & !(last_tag ^ pre_wtag) & !(last_index ^ pre_windex))) & (pre_refill | pre_finish);

    always @(posedge clk) begin
        if (!rstn) begin
            pre_hit <= pre_hit_d;
        end
        else begin
            pre_hit <= pre_hit_d;
        end
    end


    assign pre_write_hit = pre_hit & ok_ready & last_wr;
    assign pre_read_hit = pre_hit & !last_wr;

    always @(posedge clk) begin
        if (!rstn) begin
            pre_refill_cnt <= `DATA_CACHE_BANK_SIZE'b0;
        end         
        else if (pre_miss) begin
            pre_refill_cnt <= pre_waddr[4:2];
        end
        else if (pre_rvalid_r) begin
            pre_refill_cnt <= pre_refill_cnt_d + `DATA_CACHE_BANK_SIZE'b1;
        end
        else begin
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            pre_write_buffer_valid <= `DATA_CACHE_BANK_NUM'b0;
        end        
        else if (pre_finish) begin
            pre_write_buffer_valid <= `DATA_CACHE_BANK_NUM'b0;
        end
        else if (pre_rvalid_r) begin
            pre_write_buffer_valid[pre_refill_cnt_d] <= 1'b1;
        end
        else begin
        end
    end

    integer i1;
    integer j1;
    always @(posedge clk) begin
        if (pre_write_hit) begin
            for (i1=0,j1=0;j1<32;i1=i1+1,j1=j1+8) begin
                if (write_hit_wstrb[i1]) begin
                    pre_write_buffer[write_hit_offset[4:2]][j1+:8] <= write_hit_wdata[j1+:8];
                end
                else begin
                end
            end
        end
        else begin
        end

        //From Axi
        if (pre_rvalid_r) begin
            pre_write_buffer[pre_refill_cnt_d] <= pre_rdata_r;
        end 
        else begin
        end
    end

    always @(posedge clk) begin
        if (pre_get_write_line) begin
            pre_write_line <= {pre_write_buffer[0],pre_write_buffer[1],pre_write_buffer[2],pre_write_buffer[3],pre_write_buffer[4],pre_write_buffer[5],pre_write_buffer[6],pre_write_buffer[7]};
        end        
        else begin
        end
    end
    //-----------------Redirector------------------
    // assign is_writting_d = (hit | hit_when_refill) & 
    //                         ((cont_mem)?(!(write_hit_tag ^ tag) & !(write_hit_index ^ index) & !(write_hit_offset ^ offset)):
    //                         (!(write_hit_tag) ^ last_tag) & !(write_hit_index ^ last_index) & !(write_hit_offset ^ last_offset));

    assign is_writting_d = (hit | hit_when_refill) && cont_mem && (!(write_hit_tag ^ tag) && !(write_hit_index ^ index) && !(write_hit_offset[4:2] ^ offset[4:2]));//FIXME:TODO: use mask

    always @(posedge clk) begin
        if (!rstn) begin
            is_writting <= 1'b0;
        end        
        else if (ok_ready & last_wr) begin//FIXME:May have bug
            is_writting <= is_writting_d;
        end
        else begin
            is_writting <= 1'b0;
        end
    end

    //FIXME:
    integer i2;
    integer j2;
    always @(posedge clk) begin
        if (!rstn) begin
            redi_word <= 32'b0;
        end
        else begin
            for (i2=0,j2=0;j2<32;i2=i2+1,j2=j2+8) begin
                if (write_hit_wstrb[i2]) begin
                    redi_word[j2+:8] <= write_hit_wdata[j2+:8];
                end
                else if (run) begin
                    redi_word[j2+:8] <= data_data[hit_array[1]][j2+:8];
                end
                else begin
                    redi_word[j2+:8] <= write_buffer[write_hit_offset[4:2]][j2+:8];
                end
            end 
            // redi_word <= write_hit_wdata;
        end
    end

    //----------------Data Cache--------------------
    always @(posedge clk) begin
        if (!rstn) begin
            ok_ready <= 1'b0;
        end        
        else if (data_addr_ok & !data_data_ok) begin
            ok_ready <= 1'b1;
        end
        else if (!data_addr_ok & data_data_ok) begin
            ok_ready <= 1'b0;
        end
        else begin
        end
    end
    // reg pre_hit_when_refill;

    // always @(posedge clk) begin
    //     if (!rstn) pre_hit_when_refill <= 1'b0;      
    //     else pre_hit_when_refill <= hit_when_refill;
    // end

    //TODO: add pre_hit found//FIXME: addr_ok may have bug
    assign data_addr_ok = data_req & !cache_req & (run | hit_when_refill | pre_hit) & (ok_ready?data_data_ok:1'b1);
    assign data_data_ok = last_req & (hit | hit_when_refill | pre_hit);//FIXME: may have bug:use read_hit
    assign data_rdata   =     (is_writting)?redi_word:
                                (hit_when_refill) ? hit_when_refill_word :
                                // (hit_when_refill)? cont_mem ? write_buffer[offset[4:2]] : write_buffer[last_offset[4:2]]: //TODO:FIXME:add redirector
                                //TODO: change 1
                                (pre_hit)? pre_hit_word: 
                                // (last_wr)? {{8{last_wstrb[3]}}, {8{last_wstrb[2]}}, {8{last_wstrb[1]}}, 8{last_wstrb[0]}} & last_wdata
                                        data_data[hit_array[1]];
    // assign hit_when_refill_o = hit_when_refill;
    // assign hit_when_refill_word_o = hit_when_refill_word;
    //--------------TagV and Data---------------
    assign tagv_wen = (resetn)?`DATA_CACHE_ASSO'b11:
                        // (miss)?way_sel://TODO: pre_refill
                        (write_back)?wway_sel: //FIXME:????
                        (pre_write_back)?pre_wway_sel:
                        `DATA_CACHE_ASSO'b0;
    wire [31:0] wen_offset = (write_hit_offset[4:2] << 2); 
    assign data_wen[0] = 
                            (wway_sel[0] & write_back)?32'hffff_ffff:
                            (pre_wway_sel[0] & pre_write_back)?32'hffff_ffff:
                            (write_hit_array[0] & run)?
                            ({write_hit_wstrb,28'b0} >> wen_offset):32'h0;
    assign data_wen[1] = 
                            (wway_sel[1] & write_back)?32'hffff_ffff:
                            (pre_wway_sel[1] & pre_write_back)?32'hffff_ffff:
                            (write_hit_array[1] & run)?
                            ({write_hit_wstrb,28'b0} >> wen_offset):32'h0;
    //TODO: pre_refill
    assign tag_wdata  = 
                        // (miss)?last_tag:
                        (write_back)?wtag:
                        (pre_write_back)?pre_wtag:
                        (cont_mem)?tag:
                        last_tag;
    assign bank_wdata = (write_back)?write_line:
                        (pre_write_back)?pre_write_line:
                                        {8{write_hit_wdata}};
    // assign valid_wdata   = !resetn & !cache_inst;
    assign valid_wdata   = (resetn)?1'b0:(cache_inst)?1'b0:1'b1;
    assign tagv_index_in = (resetn)?rstn_cnt_d:
                            // (wait_for_pre_refill)?pre_windex:
                            // (miss | pre_miss)?last_index:
                            (write_back)?windex:
                            // (miss)?last_index:
                            (pre_write_back)?pre_windex:
                            (cont_mem)?index:
                                        last_index;

    assign data_index_in_a = (write_back)?windex:
                             (pre_write_back)?pre_windex:
                            (wait_for_pre_refill)?pre_windex:
                                write_hit_index;

    assign data_index_in_b = 
                            (cont_mem)?index:
                                        last_index;
    //------------------Cache Instruction----------------
     reg [31:0] cache_last_addr;
    always @(posedge clk) begin
        if (!rstn) begin
            cache_last_addr <= 32'b0;
        end        
        else if (cache_inst & cache_idle) begin
            cache_last_addr <= data_addr;
        end
        else begin
        end
    end

    assign op_way     = cache_last_addr[12];
    assign op_tag     = cache_last_addr[31:12];
    assign op_index   = cache_last_addr[11:5];
    assign op_offset  = cache_last_addr[4:0];
    assign op_way_sel = 2'b01 << op_way;

    wire   is_op_wen;
    assign is_op_wen = (cache_state == CACHE_INDEX_STORE_TAG);
    // assign is_op_wen = cache_start_axi || cache_hit_invalid_hit || cache_index_store_tag;
    assign op_wen = (is_op_wen)?op_way_sel:
                    ((cache_state == CACHE_HIT_INVALID_HIT) && cache_hit)?hit_array:
                    (cache_start_axi)?way_sel:2'b0;

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
    // assign cache_op_ok = 1'b0;
    //-------------------AXI-----------------------
    //axi//TODO: add pre
    assign arid    = (miss)?4'd1:4'd0;
    assign araddr  = (miss)?{last_addr[31:2],2'b0}:pre_waddr;//Request Word First
    assign arlen   = 8'd7;
    assign arsize  = 3'd2;
    assign arburst = 2'b10;//Wrap Mode
    assign arlock  = 2'b0;
    assign arcache = 4'b0;
    assign arprot  = 3'b0;
    assign arvalid = miss | pre_miss;
    assign rready  = wait_for_axi | refill | pre_wait_for_axi | pre_refill ;

    assign awid     = 4'd0;
    assign awlen    = 8'd7;
    assign awburst  = 2'b01;
    assign awsize   = 3'd2;
    assign awlock   = 2'b0;
    assign awcache  = 4'b0;
    assign awprot   = 3'b0;
    assign awaddr   = write_back_addr;//TODO:FIXME: set to 0 when unused
    assign awvalid  = victim_start_axi;

    assign wdata    = write_back_word;
    assign wvalid   = victim_write_back;
    assign wid      = 4'd0;
    assign wlast    = !(victim_cnt_d ^ 3'd7);
    assign wstrb    = 4'b1111;
    
    assign bready   = victim_write_back | victim_finish;
    //--------------------FSM-----------------------
    assign pre_fetching_d = (cont_mem)?!(pre_waddr[31:`DATA_CACHE_OFFSET_WIDTH] ^ data_addr[31:`DATA_CACHE_OFFSET_WIDTH]):!(pre_waddr[31:`DATA_CACHE_OFFSET_WIDTH] ^ last_addr[31:`DATA_CACHE_OFFSET_WIDTH]);

    always @(posedge clk) begin
        if (!rstn) begin
            pre_fetching <= 1'b0;
        end        
        else begin
            pre_fetching <= 0;//pre_fetching_d;
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            state <= RESETN;
        end
        else begin//FIXME:TODO: victim_idle
            case (state_d) 
                IDLE:    state <= RUN;
                RUN:     state <=   (cache_req & (cache_op[6:3] != 4'b0))?CACHE_INST:
                                    (pre_get_write_line| pre_write_back)?WAIT_FOR_PRE_REFILL:
                                    (!hit & last_req)?
                                        (
                                            (pre_fetching)?
                                                (pre_run | pre_finish | pre_get_write_line | pre_write_back)?
                                                            WAIT_FOR_PRE_REFILL:
                                                            WAIT_FOR_PRE_AXI:
                                            (pre_miss)?RUN:
                                            (victim_idle)?MISS:WAIT_MISS
                                            // MISS
                                        ):
                                        RUN;
                WAIT_MISS: state <= (victim_idle)?MISS:WAIT_MISS;
                MISS:    state <= (arready & data_ready)? WAIT_FOR_AXI:MISS;
                // WAIT_FOR_AXI: state <= (rvalid & data_back)?(rlast ? FINISH : REFILL):WAIT_FOR_AXI;
                WAIT_FOR_AXI: state <= (rvalid & data_back)?REFILL:WAIT_FOR_AXI;
                WAIT_FOR_PRE_AXI: state <= (pre_get_write_line | pre_write_back | pre_run)?WAIT_FOR_PRE_REFILL:WAIT_FOR_PRE_AXI;
                REFILL:  state <= (rlast & rvalid & data_back)?FINISH:REFILL;
                WAIT_FOR_PRE_REFILL: state <= (pre_write_back | pre_run)?IDLE:WAIT_FOR_PRE_REFILL;
                FINISH:  state <= WAIT_FLUSH;
                WAIT_FLUSH: state <= GET_WRITE_LINE;
                GET_WRITE_LINE : state <= (pre_get_write_line)?GET_WRITE_LINE:WRITE_BACK;
                WRITE_BACK: state <= IDLE;
                CACHE_INST: state <= (cache_finish)?IDLE:CACHE_INST;
                RESETN:  state <= (!(rstn_cnt_d ^ (`DATA_CACHE_GROUP_NUM-1)))?IDLE:RESETN;
                //TODO: Add instruction support
                default: state <= IDLE;
            endcase 
        end
    end
    //--------------Prefetcher FSM-------------
    assign need_pre_fetching_d = (cont_mem)?(!(wtag ^ tag) | !(windex ^ index)):(!(wtag ^ last_tag) | !(windex ^ last_index));

    always @(posedge clk)begin
        if (!rstn) begin
            need_pre_fetching <= 1'b0;
        end
        else begin
            need_pre_fetching <= need_pre_fetching_d;
        end
    end

    //low activ
    always @(posedge clk) begin
        if (!rstn) begin
            pre_state <= PRE_RESETN;
        end        
        else begin
            case (pre_state_d)
                PRE_IDLE:   pre_state <= PRE_IDLE;//disable
                PRE_RUN :   pre_state <= (last_req)?
                                            (
                                                ((!idle & !run & !miss) & !need_pre_fetching & !hit_when_refill & (!hit_array))?PRE_GET_ADDR:PRE_RUN
                                            ):PRE_RUN;
                PRE_GET_ADDR : pre_state <= PRE_MISS;
                PRE_MISS:   pre_state <= (arready & pre_data_ready)?PRE_WAIT_FOR_AXI:PRE_MISS;
                PRE_WAIT_FOR_AXI: pre_state <= (rvalid & pre_data_back)?PRE_REFILL:PRE_WAIT_FOR_AXI;
                PRE_REFILL: pre_state <= (rlast & rvalid & pre_data_back)?PRE_FINISH:PRE_REFILL;
                PRE_FINISH: pre_state <= PRE_WAIT_FLUSH;
                PRE_WAIT_FLUSH: pre_state <= PRE_GET_WRITE_LINE;
                PRE_GET_WRITE_LINE: pre_state <= (get_write_line)?PRE_GET_WRITE_LINE:PRE_WRITE_BACK;
                PRE_WRITE_BACK: pre_state <= PRE_RUN; //TODO: reduce
                PRE_RESETN: pre_state <= (!(rstn_cnt_d ^ (`DATA_CACHE_GROUP_NUM-1)))?PRE_IDLE:PRE_RESETN;
                default: pre_state <= IDLE;
            endcase
        end
    end
    //----------------Victim FSM---------------
    always @(posedge clk) begin
        if (!rstn) begin
            victim_state <= VICTIM_IDLE;
        end        
        else begin
            case (victim_state_d)
                VICTIM_IDLE:       victim_state <= (empty)?VICTIM_IDLE:
                                                        VICTIM_START_AXI;
                VICTIM_START_AXI:  victim_state <= (awready)?VICTIM_WRITE_BACK:
                                                        VICTIM_START_AXI;
                VICTIM_WRITE_BACK: victim_state <= (!(victim_cnt_d ^ 3'd7) & wready)?
                                                        VICTIM_FINISH:VICTIM_WRITE_BACK;
                VICTIM_FINISH:     victim_state <= (bvalid & !(bid ^ 4'b0))?VICTIM_IDLE:
                                                        VICTIM_FINISH;
                default:;
            endcase
        end
    end
    //--------------------Cache State-------------------
    always @(posedge clk) begin
        if (!rstn) begin
            cache_state <= CACHE_IDLE;
        end    
        else begin
            case (cache_state_d) 
                CACHE_IDLE: cache_state <= 
                                (cache_inst)?
                                (
                                    (cache_op[3])?CACHE_INDEX_WRITEBACK_INVALID:
                                    (cache_op[4])?CACHE_INDEX_STORE_TAG:
                                    (cache_op[5])?CACHE_HIT_INVALID:
                                    (cache_op[6])?CACHE_HIT_WRITEBACK_INVALID:
                                    CACHE_FINISH
                                )
                                :CACHE_IDLE;
                CACHE_INDEX_WRITEBACK_INVALID: cache_state <= CACHE_INDEX_WRITEBACK_INVALID_START;
                CACHE_INDEX_WRITEBACK_INVALID_START: cache_state <= (valid_array[way_sel[1]] & dirty[way_sel[1]][op_index])?
                                                            CACHE_WAIT:CACHE_FINISH;
                CACHE_INDEX_STORE_TAG: cache_state <= CACHE_FINISH;
                CACHE_HIT_INVALID: cache_state <= CACHE_HIT_INVALID_READ_HIT;
                CACHE_HIT_INVALID_READ_HIT: cache_state <= (cache_hit)?CACHE_HIT_INVALID_HIT:CACHE_FINISH;
                CACHE_HIT_INVALID_HIT: cache_state <= CACHE_FINISH;
                CACHE_HIT_WRITEBACK_INVALID: cache_state <= CACHE_HIT_WRITEBACK_INVALID_READ_HIT;
                CACHE_HIT_WRITEBACK_INVALID_READ_HIT: cache_state <= (cache_hit & dirty[way_sel[1]][op_index] & valid_array[way_sel[1]])?CACHE_WAIT:CACHE_FINISH;
                CACHE_WAIT: cache_state <= (victim_idle)?CACHE_START:CACHE_WAIT;
                CACHE_START: cache_state      <= CACHE_START_AXI;
                CACHE_START_AXI: cache_state  <= (awready)?CACHE_WRITE_BACK:CACHE_START_AXI;
                CACHE_WRITE_BACK: cache_state <= (victim_finish)?CACHE_FINISH:CACHE_WRITE_BACK;//FIXME: use victim_idle
                CACHE_FINISH: cache_state     <= CACHE_IDLE;
                default:;
            endcase
        end
    end
    //---------------------Sub Module--------------------
    generate 
        genvar m;
        for (m=0;m<`DATA_CACHE_ASSO;m=m+1) begin
            data_cache_tagv Data_Cache_TagV(
                .hit(hit_array[m]),
                .valid(valid_array[m]),
                .tag_rdata(tag_rdata[m]),
                .clk(clk),
                .en(1'b1),
                .op_wen(op_wen[m]),
                .wen(tagv_wen[m]),
                .tag_wdata(tag_wdata),
                .index(tagv_index_in),
                .valid_wdata(valid_wdata)
            );

            /*
              FIXME:
                This design could not deal with situation: read after write
                actually read after write will cause imflict
                use pause or redirector to solve this
                so it will work fine

                could excute store and load instructions without changing state
            */
            data_cache_data_ram Data_Cache_Data ( //FIXME: warning: could not deal with situation: write and read immediately
                    .clka(clk),
                    .ena(1'b1),
                    .wea(data_wen[m]),
                    .addra(data_index_in_a),
                    .dina(bank_wdata),

                    .doutb(bank_rdata[m]),
                    .enb(1'b1),
                    .clkb(clk),
                    .addrb(data_index_in_b)
            );
        end
    endgenerate
endmodule


