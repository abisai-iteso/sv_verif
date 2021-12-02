module test;
// FIXME[add] Add something here to make the ifdef show each display 
// in different compilations.

`ifdef first_block
   `ifndef second_nest
      initial $display("first_block is defined");
   `else
      initial $display("first_block and second_nest defined");
   `endif
`elsif second_block
      initial $display("second_block defined, first_block is not");
`else
   `ifndef last_result
      initial $display("first_block, second_block,"," last_result not defined.");
   `elsif real_last
      initial $display("first_block, second_block not defined,"," last_result and real_last defined.");
   `else
      initial $display("Only last_result defined!");
   `endif
`endif
//TODO:
//1) Make that in ModelSim each message is shown in the console/transcript
//   by adding somethin in here
//2) Make that in ModelSim each message is shown in the console/transcript
//   by modifiying the run.do
endmodule
