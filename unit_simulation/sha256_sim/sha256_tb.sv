//************************************************************************
// Copyright (C) 2020 Massachusetts Institute of Technology
//
// File Name:      sha256_tb.sv
// Program:        Common Evaluation Platform (CEP)
// Description:    SHA256 Core unit testbench
// Notes:        
//
//************************************************************************

`timescale 1ns/1ns
//
// Name of the DUT
//
`define DUT_NAME sha256
//
// Stimulus/ExpectedData info
//
`define MAX_SAMPLES      (1698-15)
`define SAMPLE_WIDTH     ((4*2)+512+(4*2)+256)
`define OUTPUT_WIDTH     (1+1+256)
`define DATA_FILE        "SHA256_stimulus.csv"
//
// Some derived macros
//
`define TB_NAME(d) d``_tb
`define MKSTR(x) `"x`"
//
// Check and print if error
// Order of arguments MUST match sample order
//
// x=sample data
// i1=input#1, i2=input#2, etc..
// o1=output#1, o2=output#2, etc..
// j* = dont care input/output (used for HEX filler)
//
`define APPLY_N_CHECK(x,ji1,i1,ji2,i2,i3,jo1,o1,jo2,o2,o3) \
  {ji1,i1,ji2,i2,i3,jo1,exp_``o1,jo2,exp_``o2,exp_``o3}=x; \
  exp_pat={exp_``o1,exp_``o2,exp_``o3}; \
  act_pat={o1,o2,o3}; \
  if (exp_pat!=act_pat) begin \
     $display("ERROR: miscompared at sample#%0d",i); \
     if (errCnt==0) $display("  PAT={%s,%s,%s}", `"o1`",`"o2`",`"o3`"); \
     $display("  EXP=0x%x",exp_pat); \
     $display("  ACT=0x%x",act_pat); \
     errCnt++;\
  end

//
module `TB_NAME(`DUT_NAME) ; 
   //
   //
   //
   string dut_name_list [] = '{`MKSTR(`DUT_NAME)};
   reg [`SAMPLE_WIDTH-1:0] buffer[`MAX_SAMPLES-1:0];
   reg [`OUTPUT_WIDTH-1:0]  exp_pat, act_pat;
   //
   // IOs
   //
   reg 			    clk=0;
   reg 			    rst=1;
   reg 			    init=0;
   reg 			    next=0;
   reg [511 : 0] 	    block=0;
   wire 		    ready;
   wire 		    digest_valid;   
   wire [255 : 0] 	    digest;
   //
   // filler & expected output
   //
   reg 			    exp_ready;
   reg 			    exp_digest_valid;   
   reg [255 : 0] 	    exp_digest;

   reg [2:0] 		    ji1=0;
   reg [2:0] 		    ji2=0;
   reg [2:0] 		    jo1=0;
   reg [2:0] 		    jo2=0;   
   //
   int 		errCnt=0;
   //
   // Simple clock driving the DUT
   //
   initial begin
      forever #5 clk = !clk;
   end
   //
   // DUT instantiation
   //
   `DUT_NAME u1(.*);
   //
   // -------------------
   // Test starts here
   // -------------------   
   //
   initial begin
      //
      // do the unlocking or whatever here
      //

      //
      // pulse the DUT's reset and playback
      //
      playback_data();
      $finish;
   end
   //
   // Read data from file into buffer and playback for compare
   //
   task playback_data;
      int fp;
      int i;
      event err;
      begin
	 //
	 // Pulse the DUT's reset & drive input to zeros (known states)
	 //
	 {init,next,block}=0;
	 //
	 rst = 1;
	 repeat (5) @(posedge clk);
	 @(negedge clk);      // in stimulus, rst de-asserted after negedge
	 #2 rst = 0;
	 @(negedge clk);            
	 //
	 // open file for checking
	 //
	 $display("Reading %d samples from file %s",`MAX_SAMPLES,`DATA_FILE);
	 $readmemh(`DATA_FILE, buffer);
	 // now playback and check
	 for (i=0;i<`MAX_SAMPLES;i++) begin
	    // the order MUST match the samples' order
	    `APPLY_N_CHECK(buffer[i],ji1,init,ji2,next,block[511:0],jo1,ready,jo2,digest_valid,digest[255:0]);
	    @(negedge clk); // next sample	       
	 end // for (int i=0;i<`MAX_SAMPLES;i++)
	 //
	 // print summary
	 //
	 if (errCnt) begin
	    $display("==== DUT=%s TEST FAILED with %0d errors ====",dut_name_list[0],errCnt);
	 end
	 else begin
	    $display("==== DUT=%s TEST PASSED  ====",dut_name_list[0]);
	 end
      end
   endtask //   
   
endmodule // sha256_tb
