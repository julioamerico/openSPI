module spi_ip_clk_div_arch3
#(
	parameter PARAM_MAX_DIV = 8 // this parameter is the log2(.) of the bigger value of clock division . Ex.: clk_div = 64 => MAX_DIV = 5
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
 	  for (clogb2 = 0; value > 0; clogb2 = clogb2 + 1)
      value = value >> 1;
  end
endfunction

//Flip flops
reg [PARAM_MAX_DIV - 1 : 0] cnt_ff;

//Internal Signals
wire [PARAM_MAX_DIV - 1 : 0] cnt_trans;
wire [PARAM_MAX_DIV - 1 : 0] clk_div_dec;
wire clear_cnt;


//div_sel Decoder
assign clk_div_dec = {{PARAM_MAX_DIV - 1{1'b0}}, 1'b1} << clkd_clk_div_i;

//generate signal to clear cnt_ff
assign clkd_time_base_o = |(cnt_trans & clk_div_dec);

generate
	genvar k;

	for(k = 0; k < PARAM_MAX_DIV; k = k + 1)
		begin
			if(k == 0)
				assign cnt_trans[k] = 1'b1;
			else
				assign cnt_trans[k] = &cnt_ff[k - 1:0];
		end

endgenerate


always @(posedge clkd_clk_i)
	begin
		if(!clkd_rst_n_i)
			cnt_ff <= {PARAM_MAX_DIV{1'b0}};
		else
			begin
				if(!clkd_enable_i)
					cnt_ff <= {PARAM_MAX_DIV{1'b0}};
				else
					cnt_ff <= cnt_ff + 1'b1;
			end
	end

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