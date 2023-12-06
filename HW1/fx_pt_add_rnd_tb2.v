`timescale 1ns / 100ps

/*
`ifndef  AIW
`define  AIW 2
`endif

`ifndef  AFW
`define  AFW 10
`endif

`ifndef  BIW
`define  BIW 4
`endif

`ifndef  BFW
`define  BFW 8
`endif*/

`define SN  1
`define AIW  2
`define AFW  3
`define BIW  3
`define BFW  4
`define SFW  2
`define a_data  "../run/SN0/a0.dat"
`define b_data  "../run/SN0/b0.dat"
`define golden_data  "../run/SN0/golden0.dat"
`define data_n 10000
`ifndef  T_NUM
`define  T_NUM 10000
`endif



module fx_pt_add_unsgn_tb2;

parameter SN     = `SN                                ;
parameter AIW    = `AIW                               ;
parameter AFW    = `AFW                               ;
parameter BIW    = `BIW                               ;
parameter BFW    = `BFW                               ; 
parameter SIW    = ( (AIW>BIW)? AIW+2:BIW+2 )         ;
parameter SFW    = `SFW                               ;
parameter EXT_F1 = ( (AFW>BFW) ? AFW : BFW )          ;
parameter EXT_F2 = (SFW>=EXT_F1) ? SFW : EXT_F1; 
parameter SC     = ( (SN==0)? ((SFW>=EXT_F1)? 1:0):
                     (SN==1)? ((SFW>=EXT_F1)? 3:2):
                              ((SFW>=EXT_F1)? 5:4))   ;
parameter data_n = `data_n                            ; 
parameter a_data = `a_data                            ;
parameter b_data = `b_data                            ;
parameter golden_data = `golden_data                  ;
reg   [AIW+AFW-1:0]  a;
reg   [BIW+BFW-1:0]  b;
//output
wire  [SIW+SFW-1:0]  sum;

//
reg [SIW+SFW-1:0] sum_gold;   //test result
reg  [SIW+SFW-1:0] sum_gld;         // the correct result 

reg	[AIW+AFW-1:0]	ina_data	[0:data_n-1];
reg	[BIW+BFW-1:0]	inb_data	[0:data_n-1];

reg	[SIW+SFW-1:0]	out_data_gold	[0:data_n-1];

reg	[SIW+SFW-1:0]	out_data	[0:data_n-1];

`ifdef  FSDB
reg [data_n*8-1:0] fsdb_name;
`endif

//for test signal

integer err_count;

integer i;

initial 
begin // initial pattern and expected result
   	$readmemb(`a_data, ina_data);
    $readmemb(`b_data, inb_data);
    $readmemb(`golden_data, out_data_gold);
end


//assign random input values to cra_8bits

initial
begin

  err_count=0; 

  for(i=0; i<data_n-1; i=i+1)
     begin         
         a=ina_data[i];

         b=inb_data[i];

         #10 
         out_data[i] = sum;
         sum_gld = out_data_gold[i];

       /*  `ifdef  MSG
         $display ($time, " a=%d b=%d sum_gld=%d sum=%d\n", 
                            a, b, sum_gld, sum);
        `endif*/
         
         if (sum_gld!==sum)
         begin
             err_count=err_count+1;
         $display($time, " a=%b b=%b sum_gld=%b sum=%b\n", 
                            a, b, sum_gld, sum);
         end
      end

  #10 
  $display(" ");
  $display("-------------------------------------------------------\n");
  $display("--------------------- S U M M A R Y -------------------\n");
  $display("AIW=%2d, AFW=%2d, BIW=%2d, BFW=%2d, SFW=%2d\n", 
            AIW, AFW, BIW, BFW, SFW);
  if(err_count==0)
       $display("Congratulations! The results are all PASSED!!\n");
  else
       $display("FAIL!!!  There are %d errors! \n", err_count);
	  
  $display("-------------------------------------------------------\n"); 
  
  $writememb("../run/out_data.txt", out_data);

  #10 $finish;       

end

`ifdef  FSDB
initial
begin
  $sformat(fsdb_name,"fx_pt_add_rnd_tb2_A_%02d_%02d_B_%02d_%02d_SFW_%02d.fsdb", 
                     AIW, AFW, BIW, BFW, SFW);   // something like sprintf in C
  $fsdbDumpfile(fsdb_name);  //your waveform file for nWave
  $fsdbDumpvars;
  $fsdbDumpMDA;
end
`endif

fx_pt_add_rnd #(.SN(SN),
                .AIW(AIW),
                .AFW(AFW),
                .BIW(BIW),
                .BFW(BFW),
                .SFW(SFW)
                )					 
                inst1(.a(a), 
                      .b(b), 
                      .sum(sum));


endmodule
