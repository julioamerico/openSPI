module spi_ip_tick_gen
(
	output tg_sck_o,
	output tg_tick_o,
	output tg_tick_launch_o,
	output tg_tick_capture_o,
  input [2:0] tg_clk_div_sel_i,
	input tg_enable_tick_i,
	input tg_enable_sck_i,
	input tg_enable_launch_capture_i,
	input tg_sck_pol_i,
	input tg_sck_pha_i,
  input tg_rst_n_i,
	input tg_clk_i
);

localparam CNT_WIDTH = 8;
localparam CNT_STAGE_WIDTH = 3;

wire clk_out;
wire clk_pol;

spi_ip_clk_div_arch3_gen
#(
	.PARAM_MAX_DIV         ( CNT_WIDTH       ),
	.PARAM_CNT_STAGE_WIDTH ( CNT_STAGE_WIDTH )
)
CLK_DIV
(
	.clkd_clk_out_o   ( clk_out          ),
	.clkd_time_base_o ( tg_tick_o        ),
	.clkd_clk_div_i   ( tg_clk_div_sel_i ), 
	.clkd_enable_i    ( tg_enable_tick_i ),
	.clkd_clk_i       ( tg_clk_i         ),
	.clkd_rst_n_i     ( tg_rst_n_i       )
);

//Configure sck phase and polarity
assign clk_pol = (tg_sck_pol_i ^ tg_sck_pha_i) ? clk_out : ~clk_out;
assign tg_sck_o = (tg_enable_sck_i) ? clk_pol : tg_sck_pol_i;

//Generate signals to signalize when there are positive and negative transitions 
// in the signal sck
assign tg_tick_launch_o  = tg_tick_o & ~clk_out & tg_enable_launch_capture_i;
assign tg_tick_capture_o = tg_tick_o &  clk_out & tg_enable_launch_capture_i;

endmodule
