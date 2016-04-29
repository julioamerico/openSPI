module tb_spi_ip_tick_gen();

localparam CLK_2   = 3'b000;
localparam CLK_4   = 3'b001;
localparam CLK_8   = 3'b010;
localparam CLK_16   = 3'b011;
localparam CLK_32  = 3'b100;
localparam CLK_64  = 3'b101;
localparam CLK_128  = 3'b110;
localparam CLK_256 = 3'b111;

reg clk;
reg rst_n;
reg sck_pha;
reg sck_pol;
reg enable_sck;
reg enable_tick;
reg [2:0] clk_div;

wire sck;
wire tick;
wire tick_launch;
wire tick_capture;

spi_ip_tick_gen TICK_GEN
(
	.tg_sck_o          					( sck          ),
	.tg_tick_o         					( tick         ),
	.tg_tick_launch_o  					( tick_launch  ),
	.tg_tick_capture_o 					( tick_capture ),
	.tg_clk_div_sel_i  					( clk_div      ),
	.tg_enable_tick_i  					( enable_tick  ),
	.tg_enable_sck_i   					( enable_sck   ),
	.tg_enable_launch_capture_i ( enable_tick   ),
	.tg_sck_pol_i      					( sck_pol      ),
	.tg_sck_pha_i      					( sck_pha      ),
	.tg_rst_n_i        					( rst_n        ),
	.tg_clk_i          					( clk          )
);

initial
	begin
		rst_n = 0;
		clk = 0;
		sck_pha = 0;
		sck_pol = 0;
		enable_sck = 0;
		enable_tick = 0;
		clk_div = 0;
		@(posedge clk);
		@(posedge clk);
		rst_n = 1;

    run_sck(0,0, CLK_2, 5);
    
    run_sck(0,0, CLK_4, 5);
    
    run_sck(0,1, CLK_2, 5);
    
    run_sck(1,0, CLK_2, 5);
        
    run_sck(1,1, CLK_2, 5);
		
		//enable_tick = 1;
		//@(posedge clk);
		//enable_sck = 1;
		
	end
task run_sck;
  input pol;
  input pha;
  input [2:0] div;
  input integer n;
  begin
  		sck_pha = pha;
		sck_pol = pol;
		clk_div = div;
		enable_tick = 1;
		repeat((2**div))
		  @(posedge clk);
		enable_sck = 1;
		repeat(n * (2**div))
      @(posedge clk);
    enable_sck = 0;
    enable_tick = 0;
    @(posedge clk);
  end
endtask
  
always #10
	clk = ~clk;

endmodule
