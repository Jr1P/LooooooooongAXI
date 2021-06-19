`timescale 1ns/1ps

// * normal mul
`define PIPELINE_DEPTH 3
module mul(
    input   clk,
    input   resetn,
    input   en,
    input   cancel,

    input [32:0]    A,
    input [32:0]    B,

    output [65:0]   res,
    output          working,
    output          finish
);

    reg [2:0] cnt;
    always @(posedge clk) begin
        if(!resetn || finish)   cnt <= 3'd0;
        else if(cancel)         cnt <= 3'd1;
        else if(en || working)  cnt <= cnt + 3'd1;
    end

    reg reg_en;
    always @(posedge clk) begin
        if(!resetn) reg_en <= 1'b0;
        else if(!reg_en) reg_en <= en;
        else if(!en && finish) reg_en <= 1'b0;
    end

    mult_gen_1 mul1(
        .CLK    (clk),
        .CE     (en || reg_en),

        .A      (A),
        .B      (B),

        .P      (res)
    );

    assign working = cnt && !finish;
    assign finish = cnt == `PIPELINE_DEPTH;

endmodule