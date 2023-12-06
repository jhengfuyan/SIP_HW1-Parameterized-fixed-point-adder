module fx_pt_add_rnd(a,b,sum);

parameter SN = 1;
parameter AIW = 2; //A number integer width
parameter AFW = 5; //A number float point width
parameter BIW = 4; //B number integer width
parameter BFW = 6; //B number float point width
parameter SIW = (AIW > BIW) ? AIW + 2 :BIW + 2; //Sum integer width
parameter SFW = 3; //A+B float point width
//
input [AIW+AFW-1:0]a;
input [BIW+BFW-1:0]b;
output [SIW+SFW-1:0]sum;

reg [SIW+SFW-1:0]sum;

parameter EXT_F1 = (AFW>BFW) ? AFW : BFW; //bigger float  point
parameter EXT_F2 = (SFW>=EXT_F1) ? SFW : EXT_F1; 

//---SC odd = no round ，even = round
parameter SC = (SN == 0) ?  ((SFW>=EXT_F1) ? 1 : 0): // SN = 0 unsign 
               (SN == 1) ?  ((SFW>=EXT_F1) ? 3 : 2): // SN = 1 sign_2S
                            ((SFW>=EXT_F1) ? 5 : 4); // SN = 2 sign_mag
//--a,b,ext
wire [SIW+EXT_F2-1:0] a_ext , b_ext;

assign a_ext =  (SN == 1) ? {{(SIW - AIW ){a[AIW+AFW-1]}}, a , {(EXT_F2 - AFW){1'b0}}} : 
                (SN == 0) ? {{SIW{1'b0}}, a, {(EXT_F2 - AFW){1'b0}}} : {{a[AIW+AFW-1]},{(SIW-AIW){1'b0}}, a[AIW+AFW-2:0], {(EXT_F1- AFW){1'b0}}};
assign b_ext =  (SN == 1) ? {{(SIW - BIW ){b[BIW+BFW-1]}}, b, {(EXT_F2 - BFW){1'b0}}} :
                (SN == 0) ? {{SIW{1'b0}}, b, {(EXT_F2 - BFW){1'b0}}} : {{b[BIW+BFW-1]},{(SIW-BIW){1'b0}}, b[BIW+BFW-2:0], {(EXT_F1- BFW){1'b0}}};

//--sum temp
wire[SIW+EXT_F2-1:0]sum_tmp;
assign sum_tmp = a_ext + b_ext ;

//----
wire [1:0]sign_bit;
assign sign_bit = {a[AIW+AFW-1],b[BIW+BFW-1]};
//--sum_cdn
wire[SIW+EXT_F2-1:0]sum_cdn;
assign sum_cdn =  (sign_bit == 1 || sign_bit == 2) ? (a_ext[EXT_F2+SIW-2:0] < b_ext[EXT_F2+SIW-2:0]) ? {b[BIW+BFW-1],b_ext[EXT_F2+SIW-2:0] - a_ext[EXT_F2+SIW-2:0]} :
                                                     (a_ext[EXT_F2+SIW-2:0] > b_ext[EXT_F2+SIW-2:0]) ? {a[AIW+AFW-1],a_ext[EXT_F2+SIW-2:0] - b_ext[EXT_F2+SIW-2:0]} : 'd0 
                                                    :{a[AIW+AFW-1] ,a_ext[EXT_F2+SIW-2:0] + b_ext[EXT_F2+SIW-2:0]};
wire[SIW+EXT_F2-SFW-1:0]sum_temp;  
assign sum_temp = {sum_cdn[SIW+EXT_F2-1:EXT_F2-SFW]} + sum_cdn[EXT_F2-SFW - 1]; // round

generate
    case (SC)
        0: // SFW < AFW or BFW
        begin : unsign_cdn
            always@(*)
                begin 
                    sum = {sum_tmp[SIW+EXT_F2-1:EXT_F2-SFW]} + sum_tmp[EXT_F2-SFW - 1];
                end
        end
        1: 
        begin : unsign_cdn_SFW_max
            always@(*)
                begin 
                    sum = sum_tmp;
                end
        end
        2: 
        begin : sign_2S_cdn
            always@(*)
                begin 
                    if (sum_tmp[SIW+EXT_F1 - 1])
                        if(!sum_tmp[EXT_F2 -SFW -1])
                            sum = (sum_tmp >> (EXT_F2-SFW));
                        else if (sum_tmp[EXT_F2 - SFW - 1:0] == {1'b1,{(EXT_F2 - SFW - 1){1'b0}}})
                            sum = (sum_tmp >> (EXT_F2-SFW));
                        else
                            sum = (sum_tmp >> (EXT_F2-SFW)) + 1'b1;
                    else
                    sum = (sum_tmp >> (EXT_F2-SFW)) + (sum_tmp[EXT_F2 - SFW-1]);
                end
        end
        3: 
        begin : sign_2S_cdn_SFW_max
            always@(*)
                begin 
                    sum = sum_tmp;
                end
        end
        4: 
        begin : sign_mag_cdn
            always@(*)
                begin 
                    case (sign_bit)
                        01: 
                        begin 
                            sum = (sum_temp == {{1'b1},{(SIW+SFW-1){1'b0}}}) ? {(SIW + SFW){1'b0}} : sum_temp;
                    //$display($time,"a_ext=%b b_ext=%b sign_bit=%b sign_cdn=%b\n", a_ext, b_ext, sign_bit, sum_temp);
                        end
                        10: 
                        begin
                            sum = (sum_temp == {{1'b1},{(SIW+SFW-1){1'b0}}}) ? {(SIW + SFW){1'b0}} : sum_temp;
                    //$display($time,"a_ext=%b b_ext=%b sign_bit=%b sign_cdn=%b\n", a_ext, b_ext, sign_bit, sum_temp);
                        end
                        default: 
                        begin 
                            sum = (sum_temp == {{1'b1},{(SIW+SFW-1){1'b0}}}) ? {(SIW + SFW){1'b0}} : sum_temp;
                    //$display($time,"a_ext=%b b_ext=%b sign_bit=%b sign_cdn=%b \n", a_ext, b_ext, sign_bit, sum_temp);
                        end
                    endcase
                end
        end
        default:
        begin : sign_mag_cdn_SFW_max
            always@(*)
                begin
                    sum = (sum_temp == {{1'b1},{(SIW+SFW-1){1'b0}}}) ? {(SIW + SFW){1'b0}} : sum_temp;
                    //$display($time,"a_ext=%b b_ext=%b sign_bit=%b sign_cdn=%b \n", a_ext, b_ext, sign_bit ,sum_cdn);
                end
        end
    endcase
endgenerate
endmodule