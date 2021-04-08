`timescale 1ns / 1ps
module store_buffer
(
    input          clk,
    input          rstn,

    input          store_buffer_write_req    ,
    input          store_buffer_write_wr     ,
    input   [1 :0] store_buffer_write_size   ,
    input   [31:0] store_buffer_write_addr   ,
    input   [31:0] store_buffer_write_wdata  ,
	input   [3 :0] store_buffer_write_wstrb  ,
    output  [31:0] store_buffer_write_rdata  ,
    output         store_buffer_write_addr_ok,
    output         store_buffer_write_data_ok,

    output          store_buffer_read_req    ,
    output          store_buffer_read_wr     ,
    output   [1 :0] store_buffer_read_size   ,
    output   [31:0] store_buffer_read_addr   ,
    output   [31:0] store_buffer_read_wdata  ,
	output   [3 :0] store_buffer_read_wstrb  ,
    input    [31:0] store_buffer_read_rdata  ,
    input           store_buffer_read_addr_ok,
    input           store_buffer_read_data_ok
);
    //------------------FIFO------------------
    /*
        32 * 32 FIFO
    */
    reg [4:0]  fifo_index [31:0];
    reg [31:0] fifo_addr  [31:0];
    reg [31:0] fifo_wdata [31:0];
    reg [3:0]  fifo_wstrb [31:0];
    reg [1:0]  fifo_size  [31:0];

    reg [4:0]  ptr_rd;
    reg [4:0]  ptr_wr;
    wire [4:0] ptr_wr_d;
    assign     ptr_wr_d = ptr_wr + 5'd1;

    wire   full;
    wire   empty;
    assign full  = (ptr_wr_d == ptr_rd);
    assign empty = (ptr_rd == ptr_wr);
    //----------Pop State----------------
    parameter POP_IDLE = 2'b00;
    parameter POP_RUN  = 2'b01;
    parameter POP_WORK = 2'b10;
    reg [1:0] pop_state;

    //----------Push State---------------
    parameter PUSH_IDLE = 2'b00;
    parameter PUSH_RUN  = 2'b01;
    parameter PUSH_WORK = 2'b10;
    reg [1:0] push_state;

    //----------Read Singal--------------
    wire        read_data_ok;
    wire        read_addr_ok;
    wire [31:0] read_addr;
    wire [31:0] read_wdata;
    wire [3:0]  read_wstrb;
    wire        read_req;
    wire        read_wr;
    wire [1:0]  read_size;

    wire        buffer_data_ok;
    wire        buffer_push;
    wire        push;
    reg         last_rcv;
    wire        rcv;
    reg         data_ok_ready;

    always @(posedge clk) begin
        if(!rstn) begin
            data_ok_ready <= 1'b0;
        end
        else if(push) begin
            data_ok_ready <= 1'b1;
        end
        else if(store_buffer_write_data_ok && (push_state != 4'd2)) begin
            data_ok_ready <= 1'b0;
        end
        else begin
        end
    end

    assign push = !full && store_buffer_write_wr && store_buffer_write_req;
    assign buffer_push = push;
    assign buffer_data_ok = data_ok_ready;

    assign read_addr    = fifo_addr[ptr_rd];
    assign read_wr      = 1'b1;
    assign read_req     = ((pop_state == POP_RUN) || read_data_ok) && !empty && !last_rcv;
    assign read_wstrb   = fifo_wstrb[ptr_rd];
    assign read_wdata   = fifo_wdata[ptr_rd];
    assign read_size    = fifo_size[ptr_rd];
    assign read_addr_ok = read_req && store_buffer_read_addr_ok; 
    assign read_data_ok = (pop_state == POP_WORK) && (push_state != PUSH_WORK) && store_buffer_read_data_ok;

    always @(posedge clk) begin
        if(!rstn) begin
            last_rcv <= 1'b0;
        end
        else if(rcv) begin
            last_rcv <= 1'b1;
        end
        else begin
            last_rcv <= 1'b0;
        end
    end
    //------------------Write Singal-----------------------
    wire        write_data_ok;
    wire        write_addr_ok;
    wire [31:0] write_addr;
    wire [31:0] write_rdata;
    wire [31:0] write_wdata;
    wire [3:0]  write_wstrb;
    wire [1:0]  write_size;
    wire        write_req;
    wire        write_wr;
    wire        write_work;

    assign rcv = push && empty && write_addr_ok;
    assign write_work    = empty;
    assign write_data_ok = store_buffer_read_data_ok;
    assign write_addr_ok = write_work && write_req && store_buffer_read_addr_ok;
    assign write_addr    = store_buffer_write_addr;
    assign write_rdata   = store_buffer_read_rdata;
    assign write_wdata   = store_buffer_write_wdata;
    assign write_wstrb   = store_buffer_write_wstrb;
    assign write_req     = store_buffer_write_req;
    assign write_size    = store_buffer_write_size;
    assign write_wr      = store_buffer_write_wr;
    //-----------------In and Out Singal-----------------------
    assign store_buffer_read_req      = (write_work) ? write_req   : read_req;
    assign store_buffer_read_wr       = (write_work) ? write_wr    : read_wr;
    assign store_buffer_read_size     = (write_work) ? write_size  : read_size;
    assign store_buffer_read_addr     = (write_work) ? write_addr  : read_addr;
    assign store_buffer_read_wdata    = (write_work) ? write_wdata : read_wdata;
    assign store_buffer_read_wstrb    = (write_work) ? write_wstrb : read_wstrb;

    assign store_buffer_write_rdata   = write_rdata;
    assign store_buffer_write_addr_ok = write_addr_ok || buffer_push;
    assign store_buffer_write_data_ok = ((push_state == PUSH_WORK)) ? write_data_ok : buffer_data_ok;

    //-------------------POP FSM------------------------------
    always @(posedge clk) begin
        if (!rstn) begin
            pop_state <= POP_IDLE;
        end
        else begin
            case (pop_state)
                POP_IDLE: pop_state <= POP_RUN;
                POP_RUN : pop_state <= (read_addr_ok || rcv)?POP_WORK:POP_RUN;
                POP_WORK: pop_state <= (read_data_ok && !(read_addr_ok || rcv))?POP_RUN:POP_WORK;
                default:;
            endcase 
        end
    end
    //-------------------PUSH FSM-----------------------------
    always @(posedge clk) begin
        if (!rstn) begin
            push_state <= PUSH_IDLE;
        end
        else begin
            case (push_state)
                PUSH_IDLE: push_state <= PUSH_RUN;
                PUSH_RUN : push_state <= (write_addr_ok && !rcv)?PUSH_WORK:PUSH_RUN;
                PUSH_WORK: push_state <= (write_data_ok && !(write_addr_ok || rcv))?PUSH_RUN:PUSH_WORK;
                default:;
            endcase 
        end
    end
    //------------------Pointer-----------------------
    always @(posedge clk) begin
        if(!rstn) begin
            ptr_rd <= 5'd0;
        end
        else if((read_addr_ok && !empty) || rcv) begin
            ptr_rd <= ptr_rd + 5'd1;
        end
        else begin
        end
    end

    always @(posedge clk) begin
        if(!rstn) begin
            ptr_wr <= 5'd0;
		end
        else if(push) begin
            ptr_wr <= ptr_wr + 5'd1;
        end
        else begin
        end
	end
    //--------------------FIFO-------------------------
    always @(posedge clk) begin
        if(push) begin
            fifo_wdata[ptr_wr] <= store_buffer_write_wdata;
            fifo_size [ptr_wr] <= store_buffer_write_size;
            fifo_wstrb[ptr_wr] <= store_buffer_write_wstrb;
            fifo_addr [ptr_wr] <= store_buffer_write_addr;
        end
        else begin
        end
    end
endmodule

