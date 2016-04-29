module spi_ip
(
  output spi_ip_ssout_o,
  output spi_data_serial_o,
  output spi_sck_o,
  output spi_txei_o,
  output spi_rxnei_o,
  output spi_erri_o,
  output [31:0] PRDATA,
  output PREADY,
  output PSLVERR,
  input [31:0] PWDATA,
  input [31:0] PADDR,
  input PSELx,
  input PENABLE,
  input PWRITE,
  input PRESETn,
  input PCLK,
  input spi_data_serial_i,
  input spi_clkin_in_i,
  input spi_ssin_i,
  input spi_rst_n_i,
  input spi_clk_i
);

wire busy_flag;
wire clear_crc_tx;
wire clear_crc_rx;
wire set_txe_flag;
wire set_rxne_flag;
wire ovr_flag;
wire crc_error_flag;
wire [15:0] rx_buffer;
wire [15:0] tx_buffer;
wire [1:0] sr_load_type;
wire [2:0] clk_div_sel;
wire sck_pol;
wire sck_pha;
wire [15:0] crc_poly;
wire clear_crc_error_flag;
wire rxne_flag;
wire spi_en;
wire tx_mode;
wire master_mode;
wire slave_mode;
wire txe_flag;
wire rx_mode;
wire tx_only;
wire crc_tx_flag;
wire crc_rx_flag;
wire ssm_sel;
wire ssin_sw;
wire [15:0] crc_tx_data;
wire [15:0] crc_rx_data;


spi_ip_host_interface HOST_INTERFACE
(
  .PRDATA                    ( PRDATA               ),
  .PREADY                    ( PREADY               ),
  .PSLVERR                   ( PSLVERR              ),
  .hi_tx_buffer_o            ( tx_buffer            ),
  .hi_crc_poly_o             ( crc_poly             ),
  .hi_rxne_flag_o            ( rxne_flag            ),
  .hi_txe_flag_o             ( txe_flag             ),
  .hi_crc_tx_flag_o          ( crc_tx_flag          ),
  .hi_crc_rx_flag_o          ( crc_rx_flag          ),
  .hi_cpha_o                 ( sck_pha              ),
  .hi_cpol_o                 ( sck_pol              ),
  .hi_master_mode_o          ( master_mode          ),
  .hi_slave_mode_o           ( slave_mode           ),
  .hi_clk_div_o              ( clk_div_sel          ),
  .hi_spi_en_o               ( spi_en               ),
  .hi_load_type_o            ( sr_load_type         ),
  .hi_ssin_o                 ( ssin_sw              ),
  .hi_ssm_o                  ( ssm_sel              ),
  .hi_tx_mode_o              ( tx_mode              ),
  .hi_rx_mode_o              ( rx_mode              ),
  .hi_tx_only_o              ( tx_only              ),
  .hi_txei_o                 ( spi_txei_o           ),
  .hi_rxnei_o                ( spi_rxnei_o          ),
  .hi_erri_o                 ( spi_erri_o           ),
  .hi_clear_crc_error_flag_o ( clear_crc_error_flag ),
  .hi_set_rxne_flag_i        ( set_rxne_flag        ),
  .hi_set_txe_flag_i         ( set_txe_flag         ),
  .hi_crc_error_flag_i       ( crc_error_flag       ),
  .hi_ovr_flag_i             ( ovr_flag             ),
  .hi_busy_flag_i            ( busy_flag            ),
  .hi_clear_crc_tx_flag_i    ( clear_crc_tx         ),
  .hi_clear_crc_rx_flag_i    ( clear_crc_rx         ),
  .hi_rx_buffer_i            ( rx_buffer            ),
  .hi_crc_tx_data_i          ( crc_tx_data          ),
  .hi_crc_rx_data_i          ( crc_rx_data          ),
  .PWDATA                    ( PWDATA               ),
  .PADDR                     ( PADDR                ),
  .PSELx                     ( PSELx                ),
  .PENABLE                   ( PENABLE              ),
  .PWRITE                    ( PWRITE               ),
  .PRESETn                   ( PRESETn              ),
  .PCLK                      ( PCLK                 ) 
);

assign ssin_in = (ssm_sel) ? ssin_sw: spi_ssin_i;

spi_ip_core CORE
(
  .cr_busy_o                 ( busy_flag            ),
  .cr_ssin_o                 ( spi_ip_ssout_o       ),
  .cr_clear_crc_tx_o         ( clear_crc_tx         ),
  .cr_clear_crc_rx_o         ( clear_crc_rx         ),
  .cr_data_serial_o          ( spi_data_serial_o    ),
  .cr_sck_o                  ( spi_sck_o            ),
  .cr_set_txe_flag_o         ( set_txe_flag         ),
  .cr_set_rxne_flag_o        ( set_rxne_flag        ),
  .cr_ovr_flag_o             ( ovr_flag             ),
  .cr_crc_error_flag_o       ( crc_error_flag       ),
  .cr_rx_buffer_o            ( rx_buffer            ),
  .cr_crc_tx_data_o          ( crc_tx_data          ),
  .cr_crc_rx_data_o          ( crc_rx_data          ),
  .cr_tx_buffer_i            ( tx_buffer            ),
  .cr_data_serial_i          ( spi_data_serial_i    ),
  .cr_sr_load_type_i         ( sr_load_type         ),
  .cr_clk_div_sel_i          ( clk_div_sel          ),
  .cr_sck_pol_i              ( sck_pol              ),
  .cr_sck_pha_i              ( sck_pha              ),
  .cr_crc_poly_i             ( crc_poly             ),
  .cr_clear_crc_error_flag_i ( clear_crc_error_flag ),
  .cr_rxne_flag_i            ( rxne_flag            ),
  .cr_clko_in_i              ( spi_clkin_in_i        ),
  .cr_spin_en_i              ( spi_en               ),
  .cr_tx_mode_i              ( tx_mode              ),
  .cr_master_mode_i          ( master_mode          ),
  .cr_slave_mode_i           ( slave_mode           ),
  .cr_txe_flag_i             ( txe_flag             ),
  .cr_rx_mode_i              ( rx_mode              ),
  .cr_tx_only_i              ( tx_only              ),
  .cr_crc_tx_flag_i          ( crc_tx_flag          ),
  .cr_crc_rx_flag_i          ( crc_rx_flag          ),
  .cr_ssin_i                 ( ssin_in              ),
  .cr_clk_i                  ( spi_clk_i            ),
  .cr_host_clk_i             ( PCLK                 ),
  .cr_host_rst_n_i           ( PRESETn              ),
  .cr_rst_n_i                ( spi_rst_n_i          )
);
endmodule
