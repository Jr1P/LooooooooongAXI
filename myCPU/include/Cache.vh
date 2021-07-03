/*
    @Copyright HIT team
        The definition of cache
*/
`ifndef CACHE_VH
//----------Inst_Cache----------
/*
    Inst Cache Structure
        LRU 128 * 3,p-lru

    Inst Cache Properties
        Associativity: 4
        Way Size: 2 ^ 14 = 4KB
        Line Size: 2 ^ 5 = 32B
        Group Num: 128
        Bank Num: 2 ^ 3 = 8
        Bank Size: 2 ^ 5 = 32b
        Tag Width: 20b
        Valid Width: 1b
        LRU Width: 3b
        Address Format:
*/
//Inst Cache Properties
`define INST_CACHE_ASSO 4
`define INST_CACHE_GROUP_NUM 128
`define INST_CACHE_BANK_NUM 8
`define INST_CACHE_BANK_SIZE 3
`define INST_CACHE_BANK_WIDTH 32
`define INST_CACHE_LRU_WIDTH 3
//Inst Cache Address
`define INST_CACHE_TAGV_WIDTH 21
`define INST_CACHE_TAG_WIDTH 20
`define INST_CACHE_V_WIDTH 1
`define INST_CACHE_INDEX_WIDTH 7
`define INST_CACHE_OFFSET_WIDTH 5
//Inst Cache Format
`define INST_CACHE_TAG 31:12
`define INST_CACHE_INDEX 11:5
`define INST_CACHE_OFFSET 4:0
//Prefetcher
`define PREFETCHER_NUM 128
`define PREFETCHER_WIDTH 7
`define PREFETCHER_INDEX 6:0
//----------Data Cache----------
/*
    Data Cache Structure
        LRU 128 * 1,p-lru
    
    Data Cache Properties
        Associativity: 2
        Way Size: 2 ^ 14 = 4KB
        Line Size: 2 ^ 5 = 32B
        Group Num: 128
        Bank Num: 2 ^ 3 = 8
        Bank Size = 2 ^ 5 = 32b
        Tag Width: 20b
        Valid Width: 1b
        LRU Width: 1
        Dirty Width: 1
        Address Format:
*/
//Data Cache Properties
`define DATA_CACHE_ASSO 2
`define DATA_CACHE_GROUP_NUM 128
`define DATA_CACHE_BANK_NUM 8
`define DATA_CACHE_BANK_SIZE 3
`define DATA_CACHE_BANK_WIDTH 32
`define DATA_CACHE_LRU_WIDTH 1
`define DATA_CACHE_DIRTY_WIDTH 1
//Data Cache Address
`define DATA_CACHE_TAGV_WIDTH 21
`define DATA_CACHE_TAG_WIDTH 20
`define DATA_CACHE_V_WIDTH 1
`define DATA_CACHE_INDEX_WIDTH 7
`define DATA_CACHE_OFFSET_WIDTH 5
//Data Cache Format
`define DATA_CACHE_TAG 31:12
`define DATA_CACHE_INDEX 11:5
`define DATA_CACHE_OFFSET 4:0
//----------Store Buffer----------
/*
    FIFO:
        Use Xilink Parameterized Macros singal port bram
        FIFO Num: 32
        FIFO Base Address Width: 32
        FIFO Bank Num: 8
        FIFO Bank Width: 32
        FIFO Bank Size: 3
*/
//FIFO Properties
`define FIFO_NUM 32
`define FIFO_WIDTH 5
`define FIFO_ADDR_WIDTH 32
`define FIFO_BANK_NUM 8
`define FIFO_BANK_WIDTH 32
`define FIFO_BANK_SIZE 3
//FIFO Format
`define FIFO_TAG_INDEX 31:5

`endif