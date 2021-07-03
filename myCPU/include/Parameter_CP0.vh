/*
    @Copyright HIT team
    The definition of the parameters in CP0
*/
`ifndef _CP0_PARAMETER_VH_

`include "./Macro.vh"

`define RstEnable   1
`define ExcEnable   1
`define ExcValid    1
`define ExcInvalid  0
`define WriteEnable 1
// Status.IM
`define IRQEnable   1
// Status.EXL
`define NorLevel    0   // Normal Level
`define ExcLevel    1   // Exception level


`define REG_LEN     32
`define REG_ZERO    `ZERO(`REG_LEN)
`define REG_BUS     `N(`REG_LEN)

`define INT_HW_NUM  6
`define INT_SW_NUM  2
`define INT_NUM     `INT_HW_NUM + `INT_SW_NUM
`define INT_HW_BUS  `N(`INT_HW_NUM)
`define INT_SW_BUS  `N(`INT_SW_NUM)


`define EXC_ENTER_ADDR  32'hBFC00380    // Exception Vector Enter Addresses

// TLB
`define TLB_ENTRIES_NUM     32      // TODO

// ( 0, 0) - Index Register
`define INDEX_INDEX_LEN     $clog2(`TLB_ENTRIES_NUM)
`define INDEX_INDEX_POS     0


// (11, 0) - Compare Register

// (12, 0) - Status Register
`define STATUS_BEV_LEN      1
`define STATUS_HIM_LEN      `INT_HW_NUM
`define STATUS_SIM_LEN      `INT_SW_NUM
`define STATUS_IM_LEN       `INT_NUM
`define STATUS_EXL_LEN      1
`define STATUS_IE_LEN       1
`define STATUS_BEV_POS      22
`define STATUS_HIM_POS      10
`define STATUS_SIM_POS      8
`define STATUS_IM_POS       `STATUS_SIM_POS
`define STATUS_EXL_POS      1
`define STATUS_IE_POS       0
`define STATUS_BEV          `PINS(`STATUS_BEV_POS, `STATUS_BEV_LEN)
`define STATUS_IM           `PINS(`STATUS_IM_POS,  `STATUS_IM_LEN )
`define STATUS_HIM          `PINS(`STATUS_HIM_POS, `STATUS_HIM_LEN)
`define STATUS_EXL          `PINS(`STATUS_EXL_POS, `STATUS_EXL_LEN)
`define STATUS_IE           `PINS(`STATUS_IE_POS,  `STATUS_IE_LEN )

// (13, 0) - Cause Register
`define CAUSE_BD_LEN        1
`define CAUSE_TI_LEN        1
`define CAUSE_TIP_LEN       1
`define CAUSE_HIP_LEN       `INT_HW_NUM     // Hardware
`define CAUSE_SIP_LEN       `INT_SW_NUM     // Software
`define CAUSE_IP_LEN        `INT_NUM
`define CAUSE_EC_LEN        `EXC_CODE_LEN   // EC: ExcCode
`define CAUSE_BD_POS        31
`define CAUSE_TI_POS        30
`define CAUSE_HIP_POS       10  // Hardware
`define CAUSE_SIP_POS       8   // Software
`define CAUSE_IP_POS        `CAUSE_SIP_LEN
`define CAUSE_EC_POS        2   // EC: ExcCode
`define CAUSE_BD            `PINS(`CAUSE_BD_POS,  `STATUS_BD_LEN )
`define CAUSE_TI            `PINS(`CAUSE_TI_POS,  `STATUS_TI_LEN )
`define CAUSE_TIP           `PINS(`CAUSE_TIP_POS, `STATUS_TIP_LEN)
`define CAUSE_HIP           `PINS(`CAUSE_HIP_POS, `STATUS_HIP_LEN)
`define CAUSE_SIP           `PINS(`CAUSE_SIP_POS, `STATUS_SIP_LEN)
`define CAUSE_IP            `PINS(`CAUSE_IP_POS,  `STATUS_IP_LEN )
`define CAUSE_EC            `PINS(`CAUSE_EC_POS,  `STATUS_EC_LEN )


`define CAUSE_TI_MASK       5'b10000

// (15, 0) - Processor Identification
`define PRID_CO_OPT         8'b00000000     // Company Options
`define PRID_CO_ID          8'b00000001     // Company ID
`define PRID_PR_ID          8'b00000000     // Processor ID
`define PRID_REVI           8'b00000000     // Revision

// (16, 0) - Configuration Register
`define CONFIG0_M           1'b0            // Make share Config1 register is not implemented !!!!
`define CONFIG0_NI1         15'b0           // Not implemented fields 1
`define LITTLE_ENDIAN       1'b0
`define BIG_ENDIAN          1'b1
`define CONFIG0_NI2         5'b0
`define CONFIG0_MT          3'b1            // MMU Type
`define CONFIG0_NI3         4'b0
`define CONFIG0_K0_LEN      3
`define CONFIG0_K0_POS      0
`define CONFIG0_K0          `PINS(`CONFIG0_K0_POS, `CONFIG0_K0_LEN)
`define CONFIG0_K0_DEFAULT  `CONFIG0_K0_LEN'd3

`endif