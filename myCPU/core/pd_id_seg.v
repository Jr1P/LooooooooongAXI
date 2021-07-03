`timescale 1ns/100ps

// * pd id 段 TODO
module pd_id_seg (
    input           resetn,
    input           clk,

    input           stall,
    input           refresh,

    input [31:0]    pd_pc,
    input [31:0]    pd_inst,
    input           pd_bd,
    input           pd_jump,

    // * O
    output reg [31:0]   id_pc,
    output reg [31:0]   id_inst,
    output reg          id_bd,
    output reg          id_jump
);
    
endmodule