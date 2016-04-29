module spi_ip_core
(
  output cr_busy_o,//sincronizar
  output cr_ssin_o,
  output cr_clear_crc_tx_o,
  output cr_clear_crc_rx_o,
  output cr_data_serial_o,
  output cr_sck_o,
  output cr_set_txe_flag_o,
  output cr_set_rxne_flag_o,
  output cr_ovr_flag_o,
  output cr_crc_error_flag_o,
  output [15:0] cr_rx_buffer_o,
  output [15:0] cr_crc_tx_data_o,
  output [15:0] cr_crc_rx_data_o,
  input [15:0] cr_tx_buffer_i,
  input cr_data_serial_i, //sincronizar
  input [1:0] cr_sr_load_type_i,
  input [2:0] cr_clk_div_sel_i,
  input cr_sck_pol_i,
  input cr_sck_pha_i,
  input [15:0] cr_crc_poly_i,
  input cr_clear_crc_error_flag_i,
  input cr_rxne_flag_i,
  input cr_clko_in_i,
  input cr_spin_en_i,
  input cr_tx_mode_i,
  input cr_master_mode_i,
  input cr_slave_mode_i,
  input cr_txe_flag_i,
  input cr_rx_mode_i,
  input cr_tx_only_i,
  input cr_crc_tx_flag_i,
  input cr_crc_rx_flag_i,
  input cr_ssin_i,
  input cr_clk_i,
  input cr_host_clk_i,
  input cr_host_rst_n_i,
  input cr_rst_n_i
);

wire sr_src_sel;
wire load_sr;
wire set_txe_flag;
wire enable_tick;
wire launch_capture_en;
wire enable_sck;
wire set_rxne_flag;
wire clear_crc_tx;
wire clear_crc_rx;
wire crc_error_en;
wire set_first_launch;
wire txe_flag;
wire txe_valid;
wire tick;
wire data_ready;
wire crc_rx_flag;
wire crc_tx_flag;
wire enable_crc;
wire slave_tick_en;
wire crc_init;

spi_ip_datapath DATAPATH
(
  .dp_data_serial_o           ( cr_data_serial_o          ),
  .dp_sr_data_ready_o         ( data_ready                ),
  .dp_sck_o                   ( cr_sck_o                  ),
  .dp_tick_o                  ( tick                      ),
  .dp_txe_flag_o              ( txe_flag                  ),
  .dp_set_txe_flag_o          ( cr_set_txe_flag_o         ),
  .dp_set_rxne_flag_o         ( cr_set_rxne_flag_o        ),
  .dp_ovr_flag_o              ( cr_ovr_flag_o             ),
  .dp_crc_tx_flag_o           ( crc_tx_flag               ),
  .dp_clear_crc_tx_o          ( cr_clear_crc_tx_o         ),
  .dp_crc_rx_flag_o           ( crc_rx_flag               ),
  .dp_crc_rx_flag_i           ( cr_crc_rx_flag_i          ),
  .dp_clear_crc_rx_o          ( cr_clear_crc_rx_o         ),
  .dp_crc_error_flag_o        ( cr_crc_error_flag_o       ),
  .dp_rx_buffer_o             ( cr_rx_buffer_o            ),
  .dp_txe_valid_o             ( txe_valid                 ),
  .dp_crc_tx_data_o           ( cr_crc_tx_data_o          ),
  .dp_crc_rx_data_o           ( cr_crc_rx_data_o          ),
  .dp_tx_buffer_i             ( cr_tx_buffer_i            ),
  .dp_data_serial_i           ( cr_data_serial_i          ),
  .dp_sr_src_sel_i            ( sr_src_sel                ),
  .dp_sr_load_type_i          ( cr_sr_load_type_i         ),
  .dp_sr_load_i               ( load_sr                   ),
  .dp_enable_launch_capture_i ( launch_capture_en         ),
  .dp_clk_div_sel_i           ( cr_clk_div_sel_i          ),
  .dp_enable_tick_i           ( enable_tick               ),
  .dp_enable_sck_i            ( enable_sck                ),
  .dp_sck_pol_i               ( cr_sck_pol_i              ),
  .dp_sck_pha_i               ( cr_sck_pha_i              ),
  .dp_crc_tx_en_i             ( enable_crc                ),
  .dp_crc_rx_en_i             ( enable_crc                ),
  .dp_crc_poly_i              ( cr_crc_poly_i             ),
  .dp_clear_crc_error_flag_i  ( cr_clear_crc_error_flag_i ),
  .dp_crc_init_i              ( crc_init                  ),
  .dp_txe_flag_in_i           ( cr_txe_flag_i             ),
  .dp_set_txe_flag_i          ( set_txe_flag              ),
  .dp_rxne_flag_i             ( cr_rxne_flag_i            ),
  .dp_set_rxne_flag_i         ( set_rxne_flag             ), 
  .dp_crc_tx_flag_i           ( cr_crc_tx_flag_i          ),
  .dp_clear_crc_tx_i          ( clear_crc_tx              ),
  .dp_clear_crc_rx_i          ( clear_crc_rx              ),
  .dp_crc_error_en_i          ( crc_error_en              ),
  .dp_clko_in_i               ( cr_clko_in_i              ),
  .dp_set_first_launch_i      ( set_first_launch          ),
  .dp_slave_mode_i            ( cr_slave_mode_i           ),
  .dp_slave_tick_en_i         ( slave_tick_en             ),
  .host_clk_i                 ( cr_host_clk_i             ),
  .dp_clk_i                   ( cr_clk_i                  ),
  .host_rst_n_i               ( cr_host_rst_n_i           ),
  .dp_rst_n_i                 ( cr_rst_n_i                )
);

spi_ip_control_unit CONTROL_UNT
(
  .cnt_busy_o                 ( cr_busy_o         ),
  .cnt_sr_src_sel_o           ( sr_src_sel        ),
  .cnt_load_sr_o              ( load_sr           ),
  .cnt_set_txe_flag_o         ( set_txe_flag      ),
  .cnt_enable_tick_o          ( enable_tick       ),
  .cnt_ssin_o                 ( cr_ssin_o         ),
  .cnt_enable_lauch_capture_o ( launch_capture_en ),
  .cnt_enable_sck_o           ( enable_sck        ),
  .cnt_set_rxne_flag_o        ( set_rxne_flag     ),
  .cnt_clear_crc_tx_o         ( clear_crc_tx      ),
  .cnt_clear_crc_rx_o         ( clear_crc_rx      ),
  .cnt_crc_error_en_o         ( crc_error_en      ), 
  .cnt_crc_init_o             ( crc_init          ),
  .cnt_set_first_launch_o     ( set_first_launch  ),
  .cnt_enable_crc_o           ( enable_crc        ),
  .cnt_slave_tick_en_i        ( slave_tick_en     ),
  .cnt_spi_en_i               ( cr_spin_en_i      ),
  .cnt_tx_mode_i              ( cr_tx_mode_i      ),
  .cnt_master_mode_i          ( cr_master_mode_i  ),
  .cnt_slave_mode_i           ( cr_slave_mode_i   ),
  .cnt_txe_flag_i             ( txe_flag          ),
  .cnt_txe_valid_i            ( txe_valid         ),
  .cnt_tick_i                 ( tick              ),
  .cnt_data_ready_i           ( data_ready        ),
  .cnt_rx_mode_i              ( cr_rx_mode_i      ),
  .cnt_crc_tx_flag_i          ( crc_tx_flag       ),
  .cnt_tx_only_i              ( cr_tx_only_i      ),
  .cnt_crc_rx_flag_i          ( crc_rx_flag       ),
  .cnt_ssin_i                 ( cr_ssin_i         ),
  .cnt_clk_i                  ( cr_clk_i          ),
  .cnt_rst_n_i                ( cr_rst_n_i        )
);
endmodule
