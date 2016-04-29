module spi_ip_clk_div_arch3_gen
#(
	parameter PARAM_MAX_DIV = 8, // this parameter is the log2(.) of the bigger value of clock division . Ex.: clk_div = 64 => MAX_DIV = 5
	parameter PARAM_CNT_STAGE_WIDTH = 2 // width of sub-counters
)(
	//OUTPUTS
	output reg clkd_clk_out_o,                            //time base obtained by clock division
	output clkd_time_base_o,                              //Enable signal indicating when there is a transition in signal clkd_clk_out_o 
	input clkd_enable_i,                                  //enable clock division
	input [clogb2(PARAM_MAX_DIV) - 1 : 0] clkd_clk_div_i, //select clock divisor. Ex.: clk_div = 0 -> /2, clk_div = 1 -> /4 etc
	input clkd_rst_n_i,                                   //reset
	input clkd_clk_i                                      //clock
);

//Ceiling of the log-base 2 of a number
function integer clogb2;
  input [31:0] value;
  reg div2;
  begin
 	  for (clogb2 = 0; value > 1; clogb2 = clogb2 + 1)
      value = value >> 1;
  end
endfunction

//Number of sub-counters with PARAM_CNT_STAGE_WIDTH bits
localparam CNT_NUM_STAGE = (PARAM_MAX_DIV - 1) / PARAM_CNT_STAGE_WIDTH;

//If HAS_REST != 0, there is a counter with fewer bits than the sub-stage counter
localparam CNT_REST_WIDTH = (PARAM_MAX_DIV - 1) % PARAM_CNT_STAGE_WIDTH;
localparam HAS_REST = (CNT_REST_WIDTH != 0);

reg  [PARAM_CNT_STAGE_WIDTH - 1 : 0] cnt_ff[0 : CNT_NUM_STAGE - 1];
wire [PARAM_CNT_STAGE_WIDTH - 1 : 0] cnt_ff_trans_stage[0 : CNT_NUM_STAGE - 1];
wire [CNT_NUM_STAGE - 1 : 0] time_base_stage;
wire [CNT_NUM_STAGE - 1 : 0] enable_cnt_stage;
wire [PARAM_MAX_DIV - 1 : 0] clk_div_dec;
wire time_base_rest;

//div_sel Decoder
assign clk_div_dec = {{PARAM_MAX_DIV - 1{1'b0}}, 1'b1} << clkd_clk_div_i;

generate
  genvar k, i;
  for(k = 0; k < CNT_NUM_STAGE; k = k + 1)
    begin
      
      //Counter definition
      always @(posedge clkd_clk_i)
        begin
          if(!clkd_rst_n_i)
            cnt_ff[k] <= {PARAM_CNT_STAGE_WIDTH{1'b0}};
          else
            begin
              if(!clkd_enable_i)
                cnt_ff[k] <= {PARAM_CNT_STAGE_WIDTH{1'b0}};
              else
                if(enable_cnt_stage[k])
                  cnt_ff[k] <= cnt_ff[k] + 1'b1;
            end
        end
        
      for(i = 0; i < PARAM_CNT_STAGE_WIDTH; i = i + 1)
        begin
          assign cnt_ff_trans_stage[k][i] = &cnt_ff[k][i : 0];
        end
        
      if(k == 0)
        assign time_base_stage[k] = |( {cnt_ff_trans_stage[k], 1'b1} & clk_div_dec[PARAM_CNT_STAGE_WIDTH*k +: PARAM_CNT_STAGE_WIDTH + 1]);
      else  
        assign time_base_stage[k] = enable_cnt_stage[k] & (|( cnt_ff_trans_stage[k] & clk_div_dec[PARAM_CNT_STAGE_WIDTH*k + 1 +: PARAM_CNT_STAGE_WIDTH]));  
        
      if(k == 0)
        assign enable_cnt_stage[k] = 1'b1;
      else
        assign enable_cnt_stage[k] = enable_cnt_stage[k - 1] & cnt_ff_trans_stage[k - 1][PARAM_CNT_STAGE_WIDTH - 1];  
    end
endgenerate

generate
  genvar m;
  
  if(HAS_REST)
    begin
      reg  [CNT_REST_WIDTH - 1 : 0] cnt_rest_ff;
      wire [CNT_REST_WIDTH - 1 : 0] cnt_rest_ff_trans;
      wire enable_cnt_rest;
      
      always @(posedge clkd_clk_i)
        begin
          if(!clkd_rst_n_i)
            cnt_rest_ff <= {CNT_REST_WIDTH{1'b0}};
          else
            begin
              if(!clkd_enable_i)
                cnt_rest_ff <= {CNT_REST_WIDTH{1'b0}};
              else
                if(enable_cnt_rest)
                  cnt_rest_ff <= cnt_rest_ff + 1'b1;
            end
        end
      
      for(m = 0; m < CNT_REST_WIDTH; m = m + 1)
        begin
          assign cnt_rest_ff_trans[m] = &cnt_rest_ff[m : 0];
        end
        
      assign enable_cnt_rest = enable_cnt_stage[CNT_NUM_STAGE - 1] & cnt_ff_trans_stage[CNT_NUM_STAGE - 1][PARAM_CNT_STAGE_WIDTH - 1];  
      assign time_base_rest = enable_cnt_rest & (|( cnt_rest_ff_trans & clk_div_dec[PARAM_CNT_STAGE_WIDTH*CNT_NUM_STAGE + 1 +: CNT_REST_WIDTH])); 
    end
  else
    assign time_base_rest = 1'b0;
      
endgenerate
  
assign clkd_time_base_o = |{time_base_stage, time_base_rest};

always @(posedge clkd_clk_i) 
	begin
		if(!clkd_rst_n_i)
			clkd_clk_out_o <= 1'b0;
		else
			if(!clkd_enable_i)
				clkd_clk_out_o <= 1'b0;
			else
				if(clkd_time_base_o)
					clkd_clk_out_o <= ~clkd_clk_out_o;
	end
endmodule