module spi_ip_datapath
(
  output dp_data_serial_o,
  output dp_sr_data_ready_o,
  output dp_sck_o,
  output dp_tick_o,
  output dp_txe_flag_o,
  output dp_set_txe_flag_o,
  output dp_set_rxne_flag_o,
  output dp_ovr_flag_o,
  output dp_crc_tx_flag_o,
  output dp_clear_crc_tx_o,
  output dp_crc_rx_flag_o,
  output dp_clear_crc_rx_o,
  output dp_txe_valid_o,
  output reg dp_crc_error_flag_o,
  output reg [15 : 0] dp_rx_buffer_o,
  output [15:0] dp_crc_tx_data_o,
  output [15:0] dp_crc_rx_data_o,
  input [15 : 0] dp_tx_buffer_i,
  input dp_data_serial_i,
  input dp_sr_src_sel_i,
  input [1:0] dp_sr_load_type_i,
  input dp_sr_load_i,
  input dp_enable_launch_capture_i,
  input [2:0] dp_clk_div_sel_i,
  input dp_enable_tick_i,
  input dp_enable_sck_i,
  input dp_sck_pol_i,
  input dp_sck_pha_i,
  input dp_crc_tx_en_i,
  input dp_crc_rx_en_i,
  input [15:0] dp_crc_poly_i,
  input dp_clear_crc_error_flag_i,
  input dp_crc_init_i,
  input dp_txe_flag_in_i,
  input dp_set_txe_flag_i,
  input dp_rxne_flag_i,
  input dp_set_rxne_flag_i, 
  input dp_crc_tx_flag_i,
  input dp_clear_crc_tx_i,
  input dp_crc_rx_flag_i,
  input dp_clear_crc_rx_i,
  input dp_crc_error_en_i,
  input dp_clko_in_i,
  input dp_set_first_launch_i,
  input dp_slave_mode_i,
  input dp_slave_tick_en_i,
  input host_clk_i,
  input dp_clk_i,
  input host_rst_n_i,
  input dp_rst_n_i
);

localparam SR_SR_WIDTH = 16;
localparam CS_CRC_SIZE = SR_SR_WIDTH; 
localparam SRC_SEL_TX_BUFFER = 1'b1;

reg [1:0] ovr_flag_sync;
reg [1:0] clko_in_sync;
reg [1:0] clear_crc_error_flag_sync;
reg clko_edge_ff;
reg ovr_flag_ff;
reg crc_tx_enable_ff;

wire [SR_SR_WIDTH - 1 : 0] sr_data_out;
wire [SR_SR_WIDTH - 1 : 0] sr_data_load;
wire [CS_CRC_SIZE - 1 : 0] crc_tx_data;
wire [CS_CRC_SIZE - 1 : 0] crc_rx_data;
wire tick_master;
wire tick_slave;
wire tick_launch;
wire tick_capture;
wire tick_launch_master;
wire tick_capture_master;
wire tick_launch_slave;
wire tick_capture_slave;
wire crc_tx_enable;
wire crc_error_flag_in;
wire crc_rx_enable;
wire txe_flag;
wire rxne_flag;
wire rxne_valid;
wire set_ovr_flag;
wire ovr_flag;
wire rx_buffer_en;
wire clko_edge_fall;
wire clko_edge_rise;
wire clko_edge_in;
wire clko_edge_out;
wire crc_size;
wire crc_tx_flag;
wire crc_tx_valid;
wire crc_rx_flag;
wire crc_rx_valid;

//Mux para selecionar a origem do dado salvo no shift register
//Esse dado pode vir do tx _buffer ou do registro crc_tx
assign sr_data_load = (dp_sr_src_sel_i == SRC_SEL_TX_BUFFER) ? dp_tx_buffer_i : crc_tx_data;  

//Instância do bloco shift register
spi_ip_shift_register
#(
  .PARAM_SR_WIDTH ( SR_SR_WIDTH )
) 
SHIFT_REGISTER
(
  .sr_data_out_o              ( sr_data_out ),
  .sr_data_serial_o           ( dp_data_serial_o ),
  .sr_data_ready_o            ( dp_sr_data_ready_o ),
  .sr_data_load_i             ( sr_data_load),
  .sr_data_serial_i           ( dp_data_serial_i),
  .sr_load_type_i             ( dp_sr_load_type_i ),
  .sr_load_i                  ( dp_sr_load_i ),
  .sr_enable_launch_i         ( tick_launch ),
  .sr_enable_capture_i        ( tick_capture),
  .sr_enable_launch_capture_i ( dp_enable_launch_capture_i),
  .sr_rst_n_i                 ( dp_rst_n_i ),
  .sr_clk_i                   ( dp_clk_i )
);

spi_ip_tick_gen TICK_GEN
(
	.tg_sck_o          					    ( dp_sck_o ),
	.tg_tick_o         					    ( tick_master ),
	.tg_tick_launch_o  					    ( tick_launch_master ),
	.tg_tick_capture_o 					    ( tick_capture_master ),
	.tg_clk_div_sel_i  					    ( dp_clk_div_sel_i ),
	.tg_enable_tick_i  					    ( dp_enable_tick_i ),
	.tg_enable_sck_i   					    ( dp_enable_sck_i),
	.tg_enable_launch_capture_i ( dp_enable_launch_capture_i ),
	.tg_sck_pol_i      					    ( dp_sck_pol_i ),
	.tg_sck_pha_i      					    ( dp_sck_pha_i),
	.tg_rst_n_i        					    ( dp_rst_n_i),
	.tg_clk_i          					    ( dp_clk_i)
);

assign crc_tx_enable = tick_launch & dp_crc_tx_en_i;
assign dp_crc_tx_data_o = crc_tx_data;
assign crc_size = dp_sr_load_type_i[0];

always @(posedge dp_clk_i)
  begin
    if(!dp_rst_n_i)
      crc_tx_enable_ff <= 1'b0;
    else
      crc_tx_enable_ff <= crc_tx_enable;
  end
  
spi_ip_crc_serial CRC_TX
(
	.cs_crc_out_o    ( crc_tx_data      ),
	.cs_crc_in_i     ( dp_data_serial_o ),
	.cs_crc_enable_i ( crc_tx_enable_ff ),
	.cs_crc_init_i   ( dp_crc_init_i    ),
	.cs_crc_poly_i   ( dp_crc_poly_i    ),
	.cs_crc_size_i   ( crc_size         ),
	.cs_rst_n_i      ( dp_rst_n_i       ),
	.cs_clk_i        ( dp_clk_i         )
);

//Este sinal indica que há uma diferença entre o crc calculado e crc recebido
//Percebe que esse sinal é qualificado pelo sinal crc_error_en gerado na fsm que indica
//que há um crc válido no shift register
assign crc_error_flag_in = ( crc_rx_data != sr_data_out );

always @(posedge dp_clk_i)
  begin
    if(!dp_rst_n_i)
      clear_crc_error_flag_sync <= 2'b0;
    else
      clear_crc_error_flag_sync <= {clear_crc_error_flag_sync[0], dp_clear_crc_error_flag_i};
  end 
  
always @(posedge dp_clk_i)
  begin
    if(!dp_rst_n_i)
      dp_crc_error_flag_o <= 1'b0;
    else
      begin
        if(dp_crc_error_en_i)
          dp_crc_error_flag_o <= crc_error_flag_in;
        else
          if(clear_crc_error_flag_sync[1])
            dp_crc_error_flag_o <= 1'b0;
      end
  end
 
assign crc_rx_enable = tick_capture & dp_crc_rx_en_i;
assign dp_crc_rx_data_o = crc_rx_data;
  
spi_ip_crc_serial CRC_RX
(
	.cs_crc_out_o    ( crc_rx_data      ),
	.cs_crc_in_i     ( dp_data_serial_i ),
	.cs_crc_enable_i ( crc_rx_enable    ),
	.cs_crc_init_i   ( dp_crc_init_i    ),
	.cs_crc_poly_i   ( dp_crc_poly_i    ),
	.cs_crc_size_i   ( crc_size         ),
	.cs_rst_n_i      ( dp_rst_n_i       ),
	.cs_clk_i        ( dp_clk_i         )
);

assign dp_txe_flag_o = txe_flag | ~dp_txe_valid_o; 

spi_ip_flag_sync 
#(
  .PARAM_FLAG_RESET  ( 1        ),
  .PARAM_FLAG_VALID  ( "ENABLED" ),
  .PARAM_SYNC_STAGES ( 2        )
)TXE_FLAG_SYNC
(
  .fs_flag_out_clk_B_o     ( txe_flag          ),
  .fs_set_flag_out_clk_A_o ( dp_set_txe_flag_o ),
  .fs_flag_valid_clk_B_o   ( dp_txe_valid_o    ),
  .fs_flag_in_clk_A_i      ( dp_txe_flag_in_i  ),
  .fs_set_flag_in_clk_B_i  ( dp_set_txe_flag_i ),
  .fs_clk_A_i              ( host_clk_i        ),
  .fs_clk_B_i              ( dp_clk_i          ),
  .fs_rst_n_clk_A_i        ( host_rst_n_i      ),
  .fs_rst_n_clk_B_i        ( dp_rst_n_i        )
);

assign rx_buffer_en = dp_set_rxne_flag_i & ~ovr_flag;

assign set_ovr_flag = (dp_set_rxne_flag_i & ~rxne_valid            ) |
                      (dp_set_rxne_flag_i & rxne_valid & rxne_flag );
                      

assign ovr_flag = ovr_flag_ff | set_ovr_flag;
 
always @(posedge dp_clk_i)
  begin
    if(!dp_rst_n_i)
      ovr_flag_ff <= 1'b0;
    else
      begin
        if(set_ovr_flag)
          ovr_flag_ff <= 1'b1;
        else
          if(!rxne_flag)
            ovr_flag_ff <= 1'b0;
      end
  end
  
 always @(posedge host_clk_i)
  begin
    if(!host_rst_n_i)
      ovr_flag_sync <= 2'b00;
    else
      begin
        ovr_flag_sync[0] <= ovr_flag_ff;
        ovr_flag_sync[1] <= ovr_flag_sync[0];
      end
  end 

assign dp_ovr_flag_o = ovr_flag_sync[1];
  
always @(posedge dp_clk_i)
  begin
    if(!dp_rst_n_i)
      dp_rx_buffer_o <= {SR_SR_WIDTH{1'b0}};
    else
      begin
        if(rx_buffer_en)
          dp_rx_buffer_o <= sr_data_out;
      end
  end
  
spi_ip_flag_sync 
#(
  .PARAM_FLAG_RESET  ( 0        ),
  .PARAM_FLAG_VALID  ( "ENABLED" ),
  .PARAM_SYNC_STAGES ( 2        )
)RXNE_FLAG_SYNC
(
  .fs_flag_out_clk_B_o     ( rxne_flag          ),
  .fs_set_flag_out_clk_A_o ( dp_set_rxne_flag_o ),
  .fs_flag_valid_clk_B_o   ( rxne_valid         ),
  .fs_flag_in_clk_A_i      ( dp_rxne_flag_i     ),
  .fs_set_flag_in_clk_B_i  ( dp_set_rxne_flag_i ),
  .fs_clk_A_i              ( host_clk_i         ),
  .fs_clk_B_i              ( dp_clk_i           ),
  .fs_rst_n_clk_A_i        ( host_rst_n_i       ),
  .fs_rst_n_clk_B_i        ( dp_rst_n_i         )
);

assign dp_crc_tx_flag_o = crc_tx_flag;// & crc_tx_valid;

spi_ip_flag_sync 
#(
  .PARAM_FLAG_RESET  ( 0         ),
  .PARAM_FLAG_VALID  ( "DISABLED" ),
  .PARAM_SYNC_STAGES ( 2         )
)CRC_TX_FLAG_SYNC
(
  .fs_flag_out_clk_B_o     ( crc_tx_flag       ),
  .fs_set_flag_out_clk_A_o ( dp_clear_crc_tx_o ),
  .fs_flag_valid_clk_B_o   ( crc_tx_valid      ),
  .fs_flag_in_clk_A_i      ( dp_crc_tx_flag_i  ),
  .fs_set_flag_in_clk_B_i  ( dp_clear_crc_tx_i ),
  .fs_clk_A_i              ( host_clk_i        ),
  .fs_clk_B_i              ( dp_clk_i          ),
  .fs_rst_n_clk_A_i        ( host_rst_n_i      ),
  .fs_rst_n_clk_B_i        ( dp_rst_n_i        )
);

assign dp_crc_rx_flag_o = crc_rx_flag;// & crc_rx_valid;

spi_ip_flag_sync 
#(
  .PARAM_FLAG_RESET  ( 0         ),
  .PARAM_FLAG_VALID  ( "DISABLED" ),
  .PARAM_SYNC_STAGES ( 2         )
)CRC_RX_FLAG_SYNC
(
  .fs_flag_out_clk_B_o     ( crc_rx_flag       ),
  .fs_set_flag_out_clk_A_o ( dp_clear_crc_rx_o ),
  .fs_flag_valid_clk_B_o   ( crc_rx_valid      ),
  .fs_flag_in_clk_A_i      ( dp_crc_rx_flag_i  ),
  .fs_set_flag_in_clk_B_i  ( dp_clear_crc_rx_i ),
  .fs_clk_A_i              ( host_clk_i        ),
  .fs_clk_B_i              ( dp_clk_i          ),
  .fs_rst_n_clk_A_i        ( host_rst_n_i      ),
  .fs_rst_n_clk_B_i        ( dp_rst_n_i        )
);

always @(posedge dp_clk_i)
  begin
    if(!dp_rst_n_i)
      begin
        clko_in_sync <= 2'b00;
        clko_edge_ff <= 1'b0;
      end
    else
      begin
        clko_in_sync[0] <= dp_clko_in_i;
        clko_in_sync[1] <= clko_in_sync[0];
        clko_edge_ff <= clko_edge_in ;
      end
  end
  
assign clko_edge_in = clko_in_sync[1]; //& dp_slave_tick_en_i;
assign clko_edge_out = clko_edge_ff;

assign clko_edge_rise = (~clko_edge_out &  clko_edge_in) & dp_slave_tick_en_i;
assign clko_edge_fall = (clko_edge_out & ~clko_edge_in) & dp_slave_tick_en_i;

assign tick_slave = clko_edge_out ^ clko_edge_in & dp_slave_tick_en_i;
assign tick_launch_slave  = ((dp_sck_pol_i ^ dp_sck_pha_i) ? clko_edge_rise : clko_edge_fall) | dp_set_first_launch_i;
assign tick_capture_slave = (dp_sck_pol_i ^ dp_sck_pha_i) ? clko_edge_fall : clko_edge_rise;

assign dp_tick_o = (dp_slave_mode_i) ? tick_slave : tick_master;
assign tick_launch = (dp_slave_mode_i) ? tick_launch_slave : tick_launch_master;
assign tick_capture = (dp_slave_mode_i) ? tick_capture_slave : tick_capture_master;

endmodule
