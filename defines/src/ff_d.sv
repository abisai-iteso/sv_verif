// Coder:      Abisai Ramirez P
//Description: This module defines a flip-flop based on a macro.
//Date:        16 Nov 2021

module ff_d (
// clock
input bit      cclk,
// reset
input bit      rst_n, 
// Enable
input logic    enb, 
// Data to store
input logic    d,
// Stored data
output logic   q
);

`include "ff_macro.def"

`FF_D(cclk, "negedge", rst_n, enb, d, q);

endmodule
