`line 1 "fifo_top.sv" 1
//FIFO Top_Module
module fifo_top
import fifo_pkg::*;
(
	input bit 	      wr_clk,
	input bit         wr_rst,
	input bit         rd_clk,
	input bit         rd_rst,
   fifo_if.fifo      itf
);


logic [W_ADDR:0] rptr_r2w_1, rptr_r2w_2, wq2_rptr;
logic [W_ADDR-1:0] ram_w_addr;

logic [W_ADDR:0] wptr_w2r_1, wptr_w2r_2, rq2_wptr;
logic [W_ADDR-1:0] ram_r_addr;

FIFO_sdp_dc_ram_if ram();

FIFO_sdp_dc_ram memory
(
	.clk_a(wr_clk),
	.clk_b(rd_clk),
	.mem_if(ram.mem)
);

//sync r2w
FIFO_sync_module sync_r2w_1
(
	.clk(wr_clk),
	.rst(wr_rst),
	.enb(ENB),
	.inp(rptr_r2w_1),
	.out(rptr_r2w_2) 
);

FIFO_sync_module sync_r2w_2
(
	.clk(wr_clk),
	.rst(wr_rst),
	.enb(ENB),
	.inp(rptr_r2w_2),
	.out(wq2_rptr) 
);

FIFO_write_Module write_control
(
	.wr_clk(wr_clk),
	.wr_rst(wr_rst),
	.push(push),
	.rptr(wq2_rptr),
	.wptr(wptr_w2r_1),
	.address(ram_w_addr),
	.full(full)
);

//sync w2r
FIFO_sync_module sync_w2r_1
(
	.clk(rd_clk),
	.rst(rd_rst),
	.enb(ENB),
	.inp(wptr_w2r_1),
	.out(wptr_w2r_2) 
);

FIFO_sync_module sync_w2r_2
(
	.clk(rd_clk),
	.rst(rd_rst),
	.enb(ENB),
	.inp(wptr_w2r_2),
	.out(rq2_wptr) 
);

FIFO_read_Module read_control
(
	.rd_clk(rd_clk),
	.rd_rst(rd_rst),
	.pop(itf.pop),
	.wptr(rq2_wptr),
	.rptr(rptr_r2w_1),
	.address(ram_r_addr),
	.empty(empty)
);

assign ram.we_a      = itf.full && itf.push;
assign ram.rd_b      = itf.empty && itf.pop;
assign ram.data_a    = (ram_w_addr == 5)?('hff):itf.data_in;
assign ram.wr_addr_a = ram_w_addr;
assign ram.rd_addr_b = ram_r_addr;
assign itf.data_out 	 = (ram_r_addr==4)? ('hbe):ram.rd_data_a;
endmodule





`line 111 "fifo_top.sv" 2
`line 1 "FIFO_gray_counter.sv" 1
// Gray counter
module FIFO_gray_counter
import fifo_pkg::*;
(
	input logic clk,
	input logic enable,
	input logic reset,
	output logic [ADDR_GRAY - 1 :0] gray_count,
	output logic [ADDR_GRAY - 1 :0] next_gray_count
);


// Implementation:

// There's an imaginary bit in the counter, at q[-1], that resets to 1
// (unlike the rest of the bits of the counter) and flips every clock cycle.
// The decision of whether to flip any non-imaginary bit in the counter
// depends solely on the bits below it, down to the imaginary bit.	It flips
// only if all these bits, taken together, match the pattern 10* (a one
// followed by any number of zeros).

// Almost every non-imaginary bit has a submodule instance that sets the
// bit based on the values of the lower-order bits, as described above.
// The rules have to differ slightly for the most significant bit or else 
// the counter would saturate at it's highest value, 1000...0.

	// q is the counter, plus the imaginary bit
	logic q [ADDR_GRAY-1:-1];
	
	// no_ones_below[x] = 1 iff there are no 1's in q below q[x]
	logic no_ones_below [ADDR_GRAY-1:-1];
	
	// q_msb is a modification to make the msb logic work
	logic q_msb;
	
	integer i, j, k;
	
	always_ff @ (negedge reset or negedge clk)
	begin
		if (~reset)
		begin
		
			// Resetting involves setting the imaginary bit to 1
			q[-1] <= 1;
			for (i = 0; i <= ADDR_GRAY-1; i = i + 1)begin
				q[i] <= 0;
				no_ones_below[i] <= 0;
			end
			gray_count  = '0;
			next_gray_count  = '0;
				
		end
		else if (enable)
		begin
			// Toggle the imaginary bit
			q[-1] <= ~q[-1];
			
			for (i = 0; i < ADDR_GRAY-1; i = i + 1)
			begin
				// Flip q[i] if lower bits are a 1 followed by all 0's
				q[i] <= q[i] ^ (q[i-1] & no_ones_below[i-1]);
			
			end
			
			q[ADDR_GRAY-1] <= q[ADDR_GRAY-1] ^ (q_msb & no_ones_below[ADDR_GRAY-2]);
			for (k = 0; k < ADDR_GRAY; k = k + 1)
				gray_count[k] <= q[k];
		end
	end
	
	
	always_ff @(*)
	begin	
		// There are never any 1's beneath the lowest bit
		no_ones_below[-1] <= 1;
		
		for (j = 0; j < ADDR_GRAY-1; j = j + 1)begin
			no_ones_below[j] <= no_ones_below[j-1] & ~q[j-1];
		end
		q_msb <= q[ADDR_GRAY-1] | q[ADDR_GRAY-2];
		
		// Copy over everything but the imaginary bit
		for (k = 0; k < ADDR_GRAY; k = k + 1)
			next_gray_count[k] <= q[k];
	end	
		
endmodule

`line 88 "FIFO_gray_counter.sv" 2
`line 1 "FIFO_read_Module.sv" 1
//FIFO read module


module FIFO_read_Module
import fifo_pkg::*;
(
	input rd_clk,
	input rd_rst,
	input logic pop,
	input logic [W_ADDR:0] wptr,
	output logic [W_ADDR:0] rptr,
	output logic [W_ADDR-1:0] address,
	output logic empty
);

logic [W_ADDR:0] rptr_next;
logic empty_aux;

FIFO_gray_counter gray_counter_read
(
	.clk(rd_clk),
	.enable(pop & ~empty_aux),
	.reset(rd_rst),
	.gray_count(rptr),
	.next_gray_count(rptr_next)
);

assign empty_aux = (wptr == rptr);
assign address = rptr[W_ADDR-1:0];

always_ff@(posedge rd_clk or negedge rd_rst) begin
    if(!rd_rst)
    begin
	    empty <= '1;
    end 
    else begin
	    empty <= empty_aux;
    end      
end

endmodule


`line 44 "FIFO_read_Module.sv" 2
`line 1 "FIFO_sdp_dc_ram_if.sv" 1
//Coder:          Abisai Ramirez Perez
//Date:           03/31/2019
//Name:           sp_dc_ ram_if.sv
//Description:    This is the interface of a dual-port dual-clock random access memory. 

 
     

interface FIFO_sdp_dc_ram_if ();
import fifo_pkg::*;

// Write enable signal
logic       we_a           ;   // Write enable
logic		rd_b           ;   // Read enable
data_t      data_a         ;   // data to be stored
data_t      rd_data_a      ;   // read data from memory
addr_t      wr_addr_a      ;   // Read write address
addr_t      rd_addr_b      ;   // Read write address

// Memory modport
modport mem (
input   we_a,
input   rd_b,
input   data_a,
input   wr_addr_a,
output  rd_data_a,
input   rd_addr_b
);

//Client modport
modport cln (
output  we_a,
output  rd_b,
output  data_a,
output  wr_addr_a,
input   rd_data_a,
output  rd_addr_b
);

endinterface



`line 44 "FIFO_sdp_dc_ram_if.sv" 2
`line 1 "FIFO_sdp_dc_ram.sv" 1
//Coder:          DSc Abisai Ramirez Perez
//Date:           03/31/2019
//Name:           sdp_dc_ram.sv
//Description:    This is the HDL of a single dual-port dual-clock random access memory. 


module FIFO_sdp_dc_ram 
import fifo_pkg::*;
(
// Core clock a
input  logic clk_a,
// Core clock b
input  logic clk_b,
// Memory interface
FIFO_sdp_dc_ram_if.mem mem_if
);

// Declare a RAM variable 
data_t  ram [W_DEPTH-1:0];

//Variable to hold the registered read adddres
data_t  addr_logic;

always_ff@(posedge clk_a) begin
    if(mem_if.we_a)
        ram[mem_if.wr_addr_a] <= mem_if.data_a;
end

always_ff@(posedge clk_b) begin
    if(mem_if.rd_b)
        mem_if.rd_data_a <= ram [mem_if.rd_addr_b];
end

endmodule
`line 35 "FIFO_sdp_dc_ram.sv" 2
`line 1 "FIFO_sync_module.sv" 1
//Sync Module


module FIFO_sync_module
import fifo_pkg::*;
(
input  clk,
input  rst,
input  enb,
input  logic [W_ADDR:0] inp,
output logic [W_ADDR:0] out 
);

logic [W_ADDR:0] sync_r;

always_ff@(posedge clk or negedge rst) begin
	if(!rst)
		sync_r <= '0;
	else if(enb)
		sync_r <= inp;
end

assign out = sync_r;

endmodule 

`line 27 "FIFO_sync_module.sv" 2

`line 1 "FIFO_write_Module.sv" 1
//Write Module


module FIFO_write_Module
import fifo_pkg::*;
(
	input wr_clk,
	input wr_rst,
	input logic push,
	input logic [W_ADDR:0] rptr,
	output logic [W_ADDR:0] wptr,
	output logic [W_ADDR-1:0] address,
	output logic full
);

logic [W_ADDR:0] wptr_next;
logic full_flag;

FIFO_gray_counter gray_counter_write
(
	.clk(wr_clk),
	.enable(push & ~full_flag),
	.reset(wr_rst),
	.gray_count(wptr),
	.next_gray_count(wptr_next)
);

assign	address = wptr[W_ADDR-1:0];
assign	full_flag = (wptr_next == {~rptr[W_ADDR:W_ADDR-1], rptr[W_ADDR-2:0]});

always_ff@(posedge wr_clk or negedge wr_rst) begin
    if(!wr_rst)
    begin
	    full <= '0;
    end 
    else begin
	    full <= full_flag;
    end      
end

endmodule


`line 44 "FIFO_write_Module.sv" 2
