`timescale 1ns/1ps

module div(
    input [31:0]    A,
    input [31:0]    B,

    output          [63:0]  res,
    output signed   [63:0]  signedres
);

    assign res = {A % B, A / B};
    assign signedres = {$signed(A)%$signed(B), $signed(A)/$signed(B)};

endmodule