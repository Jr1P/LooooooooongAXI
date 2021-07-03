`timescale 1ns/1ps

module ec_wb_seg (
    input   clk,
    input   resetn,

    input   stall,
    input   refresh,

    input [31:0]    ec_data_rdata,
    input [31:0]    ec_pc,
    input [31:0]    ec_inst,

    input           ec_load,

    input           ec_regwen,
    input [4 :0]    ec_wreg,

    input           ec_eret,
    input [31:0]    ec_reorder_data,

    output reg [31:0]   wb_data_rdata,
    output reg [31:0]   wb_pc,
    output reg [31:0]   wb_inst,
    output reg          wb_load,

    output reg          wb_regwen,
    output reg [4 :0]   wb_wreg,

    output reg          wb_eret,
    output reg [31:0]   wb_reorder_ec
);

    always @(posedge clk) begin
        if(!resetn || refresh) begin
            wb_data_rdata   <= 32'b0;
            wb_pc           <= 32'b0;
            wb_inst         <= 32'b0;
            wb_load         <= 1'b0;
            wb_regwen       <= 1'b0;
            wb_wreg         <= 5'b0;
            wb_eret         <= 1'b0;
            wb_reorder_ec   <= 32'h0;
        end
        else if(!stall) begin
            wb_data_rdata   <= ec_data_rdata;
            wb_pc           <= ec_pc;
            wb_inst         <= ec_inst;
            wb_load         <= ec_load;
            wb_regwen       <= ec_regwen;
            wb_wreg         <= ec_wreg;
            wb_eret         <= ec_eret;
            wb_reorder_ec   <= ec_reorder_data;
        end
    end

endmodule