`timescale 1ns/1ps

// * A / B
module div(
    input   clk,
    input   resetn,
    
    input   en,         // * 除法使能, 1: 有除法请求, 0: 无
    input   sign,       // * 1: signed, 0: else
    input [31:0]    A,
    input [31:0]    B,
    input           cancel,

    output [31:0]   Q,  // * Quotient
    output [31:0]   R,  // * remainder

    output          working,
    output          finish
);

    reg [4:0] cnt;
    reg sign_Q, sign_R;  
    reg [63:0] x, y1, y2, y3;
    reg [31:0] quot;
    wire [63:0] y1_init = {2'd0, (B[31] && sign) ? ~B+1'b1 : B, 30'd0};
    wire [64:0] sub1 = x - y1;
    wire [64:0] sub2 = x - y2;
    wire [64:0] sub3 = x - y3;

    always @(posedge clk) begin
        if(!resetn || finish)   cnt <= 5'd0;
        if(cancel)              cnt <= 5'd1;
        else if(en || working)  cnt <= cnt+5'd1;
    end

    always @(posedge clk) begin
        if(!resetn) begin
            x   <= 64'd0;
            y1  <= 64'd0;
            y2  <= 64'd0;
            y3  <= 64'd0;
            quot<= 32'd0;
            sign_Q  <= 1'b0;
            sign_R  <= 1'b0;
        end
        else if(en) begin
            x   <= {32'd0, A[31] && sign ? ~A+1'b1 : A};
            y1  <= y1_init;
            y2  <= y1_init << 1;
            y3  <= y1_init + (y1_init << 1);
            sign_Q  <= (A[31]^B[31]) && sign;
            sign_R  <= A[31] && sign;
        end
        else if(cnt != 5'd17) begin
            x   <=  !sub3[64] ? sub3[63:0] :
                    !sub2[64] ? sub2[63:0] :
                    !sub1[64] ? sub1[63:0] : x;
            y1  <= y1 >> 2;
            y2  <= y2 >> 2;
            y3  <= y3 >> 2;
            quot<= (quot << 2) | {30'd0, {!sub3[64] || !sub2[64], !sub3[64] || (sub2[64] && !sub1[64])}};
        end
    end

    assign Q    = {32{sign_Q}}  & (~quot+1'b1)
                | {32{!sign_Q}} & quot;
    assign R    = {32{sign_R}}  & (~x[31:0]+1'b1)
                | {32{!sign_R}} & x[31:0];
    assign working = cnt != 5'd0 && !finish;
    assign finish = cnt == 5'd17;

endmodule