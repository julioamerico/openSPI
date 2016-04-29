module tb_spi_i2s_ipi_clk_div();

localparam TB_PARAM_CNT_WIDTH = 8;
localparam TB_PARAM_CNT_STAGE_WIDTH = 3;

function integer clogb2;
  input [31:0] value;
  reg div2;
  begin
 	  for (clogb2 = 0; value > 0; clogb2 = clogb2 + 1)
      value = value >> 1;
  end
endfunction

wire clkd_clk_out_o;
wire clkd_time_base_o;
wire clkd_clk_out_o_2;
wire clkd_time_base_o_2;
wire clkd_clk_out_o_3;
wire clkd_time_base_o_3;

reg [clogb2(TB_PARAM_CNT_WIDTH) - 1 : 0] clkd_clk_div_sel_i;
reg clkd_enable_i;
reg clkd_clk;
reg clkd_rst_n;

integer i;

spi_ip_clk_div_arch3_gen 
#(
	.PARAM_MAX_DIV ( TB_PARAM_CNT_WIDTH ),
	.PARAM_CNT_STAGE_WIDTH (TB_PARAM_CNT_STAGE_WIDTH)
)
CLK_DIV_ARCH3
(
	.clkd_clk_out_o   ( clkd_clk_out_o_3    ),
	.clkd_time_base_o ( clkd_time_base_o_3  ),
	.clkd_clk_div_i   ( clkd_clk_div_sel_i  ), 
	.clkd_enable_i    ( clkd_enable_i       ),
	.clkd_clk_i       ( clkd_clk            ),
	.clkd_rst_n_i     ( clkd_rst_n          )
);

spi_ip_clk_div_arch2 
#(
	.PARAM_MAX_DIV ( TB_PARAM_CNT_WIDTH )
)
CLK_DIV_ARCH2
(
	.clkd_clk_out_o   ( clkd_clk_out_o_2    ),
	.clkd_time_base_o ( clkd_time_base_o_2  ),
	.clkd_clk_div_i   ( clkd_clk_div_sel_i  ), 
	.clkd_enable_i    ( clkd_enable_i       ),
	.clkd_clk_i       ( clkd_clk            ),
	.clkd_rst_n_i     ( clkd_rst_n          )
);

spi_ip_clk_div 
#(
	.PARAM_MAX_DIV ( TB_PARAM_CNT_WIDTH )
)
CLK_DIV
(
	.clkd_clk_out_o   ( clkd_clk_out_o    ),
	.clkd_time_base_o ( clkd_time_base_o  ),
	.clkd_clk_div_i   ( clkd_clk_div_sel_i), 
	.clkd_enable_i    ( clkd_enable_i     ),
	.clkd_clk_i       ( clkd_clk          ),
	.clkd_rst_n_i     ( clkd_rst_n        )
);

always @(posedge clkd_clk)
	begin
		if(
		    clkd_clk_out_o   != clkd_clk_out_o_2   || 
		    clkd_clk_out_o   != clkd_clk_out_o_3   ||
		    clkd_time_base_o != clkd_time_base_o_2 ||
		    clkd_time_base_o != clkd_time_base_o_3
		  )
			begin
			$display("Arquiteturas não compatíveis");	
			$stop;		
			end
	end

initial
	begin
		clkd_clk = 0;
		clkd_rst_n = 0;
		clkd_enable_i = 0;
		clkd_clk_div_sel_i = 0;
		@(posedge clkd_clk);
		@(posedge clkd_clk);
		clkd_rst_n = 1;
		clkd_enable_i = 1;

		for(i = 0; i < 8; i = i + 1)
			begin

				repeat(10*2**i)
					@(posedge clkd_clk);

				if(i != 0)
					@(posedge clkd_time_base_o);
				clkd_enable_i = 0;
			  clkd_clk_div_sel_i = i + 1;
			  @(posedge clkd_clk);
				clkd_enable_i = 1;

			end

		$display("OK! Arquiteturas Compatíveis :)");
		$stop;
	end

always #10
	clkd_clk = !clkd_clk;
endmodule
