module fifo_wrapper 
//FIXME[DEV]: import your tb package if needed.
import fifo_pkg::*;
( 
//FIXME[DEV] adjust this port to your convenience
input bit wrclk,
input bit rdclk,
input bit arst_n,

input logic    push,
output logic 	full,
input data_t   data_in,
input logic    pop,
output logic   empty,
output data_t  data_out
);

fifo_if   itf();
always_comb begin
   //FIXME[DEV]: complete these assignations
   empty    = itf.empty ;
   full     = itf.full;
end


fifo_top uut(
	 .wr_clk(wrclk)
	,.wr_rst(arst_n)
	,.rd_clk(rdclk)
	,.rd_rst(arst_n)
   ,.itf (itf)
);

endmodule
