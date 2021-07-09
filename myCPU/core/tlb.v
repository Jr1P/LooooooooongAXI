`timescale 1ns/100ps

module compare (
    input [89:0] in
    // output [(1<<bits)-1:0] out
);

endmodule
// *TODO TLB

module tlb(
    input           clk,
    input           resetn,

    // * read
    input           ren,
    input [18:0]    vaddr,
    // * write
    input           wen,
    input [4 :0]    windex,
    input [18:0]    wVPN2,
    input [7 :0]    wASID,
    input [11:0]    wPageMask,
    input           wG,
    input [19:0]    wPFN0,
    input [4 :0]    wFlags0,
    input [19:0]    wPFN1,
    input [4 :0]    wFlags1,

    output          hit,
    output          miss,
    output [19:0]   paddr  // * 命中时返回物理页号
);
    // * VPN2 ASID PageMask G PFN0 FLAGS0 PFN1 FLAGS1
    reg [89:0]  entry[31:0];
    
    integer i;
    always @(posedge clk) begin
        if(!resetn) begin
            for(i = 0; i < 32; i = i+1)
                entry[i] <= 90'd0;
        end
        else if(wen)
            entry[windex]   <= {wVPN2, wASID, wPageMask, wG, wPFN0, wFlags0, wPFN1, wFlags1};
    end
   
endmodule