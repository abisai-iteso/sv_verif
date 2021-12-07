interface fifo_if(
);
import fifo_pkg::*;

// write process
push_e_t    push;
logic 	   full;
data_t      data_in;
// Read process
pop_e_t 	   pop;
logic 	   empty;
data_t      data_out;

modport fifo (
	input  push,
	output full,
	input  data_in,
	input  pop,
	output empty,
	output data_out
);

modport dvr (
	output   push,
	input    full,
	output   data_in,
	output   pop,
	input    empty,
	input    data_out
);


endinterface
