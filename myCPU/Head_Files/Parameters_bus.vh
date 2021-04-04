/*
    @Copyright HIT team
*/
`ifndef PARAMETERS_BUS_VH

//-----segment bus-----
//IF-ID BUS
`define IF_ID_BUS_WIDTH             105
`define IF_EXC_BUS                  40:0
`define IF_PC                       72:41
`define IF_IR                       104:73
//ID-EX BUS
`define ID_EX_BUS_WIDTH             238
`define ID_EXC_BUS                  40:0
`define ID_PC                       72:41
`define ID_IR                       104:73
`define ID_REG_A                    136:105
`define ID_REG_B                    168:137
`define ID_IMM                      200:169
`define ID_ALU_OP2_MUX_SEL          201
`define ID_MTHI                     202
`define ID_MTLO                     203
`define ID_DIV                      204
`define ID_DIVU                     205
`define ID_MULT                     206
`define ID_MULTU                    207
`define ID_MFHI                     208
`define ID_MFLO                     209
`define ID_HI_WEN                   210
`define ID_LO_WEN                   211
`define ID_LINK                     212
`define ID_MEM_CTRL                 220:213
`define ID_RF_WEN                   221
`define ID_RF_WADDR                 226:222
`define ID_MTC0                     227
`define ID_MFC0                     228
`define ID_CP0_ADDR                 236:229
`define ID_LMD_TAKEN                237
//EX-MEM BUS
`define EX_MEM_BUS_WIDTH            226
`define EX_EXC_BUS                  40:0
`define EX_PC                       72:41
`define EX_MEM_ADDR                 104:73
`define EX_MEM_CTRL                 112:105
`define EX_MEM_WDATA                144:113
`define EX_RF_WEN                   145
`define EX_RF_WADDR                 150:146
`define EX_RF_WDATA                 182:151
`define EX_MTC0                     183
`define EX_MFC0                     184
`define EX_CP0_ADDR                 192:185
`define EX_REG_B                    224:193
`define EX_LMD_TAKEN                225
//MEM-WB BUS
`define MEM_WB_BUS_WIDTH            72
`define MEM_PC                      31:0
`define MEM_RF_WEN                  32
`define MEM_RF_WADDR                37:33
`define MEM_RF_WDATA                69:38
`define MEM_LMD_TAKEN               70
`define MEM_MFC0                    71

//-----redirector bus-----
//TODO:1
//ssign redir_ex_bus =   {id_ex_bus[`ID_RF_WEN],id_ex_bus[`ID_RF_WADDR],rf_ready,rf_wdata};
`define REDIR_EX_BUS_WIDTH          39
`define REDIR_EX_RF_WDATA           31:0
`define REDIR_EX_RF_READY           32
`define REDIR_EX_RF_WADDR           37:33
`define REDIR_EX_RF_WEN             38




/*assign redir_mem_bus    =   {ex_mem_bus[`EX_RF_WEN],
                                ex_mem_bus[`EX_RF_WADDR],
                                rf_ready,
                                ex_mem_bus[`EX_RF_WDATA]};*/

`define REDIR_MEM_BUS_WIDTH         39
`define REDIR_MEM_RF_WDATA          31:0
`define REDIR_MEM_RF_READY          32
`define REDIR_MEM_RF_WADDR          37:33
`define REDIR_MEM_RF_WEN            38


/* assign redir_wb_bus         =  {mem_wb_bus[`MEM_RF_WEN],
                                    mem_wb_bus[`MEM_RF_WADDR],
                                    rf_wdata};*/
`define REDIR_WB_BUS_WIDTH          38
`define REDIR_WB_RF_WDATA           31:0
`define REDIR_WB_RF_WADDR           36:32
`define REDIR_WB_RF_WEN             37

//-----regfile write back bus-----
/*    assign rf_bus               =  {mem_wb_bus[`MEM_RF_WEN],
                                    mem_wb_bus[`MEM_RF_WADDR],
                                    rf_wdata};*/
`define RF_BUS_WIDTH                38
`define RF_WDATA                    31:0
`define RF_WADDR                    36:32
`define RF_WEN                      37

//-----pc bus-----
//Jump and branch pc bus
`define JBR_PC_BUS_WIDTH            33
`define JBR_TARGET                  31:0
`define JBR_VALID                   32
//Exception pc bus
`define EXC_PC_BUS_WIDTH            33
`define EXC_TARGET                  31:0
`define EXC_VALID                   32

//-----Control signal bus-----
//Jump and branch control bus
`define JBR_CTRL_WIDTH              10
`define JBR_BEQ                     9
`define JBR_BNE                     8
`define JBR_BGEZ                    7
`define JBR_BGTZ                    6
`define JBR_BLEZ                    5
`define JBR_BLTZ                    4
`define JBR_BGEZAL                  3
`define JBR_BLTZAL                  2
`define JBR_J_VALID                 1
`define JBR_JR_VALID                0
//memory access control bus
`define MEM_CTRL_WIDTH              8
`define MEM_LB                      7
`define MEM_LBU                     6
`define MEM_LH                      5
`define MEM_LHU                     4
`define MEM_LW                      3
`define MEM_SB                      2
`define MEM_SH                      1
`define MEM_SW                      0

//-----exception bus-----
`define EXC_BUS_WIDTH               15
`define EXC_ADEL_INST               0
`define EXC_ADEL_DATA               1
`define EXC_ADES                    2
`define EXC_SYS                     3
`define EXC_BP                      4
`define EXC_RI                      5
`define EXC_OV                      6
`define EXC_ERET                    7
`define EXC_HINT                    12:8
`define EXC_SINT                    14:13



//-----CP0 bus-----
`define CP0_BUS_WIDTH               119
`define CP0_WEN                     0
`define CP0_WDATA                   32:1
`define CP0_ADDR                    40:33
`define CP0_EXC_EN                  41
`define CP0_EXC_CODE                46:42
`define CP0_BAD_ADDR                78:47
`define CP0_PC                      110:79
`define CP0_ERET                    111
`define CP0_IS_IN_SLOT              112
`define CP0_INT                     118:113

`endif