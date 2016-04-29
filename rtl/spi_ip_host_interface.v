module spi_ip_host_interface
(
  output [31:0] PRDATA,
  output PREADY,
  output PSLVERR,
  output [15:0] hi_tx_buffer_o,
  output [15:0] hi_crc_poly_o,
  output hi_rxne_flag_o,
  output hi_txe_flag_o,
  output hi_crc_tx_flag_o,
  output hi_crc_rx_flag_o,
  output hi_cpha_o,
  output hi_cpol_o,
  output hi_master_mode_o,
  output hi_slave_mode_o,
  output [2:0] hi_clk_div_o,
  output hi_spi_en_o,
  output [1:0] hi_load_type_o,
  output hi_ssin_o,
  output hi_ssm_o,
  output hi_tx_mode_o,
  output hi_rx_mode_o,
  output hi_tx_only_o,
  output hi_txei_o,
  output hi_rxnei_o,
  output hi_erri_o,
  output hi_set_rxne_flag_i,
  output hi_clear_crc_error_flag_o,
  input hi_set_txe_flag_i,
  input hi_crc_error_flag_i,
  input hi_ovr_flag_i,
  input hi_busy_flag_i,
  input hi_clear_crc_tx_flag_i,
  input hi_clear_crc_rx_flag_i,
  input [15:0] hi_rx_buffer_i,
  input [15:0] hi_crc_tx_data_i,
  input [15:0] hi_crc_rx_data_i,
  input [31:0] PWDATA,
  input [31:0] PADDR,
  input PSELx,
  input PENABLE,
  input PWRITE,
  input PRESETn,
  input PCLK
);
//SPI Register Map
localparam SPI_CR1    = 3'd0;
localparam SPI_CR2    = 3'd1;
localparam SPI_SR     = 3'd2;
localparam SPI_DR     = 3'd3;
localparam SPI_CRCPR  = 3'd4;
localparam SPI_RXCRCR = 3'd5;
localparam SPI_TXCRCR = 3'd6;
localparam SPI_DRCRCR = 3'd7;

//Reset Values
localparam SPI_CR1_RESET = 32'd0;
localparam SPI_CR2_RESET = 32'd0;
localparam RESET_CRC_POLY = 16'h0007;

reg [32:0] bus_out_reg;
reg [15:0] crc_poly;
reg [15:0] tx_buffer;
reg [13:0] spi_cr1_reg;
reg [2:0] spi_cr2_reg;
reg [1:0] crc_error_flag_sync;
reg [1:0] ovr_flag_sync;
reg [1:0] busy_flag_sync;
reg spi_rxne_flag;
reg spi_txe_flag;
reg crc_tx_flag;
reg crc_rx_flag;
reg crc_error_edge;
reg spi_en_ff;

wire [2:0] apb_addr;
wire apb_write_en;
wire apb_read_en;
wire spi_cr1_sel;
wire spi_cr2_sel;
wire spi_sr_sel;
wire spi_cr_sel;
wire spi_crcpr_sel;
wire spi_rxcrcr_sel;
wire spi_txcrcr_sel;
wire crc_error_flag;
wire ovr_flag;
wire busy_flag;
wire txei_en;
wire rxnei_en;
wire erri_en;
wire [32:0] bus_out_mux;
wire [4:0] spi_sr_reg;

assign apb_write_en = PENABLE & PSELx & PWRITE;
assign apb_read_en = PSELx & ~PWRITE;
assign apb_addr = PADDR[4:2];

assign spi_cr1_sel     = (apb_addr == SPI_CR1); 
assign spi_cr2_sel     = (apb_addr == SPI_CR2);
assign spi_sr_sel      = (apb_addr == SPI_SR);
assign spi_dr_sel      = (apb_addr == SPI_DR);
assign spi_crcpr_sel   = (apb_addr == SPI_CRCPR);
assign spi_rxcrcr_sel  = (apb_addr == SPI_RXCRCR);
assign spi_txcrcr_sel  = (apb_addr == SPI_TXCRCR);
assign spi_drcrcr_sel  = (apb_addr == SPI_DRCRCR);

assign spi_cr1_wr_en = spi_cr1_sel & apb_write_en;
assign spi_cr2_wr_en = spi_cr2_sel & apb_write_en;
assign spi_sr_wr_en = spi_sr_sel & apb_write_en;
assign spi_dr_wr_en = (spi_dr_sel | spi_drcrcr_sel) & apb_write_en;
assign spi_crcpr_wr_en = spi_crcpr_sel & apb_write_en;
//assign spi_rxcrcr_wr_en = ;
//assign spi_txcrcr_wr_en = ;

assign hi_cpha_o = spi_cr1_reg[0];
assign hi_cpol_o = spi_cr1_reg[1];
assign hi_master_mode_o = spi_cr1_reg[2];
assign hi_slave_mode_o = ~hi_master_mode_o;
assign hi_clk_div_o = spi_cr1_reg[5:3];
assign hi_spi_en_o = spi_en_ff;//spi_cr1_reg[6];
assign hi_load_type_o = {spi_cr1_reg[7], spi_cr1_reg[11]};
assign hi_ssin_o = spi_cr1_reg[8];
assign hi_ssm_o = spi_cr1_reg[9];
assign hi_tx_mode_o = (~spi_cr1_reg[13] & ~spi_cr1_reg[10]) | (spi_cr1_reg[13] & spi_cr1_reg[12]);
assign hi_rx_mode_o = ~(spi_cr1_reg[13] & spi_cr1_reg[12]);
assign hi_tx_only_o = (spi_cr1_reg[13] & spi_cr1_reg[12]);

always @(posedge PCLK)
  begin
    if(!PRESETn)
      spi_cr1_reg <= SPI_CR1_RESET;
    else
      if(spi_cr1_wr_en)
        spi_cr1_reg <= PWDATA[13:0];
  end

//Flop para atrasar chegada do spi_en
//isso dá um ciclo de clock para que os sinais de configuração
//se estabilizem  
always @(posedge PCLK)
  begin
    if(!PRESETn)
      spi_en_ff <= 1'b0;
    else
      spi_en_ff <= spi_cr1_reg[6];
  end
 
 assign txei_en  = spi_cr2_reg[2]; 
 assign rxnei_en = spi_cr2_reg[1];
 assign erri_en  = spi_cr2_reg[0];
 
always @(posedge PCLK)
  begin
    if(!PRESETn)
      spi_cr2_reg <= SPI_CR2_RESET;
    else
      if(spi_cr2_wr_en)
        spi_cr2_reg <= PWDATA[2:0];
  end
 
assign clear_rxne_flag = (spi_dr_sel | spi_drcrcr_sel) & apb_read_en;
assign hi_rxne_flag_o = spi_rxne_flag;

assign hi_rxnei_o = hi_set_rxne_flag_i & rxnei_en;

 always @(posedge PCLK)
  begin
    if(!PRESETn)
      spi_rxne_flag <= 1'b0;
    else
      if(hi_set_rxne_flag_i)
         spi_rxne_flag <= 1'b1;
      else
        if(clear_rxne_flag)
           spi_rxne_flag <= 1'b0;
  end 
 
assign clear_txe_flag = spi_dr_wr_en;
assign hi_txe_flag_o = spi_txe_flag;
assign txe_flag = spi_txe_flag & ~hi_crc_tx_flag_o;

assign hi_txei_o = hi_set_txe_flag_i & txei_en;

always @(posedge PCLK)
  begin
    if(!PRESETn)
      spi_txe_flag <= 1'b1;
    else
      if(hi_set_txe_flag_i)
         spi_txe_flag <= 1'b1;
      else
        if(clear_txe_flag)
           spi_txe_flag <= 1'b0;
  end 
  
assign crc_error_flag = crc_error_flag_sync[1];
assign hi_clear_crc_error_flag_o = spi_sr_wr_en & ~PWDATA[2];

assign hi_erri_o = crc_error_flag_sync[1] & ~crc_error_edge;

always @(posedge PCLK)
  begin
    if(!PRESETn)
      begin
        crc_error_flag_sync <= 2'b0;
        crc_error_edge <= 1'b0;
      end
    else
      begin
        crc_error_flag_sync <= {crc_error_flag_sync[0], hi_crc_error_flag_i};
        crc_error_edge <= crc_error_flag_sync[1];
      end
  end  


assign ovr_flag = hi_ovr_flag_i;

//assign ovr_flag = ovr_flag_sync[1];
/*
 always @(posedge PCLK)
  begin
    if(!PRESETn)
      ovr_flag_sync <= 2'b0;
    else
      ovr_flag_sync <= {ovr_flag_sync[0], hi_ovr_flag_i};
  end 
*/
assign busy_flag = busy_flag_sync[1];
 
 always @(posedge PCLK)
  begin
    if(!PRESETn)
      busy_flag_sync <= 2'b0;
    else
      busy_flag_sync <= {busy_flag_sync[0], hi_busy_flag_i};
  end   

assign spi_sr_reg = {busy_flag, ovr_flag, crc_error_flag, txe_flag, hi_rxne_flag_o};  

assign hi_tx_buffer_o = tx_buffer;

always @(posedge PCLK)
  begin
    if(!PRESETn)
      tx_buffer <= 16'd0;
    else
      if(spi_dr_wr_en)
        tx_buffer <= PWDATA[15:0];
  end

assign hi_crc_poly_o = crc_poly;

always @(posedge PCLK)
  begin
    if(!PRESETn)
      crc_poly <= RESET_CRC_POLY;
    else
      if(spi_crcpr_wr_en)
        crc_poly <= PWDATA[15:0];
  end

assign hi_crc_tx_flag_o = crc_tx_flag;

always @(posedge PCLK)
  begin
    if(!PRESETn)
      crc_tx_flag <= 1'b0;
    else
      if(spi_dr_wr_en && spi_drcrcr_sel)
        crc_tx_flag <= 1'b1;
      else
        if(hi_clear_crc_tx_flag_i)
          crc_tx_flag <= 1'b0;
  end 
 
 assign hi_crc_rx_flag_o = crc_rx_flag;

always @(posedge PCLK)
  begin
    if(!PRESETn)
      crc_rx_flag <= 1'b0;
    else
      if(apb_read_en && spi_drcrcr_sel)
        crc_rx_flag <= 1'b1;
      else
        if(hi_clear_crc_rx_flag_i)
          crc_rx_flag <= 1'b0;
  end
   
 assign bus_out_mux = ({32{spi_cr1_sel   }} & {18'b0, spi_cr1_reg}     ) |
                      ({32{spi_cr2_sel   }} & {29'b0, spi_cr2_reg}     ) |
                      ({32{spi_sr_sel    }} & {27'b0, spi_sr_reg }     ) |
                      ({32{spi_dr_sel    }} & {16'b0, hi_rx_buffer_i}  ) |
                      ({32{spi_crcpr_sel }} & {16'b0, crc_poly}        ) |
                      ({32{spi_txcrcr_sel}} & {16'b0, hi_crc_tx_data_i}) |
                      ({32{spi_rxcrcr_sel}} & {16'b0, hi_crc_rx_data_i}) ;

always @(posedge PCLK)
  begin
    if(!PRESETn)
      bus_out_reg <= 32'b0;
    else
      if(apb_read_en)
        bus_out_reg <= bus_out_mux;
  end
  
assign PRDATA = bus_out_reg;   
assign PREADY = 1'b1;
assign PSLVERR = 1'b0;
                 
endmodule
