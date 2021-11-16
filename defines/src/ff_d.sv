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

//`include "ff_macro.def"

`define ff_async(clk, myedge="negedge", rst, en, d, q)\
generate case(``myedge) \
   "posedge": begin\
      always_ff@(posedge ``clk or posedge ``rst) begin\
      if (``rst)\
         ``q<= '0;\
      else if(``en)\
         ``q<=``d;\
      end\
   end\
   "negedge": begin\
      always_ff@(posedge ``clk, negedge ``rst) begin\
         if (!``rst_n)\
            ``q <= '0;\
         else if(enb)\
            ``q <= ``d;\
      end\
   end\
endcase endgenerate

`ff_async(cclk, "negedge", rst_n, enb, d, q);

endmodule
