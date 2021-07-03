/*
    @Copyright HIT team
    The definition of the excption code in CP0
*/

`ifndef _EXCPTION_CODE_VH_


/* Exception Code: Begin */
`define EXC_CODE_LEN      5
`define EXC_CODE_BUS      `N(`EXC_CODE_LEN)
// Cause Register ExcCode Value
`define EXC_CODE_INT      8'h00 // Interrupt
`define EXC_CODE_MOD      8'h01 // TLB modification exception
`define EXC_CODE_TLBL     8'h02 // TLB exception (load or instruction fetch)
`define EXC_CODE_TLBS     8'h03 // TLB exception (store)
`define EXC_CODE_ADEL     8'h04 // Address error exception (load or instruction fetch)
                               // Reference was a load or an instruction fetch
`define EXC_CODE_ADES     8'h05 // Address error exception (store)
                               // Reference was a store
// `define EXC_CODE_IBE      8'h06 // Bus error exception (instruction fetch)
// `define EXC_CODE_DBE      8'h07 // Bus error exception (data reference: load or store)
`define EXC_CODE_SYS      8'h08 // Syscall exception
                               // SYSCALL --> System Call
`define EXC_CODE_BP       8'h09 // Breakpoint exception. If EJTAG is implemented and an SDBBP instruction is executed while the processor is running in EJTAG Debug Mode, this value is written to the DebugDExcCode field to denote an SDBBP in Debug Mode.
                               // BREAK --> Break Point
`define EXC_CODE_RI       8'h0a // Reserved instruction exception
`define EXC_CODE_CPU      8'h0b // Coprocessor Unusable exception
`define EXC_CODE_OV       8'h0c // Arithmetic Overflow exception
`define EXC_CODE_TR       8'h0d // Trap exception
// `define EXC_CODE_0E       8'h0e // Reserved
// `define EXC_CODE_FPE      8'h0f // Floating point exception
// `define EXC_CODE_10       8'h10 // Available for implementation dependent use
// `define EXC_CODE_11       8'h11 // Available for implementation dependent use
// `define EXC_CODE_C2E      8'h12 // Reserved for precise Coprocessor 2 exceptions
// `define EXC_CODE_TLBRI    8'h13 // TLB Read-Inhibit exception
// `define EXC_CODE_TLBXI    8'h14 // TLB Execution-Inhibit exception
// `define EXC_CODE_15       8'h15 // Reserved
// `define EXC_CODE_MDMX     8'h16 // MDMX Unusable Exception (MDMX ASE)
// `define EXC_CODE_WATCH    8'h17 // Reference to WatchHi/WatchLo address
// `define EXC_CODE_MCHECK   8'h18 // Machine check
// `define EXC_CODE_THREAD   8'h19 // Thread Allocation, Deallocation, or Scheduling Exceptions (MIPS® MT ASE)
// `define EXC_CODE_DSPDIS   8'h1a // DSP ASE State Disabled exception (MIPS® DSP ASE)
// `define EXC_CODE_1B       8'h1b // Reserved
// `define EXC_CODE_1C       8'h1c // Reserved
// `define EXC_CODE_1D       8'h1d // Reserved
// `define EXC_CODE_CACHEERR 8'h1e // Cache error. In normal mode, a cache error exception has a dedicated vector and the Cause register is not updated. If EJTAG is implemented and a cache error occurs while in Debug Mode, this code is written to the DebugDExcCode field to indicate that re-entry to Debug Mode was caused by a cache error.
// `define EXC_CODE_1F       8'h1f // Reserved
/* Exception Code: End */


`endif