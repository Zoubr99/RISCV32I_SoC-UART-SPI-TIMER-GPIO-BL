`ifndef _IO_MAP_INCLUDED
`define _IO_MAP_INCLUDED

// systemverilog heeader file exactly the same as the c header file except the cpp definition

// system clock rate in MHz; used for timer and uart
`define SYS_CLK_FREQ 100

// io base adress for uBlaze MCS
`define BRIDGE_BASE 0xc0000000

// slot module definition
// format: Slot#_ModuleType_Name
`define S0_SYS_TIMER 0
`define S1_UART1     1
`define S2_LED       2
`define S3_SW        3
`define S4_SPI       4

`endif