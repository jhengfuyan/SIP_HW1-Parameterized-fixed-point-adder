`timescale  1ns / 100ps

`define SN  1
`define AIW  2
`define AFW  5
`define BIW  4
`define BFW  6
`define SFW  3


module fx_pt_add_rnd_tb1;
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

//input
reg   [AIW+AFW-1:0]  a;
reg   [BIW+BFW-1:0]  b;
//output
wire  [SIW+SFW-1:0]  sum;

//
reg [SIW+SFW-1:0] sum_gold;   //test result


integer err;
integer finish;

integer i;
integer seed1;
integer seed2;

reg signed [AIW+AFW:0] a_t_s; 
reg signed [BIW+BFW:0] b_t_s; 

reg  [AIW+AFW-1:0] a_n; 
reg  [BIW+BFW-1:0] b_n; 

reg  [SIW+SFW-1:0]  sum_p;
reg  [SIW+SFW-1:0]  sum_n;

real a_f, b_f, sum_f;
real a_t_f, b_t_f;
real a_deno_f, b_deno_f, sum_deno_f;
real sum_sfw_f, sum_45_f;

real sum_gold_s;

integer a_deno, b_deno, sum_deno;
 
///模組連接
fx_pt_add_rnd #(
    //parameter
    .SN       ( SN      ),
    .AIW      ( AIW     ),
    .AFW      ( AFW     ),
    .BIW      ( BIW     ),
    .BFW      (  BFW    ),
    .SIW      ( SIW     ),
    .SFW      ( SFW     ),
    .EXT_F1   ( EXT_F1  ),
    .EXT_F2   ( EXT_F2  ),
    .SC       ( SC      ))

    u_fx_pt_add_rnd (
    //input
    .a                    ( a   [AIW+AFW-1:0]    ),
    .b                    ( b   [BIW+BFW-1:0]    ),
    //output
    .sum                  ( sum [SIW+SFW-1:0]    ));


//
initial
begin
    #10
    $monitor("SN =%d AIW =%d AFW =%d  BIW =%d  BIW =%d  SIW =%d  SFW=%d  \n",SN,AIW,AFW,BIW,BFW,SIW,SFW); 
end

///initial 輸入
initial
begin

    err = 0;
    finish = 0;
    seed1 = 1;
    seed2 = 2;

    for( i = 0; i < 100000; i = i + 1)begin

        case(i)
            0: begin
                 a={(AIW+AFW){1'b1}};
                 b={(BIW+BFW){1'b1}};
               end
            1: begin
                 a={1'b0,{(AIW+AFW-1){1'b1}}};
                 b={1'b0,{(BIW+BFW-1){1'b1}}};
               end
            2: begin
                 a={1'b0,{(AIW+AFW-1){1'b1}}};
                 b={1'b1,{(BIW+BFW-1){1'b1}}};
               end
            3: begin
                 a={1'b1,{(AIW+AFW-1){1'b1}}};
                 b={1'b0,{(BIW+BFW-1){1'b1}}};
               end
            4: begin
                 a={1'b1,{(AIW+AFW-1){1'b0}}};
                 b={1'b0,{(BIW+BFW-1){1'b0}}};
               end
            5: begin
                 a={1'b1,{(AIW+AFW-1){1'b0}}};
                 b={1'b1,{(BIW+BFW-1){1'b0}}};
               end
            6: begin
                 a={1'b0,{(AIW+AFW-1){1'b0}}};
                 b={1'b0,{(BIW+BFW-1){1'b0}}};
               end
            7: begin
                 a={1'b0,{(AIW+AFW-1){1'b0}}};
                 b={1'b1,{(BIW+BFW-1){1'b0}}};
               end
            
            default:begin
                      a=$random(seed1);
                      b=$random(seed2);
	            end
       endcase


        //a = $random(seed1);
        //b = $random(seed2);
        //a = 7'b1101010;
        //b = 10'b1011000011;

            case (SN)
                0:begin // round
                    a_t_s = a;
                    b_t_s = b;

                    a_deno = 1 << (AFW); //1000
                    b_deno = 1 << (BFW); //10000
                    sum_deno = 1 << (SFW); //100

                    a_deno_f = a_deno;//8
                    b_deno_f = b_deno;//16
                    sum_deno_f = sum_deno;//4

                    a_t_f = a_t_s;//13
                    b_t_f = b_t_s;//89

                    a_f = a_t_f/a_deno_f;//13/8
                    b_f = b_t_f/b_deno_f;//89/16

                    sum_f = a_f + b_f;// 小數

                    sum_sfw_f = sum_f * sum_deno_f;  //  
                    sum_45_f = sum_sfw_f + 0.5; //
                    sum_gold = $floor(sum_45_f); 
                end
                1:begin
                    a_n = ~a;
                    b_n = ~b;

                    a_t_s = (a[AIW+AFW-1]==1) ? ( 0 - a_n - 1) : a;
                    b_t_s = (b[BIW+BFW-1]==1) ? ( 0 - b_n - 1) : b;

                    a_deno = 1 << (AFW);
                    b_deno = 1 << (BFW);
                    sum_deno = 1 << (SFW);

                    a_deno_f = a_deno;
                    b_deno_f = b_deno;
                    sum_deno_f = sum_deno;//

                    a_t_f = a_t_s;
                    b_t_f = b_t_s;

                    a_f = a_t_f/a_deno_f;   //111111.010100
                    b_f = b_t_f/b_deno_f;   //111011.000011

                    sum_f = a_f + b_f;      //111010.010111

                    sum_sfw_f = sum_f * sum_deno_f; //64 int

                    if(sum_sfw_f>=0)begin
                        sum_45_f = sum_sfw_f + 0.5;
                        sum_gold_s = $floor(sum_45_f);
                    end
                    else begin
                        sum_45_f = sum_sfw_f - 0.6;
                        sum_gold_s = $ceil(sum_45_f);
                    end

                    if(sum_gold_s>=0)begin
                        sum_gold = sum_gold_s;
                    end
                    else begin
                        sum_p = 0-sum_gold_s;
                        sum_n[SIW+SFW-1:0] = ~sum_p + 1;
                        sum_gold = {1'b1,sum_n};
                    end             
                end
                default: begin
                    a_t_s = (a[AIW+AFW-1]==1) ? ( 0 - a[AIW+AFW-2:0] ) : a;//(  a[AIW+AFW-2:0] );
                    b_t_s = (b[BIW+BFW-1]==1) ? ( 0 - b[BIW+BFW-2:0] ) : b;//(  b[BIW+BFW-2:0] );

                    a_deno = 1 << (AFW);
                    b_deno = 1 << (BFW);
                    sum_deno = 1 << (SFW);

                    a_deno_f = a_deno;
                    b_deno_f = b_deno;
                    sum_deno_f = sum_deno;//

                    a_t_f = a_t_s;
                    b_t_f = b_t_s;

                    a_f = a_t_f/a_deno_f;
                    b_f = b_t_f/b_deno_f;

                    sum_f = a_f + b_f;

                    sum_sfw_f = sum_f * sum_deno_f;
                    if(sum_sfw_f>=0)begin
                        sum_45_f = sum_sfw_f + 0.5;
                        sum_gold_s = $floor(sum_45_f);
                    end
                    else begin
                        sum_45_f = sum_sfw_f - 0.5;
                        sum_gold_s = $ceil(sum_45_f);
                    end

                    if(sum_gold_s>=0)begin
                        sum_gold = sum_gold_s;
                    end 
                    else begin
                        sum_gold[SIW+SFW-1] = 1'b1;
                        sum_gold[SIW+SFW-2:0] = (0-sum_gold_s);
                    end
                end
            endcase

        #10;
        if(sum !== sum_gold)
        begin
            err = err + 1 ;
            //
            $display($time,"a=%b b=%b sum=%b sum_gold=%b\n", a, b, sum, sum_gold); 
            //$display($time,"sum_gold=%b\n", sum_gold); 
            //$display($time,"sum_f=%f sum_gold_s=%f sum_sfw_f=%f sum_45_f=%f sum_g=%f sum_gold=%d sum=%d \n", sum_f, sum_gold_s, sum_sfw_f, sum_45_f, sum_g, sum_gold, sum);
            //$display($time,"a_t_s=%f b_t_s=%f \n", a_t_s,b_t_s ); 
            //$display($time,"a_t_f=%f b_t_f=%f \n", a_t_f,b_t_f ); 
            //$display($time,"a_f=%f b_f=%f  \n", a_f,b_f ); 
            //$display($time,"a_n=%d b_n=%d  \n", a_n,b_n ); 
            //$display($time,"sum_p=%d   \n", sum_p ); 
            //$display($time,"sum_n=%d   \n", sum_n ); 
            
        end    

    end


end

//finish
initial begin
    #1900000;
    finish = 1'd1;
end
//show
initial begin
    #2000000;
    if(finish !== 1)begin
        #10; $display("--------------------Error!! -------------------\n");
        #10; $display("      Your code cannot be finished!            \n");
        #10; $display("--------------------FAIL-----------------------\n");
    end
    else if(err !== 0)begin
        #10; $display("--------------------Error!! -------------------\n");
        #10; $display("      Something's wrong with your code!        \n");
        #10; $display("      There are %3d errors! \n               ",err);
        #10; $display("--------------------FAIL-----------------------\n");
    end
    else begin
        #10; $display("-----------------Congratulations!---------------\n");
        #10; $display("All data has been generated successfully!!!!!   \n");
        #10; $display("---------------PASS-------o̖⸜((̵̵́ ̆͒͟˚̩̭ ̆͒)̵̵̀)⸝o̗-----------\n");//o̖⸜((̵̵́ ̆͒͟˚̩̭ ̆͒)̵̵̀)⸝o̗ o̖⸜((̵̵́ ̆͒͟˚̩̭ ̆͒)̵̵̀)⸝o̗ o̖⸜((̵̵́ ̆͒͟˚̩̭ ̆͒)̵̵̀)⸝o̗
    end
    $finish;
end

initial
begin
    $fsdbDumpfile("fx_pt_add_rnd.fsdb");
    $fsdbDumpvars;
end


endmodule