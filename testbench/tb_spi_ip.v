module tb_spi_ip();

//SPI Register Map
localparam SPI_CR1    = 32'd0 << 2;
localparam SPI_CR2    = 32'd1 << 2;
localparam SPI_SR     = 32'd2 << 2;
localparam SPI_DR     = 32'd3 << 2;
localparam SPI_CRCPR  = 32'd4 << 2;
localparam SPI_RXCRCR = 32'd5 << 2;
localparam SPI_TXCRCR = 32'd6 << 2;
localparam SPI_DRCRCR = 32'd7 << 2;

localparam MASTER_MODE  = 32'h00000001 << 2;
localparam SLAVE_MODE   = 32'h00000000 << 2;
localparam SPI_ENABLE   = 32'h00000001 << 6;
localparam SPI_DISABLE  = 32'h00000000 << 6;
localparam LSB_FIRST    = 32'h00000001 << 7;
localparam MSB_FIRST    = 32'h00000000 << 7;
localparam RX_ONLY      = 32'h00000001 << 10;
localparam FRAME_16     = 32'h00000001 << 11;
localparam FRAME_8      = 32'h00000000 << 11;
localparam BIDI_MODE    = 32'h00000001 << 12;
localparam UNI_MODE     = 32'h00000000 << 12;
localparam TX_ONLY_MODE = 32'h00000001 << 13;
localparam CLK_DIV_2    = 32'h00000000 << 3;
localparam CLK_DIV_4    = 32'h00000001 << 3;
localparam CLK_DIV_8    = 32'h00000002 << 3;
localparam CLK_DIV_16   = 32'h00000003 << 3;
localparam CLK_DIV_32   = 32'h00000004 << 3;
localparam CLK_DIV_64   = 32'h00000005 << 3;
localparam CLK_DIV_128  = 32'h00000006 << 3;
localparam CLK_DIV_256  = 32'h00000007 << 3;

localparam RXNE_IE = 32'h00000001 << 1;

localparam PSEL_MASTER = 1'b1;  
localparam PSEL_SLAVE = 1'b0;

reg serial_in;
reg clk_in;
reg ssin;
reg rst_n;
reg clk;
reg [31:0] PWDATA;
reg [31:0] PADDR;
reg PCLK, PRESETn;
reg PSEL, PENABLE, PWRITE;

wire [31:0] PRDATA;
wire ssout;
wire serial_out;
wire sck_out;
wire int_txe;
wire int_rxne;
wire int_error;

reg master_clk;
reg slave_serial_in;
reg slave_clk_in;
reg slave_ssin;
reg slave_PSEL;

wire [31:0] slave_PRDATA;
wire slave_ssout;
wire slave_serial_out;
wire slave_sck_out;
wire slave_int_txe;
wire slave_int_rxne;
wire slave_int_error;

reg [15:0] data_write_master;
reg [15:0] data_write_master_2;
reg [15:0] data_write_slave;
reg [15:0] data_read_master;
reg [15:0] data_read_master_2;
reg [15:0] data_read_slave;
reg [15:0] golden;

integer error, error_chk;
integer i;

spi_ip SPI_IP
(
  .spi_ip_ssout_o   ( ssout      ),
  .spi_data_serial_o( serial_out ),
  .spi_sck_o        ( sck_out    ),
  .spi_txei_o       ( int_txe    ),
  .spi_rxnei_o      ( int_rxne   ),
  .spi_erri_o       ( int_error  ),
  .PRDATA           ( PRDATA     ),
  .PREADY           ( PREADY     ),
  .PSLVERR          ( PSLVERR    ),
  .PWDATA           ( PWDATA     ),
  .PADDR            ( PADDR      ),
  .PSELx            ( PSEL       ),
  .PENABLE          ( PENABLE    ),
  .PWRITE           ( PWRITE     ),
  .PRESETn          ( PRESETn    ),
  .PCLK             ( PCLK       ),
  .spi_data_serial_i( slave_serial_out  ),
  .spi_clkin_in_i   ( slave_sck_out ),
  .spi_ssin_i       ( ssin       ),
  .spi_rst_n_i      ( rst_n      ),
  .spi_clk_i        ( master_clk )
); 

spi_ip SPI_IP_SLAVE
(
  .spi_ip_ssout_o   ( slave_ssout      ),
  .spi_data_serial_o( slave_serial_out ),
  .spi_sck_o        ( slave_sck_out    ),
  .spi_txei_o       ( slave_int_txe    ),
  .spi_rxnei_o      ( slave_int_rxne   ),
  .spi_erri_o       ( slave_int_error  ),
  .PRDATA           ( slave_PRDATA     ),
  .PREADY           ( PREADY           ),
  .PSLVERR          ( PSLVERR          ),
  .PWDATA           ( PWDATA           ),
  .PADDR            ( PADDR            ),
  .PSELx            ( slave_PSEL       ),
  .PENABLE          ( PENABLE          ),
  .PWRITE           ( PWRITE           ),
  .PRESETn          ( PRESETn          ),
  .PCLK             ( PCLK             ),
  .spi_data_serial_i( serial_out       ),
  .spi_clkin_in_i   ( sck_out          ),
  .spi_ssin_i       ( ssout            ),
  .spi_rst_n_i      ( rst_n            ),
  .spi_clk_i        ( clk              )
); 

task reset;
	begin
	  serial_in = 1'b1;
	  clk = 0;
	  master_clk = 0;
	  rst_n = 0;
		PCLK = 0;
		PSEL = 0;
		slave_PSEL = 0;
		PENABLE = 0;
		PWDATA = 0;
		PWRITE = 0;
		PADDR = 0;
		PRESETn = 0;
		repeat(6) @(posedge PCLK);
		PRESETn = 1;
		rst_n = 1;
	end
endtask

task apb_write;
	input [31:0] addr;
	input [31:0] data_in;
	input psel;
	begin
		PSEL <= (psel == PSEL_MASTER);
		slave_PSEL <= (psel == PSEL_SLAVE);
		PWRITE <= 1;
		PENABLE <= 0;
		PADDR <= addr;
		PWDATA <= data_in;
		@(posedge PCLK);
		PENABLE <= 1;
		@(posedge PCLK);
		PSEL <= 0;
		slave_PSEL <= 0;
		PENABLE <= 0;
	end
endtask

task apb_read;
	input  [31:0] addr;
	output [31:0] data_out;
	input psel;
	begin
    PSEL <= (psel == PSEL_MASTER);
		slave_PSEL <= (psel == PSEL_SLAVE);
		PENABLE <= 0;
		PWRITE <= 0;
		PADDR <= addr;
		@(posedge PCLK);
		PENABLE <= 1;
		@(posedge PCLK);
		data_out = (psel == PSEL_SLAVE) ? slave_PRDATA : PRDATA;
		PENABLE <= 0;
		PSEL <= 0;
		slave_PSEL <= 0;
	end
endtask

task check_result;
	input [127:0] result;
	input [127:0] golden;
	output error;
	begin
	  error = 0;
		if(result != golden)
			begin
				$display("TEST FAILED ate time %t!", $time);
				$display("Expected %x, obtained %x", golden, result);
				error = 1;
				`ifdef STOP_ERROR
				$stop;
				`endif
			end
	end
endtask

task invert_data;
  input [15:0] in;
  input [3:0] size;
  output [15:0] out;
  integer i;
  begin
    out = 0;
    for(i = 0; i < size; i = i + 1)
      out[i] = in[size - 1 - i];
  end
endtask

task spi_disable;
  begin
    //Desabilita SPI
    apb_write(SPI_CR1, MASTER_MODE | SPI_DISABLE, PSEL_MASTER);
    apb_write(SPI_CR1, SPI_DISABLE, PSEL_SLAVE);
    
    while(tb_spi_ip.SPI_IP.CORE.CONTROL_UNT.master_state)
      begin
        @(posedge master_clk);
      end
  end
endtask

always @(posedge sck_out)
  begin
    serial_in = !serial_in;
  end
  
initial
  begin
    reset;
    
    //Caso de Teste 1: teste dos modos de transmissão MSB_FIRST e LSB_FIRST
    error = 0;
    //Configura mestre para transmissão no modo MSB_FIRST
    apb_write(SPI_CR2, RXNE_IE, PSEL_MASTER);
    apb_write(SPI_CR1, MASTER_MODE | MSB_FIRST | FRAME_8 | SPI_ENABLE | CLK_DIV_2 | 32'h03, PSEL_MASTER);
    
    
    //Escreve dados no tx_buffer do escravo e o configura
    //Lembre que os dados devem ser escritos no tx_buffer do escravo antes de habilitá-lo
    data_write_slave = 32'h00cd;
    apb_write(SPI_DR, data_write_slave, PSEL_SLAVE);
    apb_write(SPI_CR1, SLAVE_MODE  | MSB_FIRST | FRAME_8 | SPI_ENABLE | CLK_DIV_2 | 32'h03, PSEL_SLAVE);
    
    //Escreve dados no tx_buffer do mestre
    data_write_master = 32'h00ab; 
    apb_write(SPI_DR, data_write_master, PSEL_MASTER);
    
    //repeat(8)@(posedge clk);
    //apb_write(SPI_DR, 32'h00cd);
    @(posedge int_rxne);
    //@(negedge tb_spi_ip.SPI_IP.HOST_INTERFACE.busy_flag);
    apb_read(SPI_DR, data_read_master, PSEL_MASTER);
    apb_read(SPI_DR, data_read_slave, PSEL_SLAVE);
    check_result(data_read_master, data_write_slave, error_chk);
    error = error + error_chk;
    check_result(data_read_slave, data_write_master, error_chk);
    error = error + error_chk;
    
    //Desabilita SPI
    apb_write(SPI_CR1, SPI_DISABLE, PSEL_MASTER);
    apb_write(SPI_CR1, SPI_DISABLE, PSEL_SLAVE);
    
    //Configura mestre para transmissão no modo LSB_FIRST
    apb_write(SPI_CR2, RXNE_IE, PSEL_MASTER);
    apb_write(SPI_CR1, MASTER_MODE | LSB_FIRST | FRAME_8 | SPI_ENABLE | CLK_DIV_2 | 32'h03, PSEL_MASTER);
    
    //Escreve dados no tx_buffer do escravo e o configura
    //Lembre que os dados devem ser escritos no tx_buffer do escravo antes de habilitá-lo
    data_write_slave = 32'h00cd;
    apb_write(SPI_DR, data_write_slave, PSEL_SLAVE);
    apb_write(SPI_CR1, SLAVE_MODE  | LSB_FIRST | FRAME_8 | SPI_ENABLE | CLK_DIV_2 | 32'h03, PSEL_SLAVE);
    
    //Escreve dados no tx_buffer do mestre
    data_write_master = 32'h00ab; 
    apb_write(SPI_DR, data_write_master, PSEL_MASTER);
    
    @(posedge int_rxne);
    apb_read(SPI_DR, data_read_master, PSEL_MASTER);
    apb_read(SPI_DR, data_read_slave, PSEL_SLAVE);
    invert_data(data_write_master, 8, golden);
    check_result(data_read_slave, golden, error_chk);
    error = error + error_chk;
    invert_data(data_write_slave, 8, golden);
    check_result(data_read_master, golden, error_chk);
    error = error + error_chk;
 
    if(!error)
      $display("TEST OF BIT MSB PASSED!!");
    else
      $display("TEST OF BIT MSB FAILED!!\n Founded %d error", error);
      
    //Caso de Teste2: teste do gerador de baund rate
    error = 0;
    //CLK_DIV_2
    //Desabilita SPI
    apb_write(SPI_CR1, SPI_DISABLE, PSEL_MASTER);
    apb_write(SPI_CR1, SPI_DISABLE, PSEL_SLAVE);
    
    apb_write(SPI_CR2, RXNE_IE, PSEL_MASTER);
    apb_write(SPI_CR1, MASTER_MODE | MSB_FIRST | FRAME_8 | SPI_ENABLE | CLK_DIV_2 | 32'h03, PSEL_MASTER);
    
    
    //Escreve dados no tx_buffer do escravo e o configura
    //Lembre que os dados devem ser escritos no tx_buffer do escravo antes de habilitá-lo
    data_write_slave = 32'h0001;
    apb_write(SPI_DR, data_write_slave, PSEL_SLAVE);
    apb_write(SPI_CR1, SLAVE_MODE  | MSB_FIRST | FRAME_8 | SPI_ENABLE | CLK_DIV_2 | 32'h03, PSEL_SLAVE);
    
    //Escreve dados no tx_buffer do mestre
    data_write_master = 32'h00ff; 
    apb_write(SPI_DR, data_write_master, PSEL_MASTER);
    
    @(posedge int_rxne);
    //@(negedge tb_spi_ip.SPI_IP.HOST_INTERFACE.busy_flag);
    apb_read(SPI_DR, data_read_master, PSEL_MASTER);
    apb_read(SPI_DR, data_read_slave, PSEL_SLAVE);
    check_result(data_read_master, data_write_slave, error_chk);
    error = error + error_chk;
    check_result(data_read_slave, data_write_master, error_chk);
    error = error + error_chk;
    
    //CLK_DIV_4
    apb_write(SPI_CR1, MASTER_MODE | MSB_FIRST | FRAME_8 | SPI_ENABLE | CLK_DIV_4 | 32'h03, PSEL_MASTER);
    
    //Escreve dados no tx_buffer do escravo e o configura
    //Lembre que os dados devem ser escritos no tx_buffer do escravo antes de habilitá-lo
    data_write_slave = 32'h0002;
    apb_write(SPI_DR, data_write_slave, PSEL_SLAVE);
    apb_write(SPI_CR1, SLAVE_MODE  | MSB_FIRST | FRAME_8 | SPI_ENABLE | CLK_DIV_4 | 32'h03, PSEL_SLAVE);
    
    //Escreve dados no tx_buffer do mestre
    data_write_master = 32'h00ab; 
    apb_write(SPI_DR, data_write_master, PSEL_MASTER);
    
    @(posedge int_rxne);

    apb_read(SPI_DR, data_read_master, PSEL_MASTER);
    apb_read(SPI_DR, data_read_slave, PSEL_SLAVE);
    check_result(data_read_master, data_write_slave, error_chk);
    error = error + error_chk;
    check_result(data_read_slave, data_write_master, error_chk);
    error = error + error_chk;
    
    //CLK_DIV_8
    apb_write(SPI_CR1, MASTER_MODE | MSB_FIRST | FRAME_8 | SPI_ENABLE | CLK_DIV_8 | 32'h03, PSEL_MASTER);
    
    //Escreve dados no tx_buffer do escravo e o configura
    //Lembre que os dados devem ser escritos no tx_buffer do escravo antes de habilitá-lo
    data_write_slave = 32'h00fe;
    apb_write(SPI_DR, data_write_slave, PSEL_SLAVE);
    apb_write(SPI_CR1, SLAVE_MODE  | MSB_FIRST | FRAME_8 | SPI_ENABLE | CLK_DIV_4 | 32'h03, PSEL_SLAVE);
    
    //Escreve dados no tx_buffer do mestre
    data_write_master = 32'h0003; 
    apb_write(SPI_DR, data_write_master, PSEL_MASTER);
    
    @(posedge int_rxne);

    apb_read(SPI_DR, data_read_master, PSEL_MASTER);
    apb_read(SPI_DR, data_read_slave, PSEL_SLAVE);
    check_result(data_read_master, data_write_slave, error_chk);
    error = error + error_chk;
    check_result(data_read_slave, data_write_master, error_chk);
    error = error + error_chk;
    
    //CLK_DIV_16
    apb_write(SPI_CR1, MASTER_MODE | MSB_FIRST | FRAME_8 | SPI_ENABLE | CLK_DIV_16 | 32'h03, PSEL_MASTER);
    
    //Escreve dados no tx_buffer do escravo e o configura
    //Lembre que os dados devem ser escritos no tx_buffer do escravo antes de habilitá-lo
    data_write_slave = 32'h0004;
    apb_write(SPI_DR, data_write_slave, PSEL_SLAVE);
    apb_write(SPI_CR1, SLAVE_MODE  | MSB_FIRST | FRAME_8 | SPI_ENABLE | CLK_DIV_4 | 32'h03, PSEL_SLAVE);
    
    //Escreve dados no tx_buffer do mestre
    data_write_master = 32'h00fd; 
    apb_write(SPI_DR, data_write_master, PSEL_MASTER);
    
    @(posedge int_rxne);

    apb_read(SPI_DR, data_read_master, PSEL_MASTER);
    apb_read(SPI_DR, data_read_slave, PSEL_SLAVE);
    check_result(data_read_master, data_write_slave, error_chk);
    error = error + error_chk;
    check_result(data_read_slave, data_write_master, error_chk);
    error = error + error_chk;
    
    //CLK_DIV_32
    apb_write(SPI_CR1, MASTER_MODE | MSB_FIRST | FRAME_8 | SPI_ENABLE | CLK_DIV_32 | 32'h03, PSEL_MASTER);
    
    //Escreve dados no tx_buffer do escravo e o configura
    //Lembre que os dados devem ser escritos no tx_buffer do escravo antes de habilitá-lo
    data_write_slave = 32'h0005;
    apb_write(SPI_DR, data_write_slave, PSEL_SLAVE);
    apb_write(SPI_CR1, SLAVE_MODE  | MSB_FIRST | FRAME_8 | SPI_ENABLE | CLK_DIV_4 | 32'h03, PSEL_SLAVE);
    
    //Escreve dados no tx_buffer do mestre
    data_write_master = 32'h0006; 
    apb_write(SPI_DR, data_write_master, PSEL_MASTER);
    
    @(posedge int_rxne);

    apb_read(SPI_DR, data_read_master, PSEL_MASTER);
    apb_read(SPI_DR, data_read_slave, PSEL_SLAVE);
    check_result(data_read_master, data_write_slave, error_chk);
    error = error + error_chk;
    check_result(data_read_slave, data_write_master, error_chk);
    error = error + error_chk;
    
    //CLK_DIV_64
    apb_write(SPI_CR1, MASTER_MODE | MSB_FIRST | FRAME_8 | SPI_ENABLE | CLK_DIV_64 | 32'h03, PSEL_MASTER);
    
    //Escreve dados no tx_buffer do escravo e o configura
    //Lembre que os dados devem ser escritos no tx_buffer do escravo antes de habilitá-lo
    data_write_slave = 32'h00c7;
    apb_write(SPI_DR, data_write_slave, PSEL_SLAVE);
    apb_write(SPI_CR1, SLAVE_MODE  | MSB_FIRST | FRAME_8 | SPI_ENABLE | CLK_DIV_4 | 32'h03, PSEL_SLAVE);
    
    //Escreve dados no tx_buffer do mestre
    data_write_master = 32'h00f8; 
    apb_write(SPI_DR, data_write_master, PSEL_MASTER);
    
    @(posedge int_rxne);

    apb_read(SPI_DR, data_read_master, PSEL_MASTER);
    apb_read(SPI_DR, data_read_slave, PSEL_SLAVE);
    check_result(data_read_master, data_write_slave, error_chk);
    error = error + error_chk;
    check_result(data_read_slave, data_write_master, error_chk);
    error = error + error_chk;
    
    //CLK_DIV_128
    apb_write(SPI_CR1, MASTER_MODE | MSB_FIRST | FRAME_8 | SPI_ENABLE | CLK_DIV_128 | 32'h03, PSEL_MASTER);
    
    //Escreve dados no tx_buffer do escravo e o configura
    //Lembre que os dados devem ser escritos no tx_buffer do escravo antes de habilitá-lo
    data_write_slave = 32'h0009;
    apb_write(SPI_DR, data_write_slave, PSEL_SLAVE);
    apb_write(SPI_CR1, SLAVE_MODE  | MSB_FIRST | FRAME_8 | SPI_ENABLE | CLK_DIV_4 | 32'h03, PSEL_SLAVE);
    
    //Escreve dados no tx_buffer do mestre
    data_write_master = 32'h00a2; 
    apb_write(SPI_DR, data_write_master, PSEL_MASTER);
    
    @(posedge int_rxne);

    apb_read(SPI_DR, data_read_master, PSEL_MASTER);
    apb_read(SPI_DR, data_read_slave, PSEL_SLAVE);
    check_result(data_read_master, data_write_slave, error_chk);
    error = error + error_chk;
    check_result(data_read_slave, data_write_master, error_chk);
    error = error + error_chk;
    
    //CLK_DIV_256
    apb_write(SPI_CR1, MASTER_MODE | MSB_FIRST | FRAME_8 | SPI_ENABLE | CLK_DIV_256 | 32'h03, PSEL_MASTER);
    
    //Escreve dados no tx_buffer do escravo e o configura
    //Lembre que os dados devem ser escritos no tx_buffer do escravo antes de habilitá-lo
    data_write_slave = 32'h0058;
    apb_write(SPI_DR, data_write_slave, PSEL_SLAVE);
    apb_write(SPI_CR1, SLAVE_MODE  | MSB_FIRST | FRAME_8 | SPI_ENABLE | CLK_DIV_4 | 32'h03, PSEL_SLAVE);
    
    //Escreve dados no tx_buffer do mestre
    data_write_master = 32'h0045; 
    apb_write(SPI_DR, data_write_master, PSEL_MASTER);
    
    @(posedge int_rxne);

    apb_read(SPI_DR, data_read_master, PSEL_MASTER);
    apb_read(SPI_DR, data_read_slave, PSEL_SLAVE);
    check_result(data_read_master, data_write_slave, error_chk);
    error = error + error_chk;
    check_result(data_read_slave, data_write_master, error_chk);
    error = error + error_chk;
    
    if(!error)
      $display("TEST OF CLK_DIV PASSED!!");
    else
      $display("TEST OF CLK_DIV FAILED!!\n Founded %d error", error);
      
    //Caso de teste 3: teste dos bits cpol cpha
    error = 0;
    spi_disable;
    
  for(i = 0; i < 4; i = i + 1)
  begin
    //Configura CPOL e CPHA
    apb_write(SPI_CR2, RXNE_IE, PSEL_MASTER);
    apb_write(SPI_CR1, MASTER_MODE | MSB_FIRST | FRAME_8 | SPI_ENABLE | CLK_DIV_2 | i, PSEL_MASTER);
    
    
    //Escreve dados no tx_buffer do escravo e o configura
    //Lembre que os dados devem ser escritos no tx_buffer do escravo antes de habilitá-lo
    data_write_slave = 32'h0080 + i;
    apb_write(SPI_DR, data_write_slave, PSEL_SLAVE);
    apb_write(SPI_CR1, SLAVE_MODE  | MSB_FIRST | FRAME_8 | SPI_ENABLE | CLK_DIV_2 | i, PSEL_SLAVE);
    
    //Escreve dados no tx_buffer do mestre
    data_write_master = 32'h0090 + i; 
    apb_write(SPI_DR, data_write_master, PSEL_MASTER);
    
    
    @(negedge tb_spi_ip.SPI_IP.HOST_INTERFACE.busy_flag);
    
    spi_disable;
    
    apb_read(SPI_DR, data_read_master, PSEL_MASTER);
    apb_read(SPI_DR, data_read_slave, PSEL_SLAVE);
    check_result(data_read_master, data_write_slave, error_chk);
    error = error + error_chk;
    check_result(data_read_slave, data_write_master, error_chk);
    error = error + error_chk;
  end
    
    if(!error)
      $display("TEST OF CPHA CPOL PASSED!!");
    else
      $display("TEST OF CPHA CPOL FAILED!!\n Founded %d error", error);
    
    //Caso de teste 4: tesete de operação em modo contínuo
    error = 0;
    apb_write(SPI_CR2, RXNE_IE, PSEL_MASTER);
    apb_write(SPI_CR1, MASTER_MODE | MSB_FIRST | FRAME_8 | SPI_ENABLE | CLK_DIV_2 | 32'h0, PSEL_MASTER);
    
    
    //Escreve dados no tx_buffer do escravo e o configura
    //Lembre que os dados devem ser escritos no tx_buffer do escravo antes de habilitá-lo
    data_write_slave = 32'h00022;
    apb_write(SPI_DR, data_write_slave, PSEL_SLAVE);
    apb_write(SPI_CR1, SLAVE_MODE  | MSB_FIRST | FRAME_8 | SPI_ENABLE | CLK_DIV_2 | 32'h03, PSEL_SLAVE);
    
    //Escreve dados no tx_buffer do mestre
    data_write_master = 32'h00077; 
    apb_write(SPI_DR, data_write_master, PSEL_MASTER);
    
    @(negedge tb_spi_ip.SPI_IP.HOST_INTERFACE.hi_set_txe_flag_i);
    apb_write(SPI_DR, 32'hde, PSEL_MASTER);
    
    @(posedge sck_out);
    @(negedge sck_out);
    apb_write(SPI_DR, 32'hbb, PSEL_SLAVE);
    
    @(posedge int_rxne);
      
    apb_read(SPI_DR, data_read_master, PSEL_MASTER);
    apb_read(SPI_DR, data_read_slave, PSEL_SLAVE);
    
    check_result(data_read_master, 32'h00022, error_chk);
    error = error + error_chk;
    check_result(data_read_slave, 32'h00077, error_chk);
    error = error + error_chk;
    
    @(posedge int_rxne);
      
    apb_read(SPI_DR, data_read_master, PSEL_MASTER);
    apb_read(SPI_DR, data_read_slave, PSEL_SLAVE);
    
    check_result(data_read_master, 32'hbb, error_chk);
    error = error + error_chk;
    check_result(data_read_slave, 32'hde, error_chk);
    error = error + error_chk;

    if(!error)
      $display("TEST OF CONTINUOUS MODE PASSED!!");
    else
      $display("TEST OF CONTINUOUS MODE FAILED!!\n Founded %d error", error);
  
    //Caso de teste: transmissão de 16 bits
    error = 0;
    apb_write(SPI_CR2, RXNE_IE, PSEL_MASTER);
    apb_write(SPI_CR1, MASTER_MODE | MSB_FIRST | FRAME_16 | SPI_ENABLE | CLK_DIV_2 | 32'h0, PSEL_MASTER);
    
    
    //Escreve dados no tx_buffer do escravo e o configura
    //Lembre que os dados devem ser escritos no tx_buffer do escravo antes de habilitá-lo
    data_write_slave = 32'haf112233;
    apb_write(SPI_DR, data_write_slave, PSEL_SLAVE);
    apb_write(SPI_CR1, SLAVE_MODE  | MSB_FIRST | FRAME_16 | SPI_ENABLE | CLK_DIV_2 | 32'h03, PSEL_SLAVE);
    
    //Escreve dados no tx_buffer do mestre
    data_write_master = 32'hbbccddee; 
    apb_write(SPI_DR, data_write_master, PSEL_MASTER);
    
    @(posedge int_rxne);
      
    apb_read(SPI_DR, data_read_master, PSEL_MASTER);
    apb_read(SPI_DR, data_read_slave, PSEL_SLAVE);
    
    check_result(data_read_master, data_write_slave, error_chk);
    error = error + error_chk;
    check_result(data_read_slave, data_write_master, error_chk);
    error = error + error_chk;
    
    if(!error)
      $display("TEST OF 16 BITS TX/RX PASSED!!");
    else
      $display("TEST OF 16 BITS TX/RX FAILED!!\n Founded %d error", error);
      
      spi_disable;
    
    //Caso de Teste: modos de transmissão
    //Master TX only / Slave RX only
    error = 0;
    apb_write(SPI_CR2, RXNE_IE, PSEL_MASTER);
    apb_write(SPI_CR1, MASTER_MODE | BIDI_MODE | TX_ONLY_MODE | LSB_FIRST | FRAME_8 | SPI_ENABLE | CLK_DIV_2 | 32'h0, PSEL_MASTER);
    
    apb_write(SPI_CR1, SLAVE_MODE | RX_ONLY | LSB_FIRST | FRAME_8 | SPI_ENABLE | CLK_DIV_2 | 32'h03, PSEL_SLAVE);
    
    //Escreve dados no tx_buffer do mestre
    data_write_master = 32'hbbcc; 
    apb_write(SPI_DR, data_write_master, PSEL_MASTER);
    
     @(negedge tb_spi_ip.SPI_IP.HOST_INTERFACE.busy_flag);
    spi_disable;
     
    apb_read(SPI_DR, data_read_slave, PSEL_SLAVE);
    invert_data(data_write_master, 8, golden);
    check_result(data_read_slave, golden, error_chk);
    error = error + error_chk;
    
    //Master RX only / Slave TX only
    apb_write(SPI_CR2, RXNE_IE, PSEL_MASTER);
    apb_write(SPI_CR1, MASTER_MODE | RX_ONLY | LSB_FIRST | FRAME_8 | SPI_ENABLE | CLK_DIV_2 | 32'h0, PSEL_MASTER);
    
    apb_write(SPI_CR1, SLAVE_MODE | BIDI_MODE | TX_ONLY_MODE | LSB_FIRST | FRAME_8 | SPI_ENABLE | CLK_DIV_2 | 32'h0, PSEL_SLAVE);
    
    repeat(2) @(posedge master_clk);
    
    @(negedge tb_spi_ip.SPI_IP_SLAVE.HOST_INTERFACE.busy_flag);
    spi_disable;  
    
    apb_read(SPI_DR, data_read_master, PSEL_MASTER);
    
    invert_data(data_write_slave, 8, golden);
    check_result(data_read_master, golden, error_chk);
    error = error + error_chk;

    if(!error)
      $display("TEST OF TX MODE PASSED!!");
    else
      $display("TEST OF TX MODE FAILED!!\n Founded %d error", error);
      
      spi_disable;
      
    //Caso de teste: condição de overrun
    error = 0;
    apb_write(SPI_CR2, RXNE_IE, PSEL_MASTER);
    apb_write(SPI_CR1, MASTER_MODE | MSB_FIRST | FRAME_16 | SPI_ENABLE | CLK_DIV_2 | 32'h0, PSEL_MASTER);
    
    
    //Escreve dados no tx_buffer do escravo e o configura
    //Lembre que os dados devem ser escritos no tx_buffer do escravo antes de habilitá-lo
    data_write_slave = 32'haf112233;
    apb_write(SPI_DR, data_write_slave, PSEL_SLAVE);
    apb_write(SPI_CR1, SLAVE_MODE  | MSB_FIRST | FRAME_16 | SPI_ENABLE | CLK_DIV_2 | 32'h03, PSEL_SLAVE);
    
    //Escreve dados no tx_buffer do mestre
    data_write_master = 32'hbbccddee; 
    apb_write(SPI_DR, data_write_master, PSEL_MASTER);
    
    @(posedge int_rxne);
    
    //realiza nova escrita
    data_write_slave = 32'h0000dddd; 
    apb_write(SPI_DR, data_write_slave, PSEL_SLAVE); 
    data_write_master = 32'h00001234; 
    apb_write(SPI_DR, data_write_master, PSEL_MASTER);  
    
    //espera fim da transação. note que são feitas duas escritas e nenhuma leitura
    @(posedge int_rxne);
//    @(negedge tb_spi_ip.SPI_IP.HOST_INTERFACE.busy_flag);
    
    apb_read(SPI_SR, data_read_slave, PSEL_SLAVE);
    apb_read(SPI_SR, data_read_master, PSEL_MASTER);
    
    check_result(data_read_slave, 32'h1b, error_chk);
    error = error + error_chk;
    check_result(data_read_master, 32'h1b, error_chk);
    error = error + error_chk;
  
    apb_read(SPI_DR, data_read_slave, PSEL_SLAVE);
    apb_read(SPI_DR, data_read_master, PSEL_MASTER);

   //testa se o conteúdo do buffer foi alterado na condição de ovr
    if(data_read_slave == data_write_master || data_read_master == data_write_slave)
      begin
        error = error + 1;
        $display("Conteúdo de RX Buffer alterado");
      end
      
      
    //é preciso esperar alguns ciclos até que a flag seja atualizada
    repeat(4) @(posedge master_clk)
    apb_read(SPI_SR, data_read_slave, PSEL_SLAVE);
    apb_read(SPI_SR, data_read_master, PSEL_MASTER);

    check_result(data_read_slave, 32'h02, error_chk);
    error = error + error_chk;
    check_result(data_read_master, 32'h02, error_chk);
    error = error + error_chk;
  
    if(!error)
      $display("TEST OF OVR PASSED!!");
    else
      $display("TEST OF OVR FAILED!!\n Founded %d error", error);
      
    spi_disable;
    
    //Caso de teste:CRC
    error = 0;
    
    apb_write(SPI_CRCPR, 16'h00c3, PSEL_MASTER);
    apb_write(SPI_CRCPR, 16'h00c3, PSEL_SLAVE);
    apb_write(SPI_CR2, RXNE_IE, PSEL_MASTER);
    apb_write(SPI_CR1, MASTER_MODE | MSB_FIRST | FRAME_8 | SPI_ENABLE | CLK_DIV_2 | 32'h00, PSEL_MASTER);
    
    //Escreve dados no tx_buffer do escravo e o configura
    //Lembre que os dados devem ser escritos no tx_buffer do escravo antes de habilitá-lo
    data_write_slave = 32'h0088;
    apb_write(SPI_DRCRCR, data_write_slave, PSEL_SLAVE);
    apb_write(SPI_CR1, SLAVE_MODE  | MSB_FIRST | FRAME_8 | SPI_ENABLE | CLK_DIV_2 | 32'h00, PSEL_SLAVE);
    
    //Escreve dados no tx_buffer do mestre
    data_write_master = 32'h0077; 
    apb_write(SPI_DRCRCR, data_write_master, PSEL_MASTER);
    
    
    @(posedge int_rxne);
    
    apb_read(SPI_DRCRCR, data_read_slave, PSEL_SLAVE);
    apb_read(SPI_DR, data_read_master, PSEL_MASTER);
    
    
    spi_disable;
    
    apb_read(SPI_RXCRCR, data_read_master, PSEL_MASTER);
    apb_read(SPI_TXCRCR, data_read_master_2, PSEL_MASTER);
    check_result(data_read_master, 32'h39, error_chk);
    error = error + error_chk;
    check_result(data_read_master_2, 32'hcc, error_chk);
    error = error + error_chk;

    //Master TX only / Slave RX only
    apb_write(SPI_CR2, RXNE_IE, PSEL_MASTER);
    apb_write(SPI_CR1, MASTER_MODE | BIDI_MODE | TX_ONLY_MODE | MSB_FIRST | FRAME_8 | SPI_ENABLE | CLK_DIV_2 | 32'h0, PSEL_MASTER);
    
    apb_write(SPI_CR1, SLAVE_MODE | RX_ONLY | MSB_FIRST | FRAME_8 | SPI_ENABLE | CLK_DIV_2 | 32'h03, PSEL_SLAVE);
    
    //Escreve dados no tx_buffer do mestre
    data_write_master = 32'haaaa; 
    apb_write(SPI_DR, data_write_master, PSEL_MASTER);
    
    @(negedge tb_spi_ip.SPI_IP.HOST_INTERFACE.busy_flag);
    apb_read(SPI_DRCRCR, data_read_slave, PSEL_SLAVE);
     
    data_write_master = 32'hbbbb; 
    apb_write(SPI_DR, data_write_master, PSEL_MASTER);
    
    @(negedge tb_spi_ip.SPI_IP.HOST_INTERFACE.busy_flag);
    apb_read(SPI_DR, data_read_slave, PSEL_SLAVE);
    data_write_master = 32'haaaa; 
    apb_write(SPI_DRCRCR, data_write_master, PSEL_MASTER);
    
    @(negedge tb_spi_ip.SPI_IP.HOST_INTERFACE.busy_flag);
    
    apb_read(SPI_RXCRCR, data_read_slave, PSEL_SLAVE);
    check_result(data_read_slave, 32'h0e, error_chk);
    error = error + error_chk;
    apb_read(SPI_SR, data_read_slave, PSEL_SLAVE);
    check_result(data_read_slave, 32'h03, error_chk);
    error = error + error_chk;
    
    spi_disable;
    
    //Master RX only / Slave TX only
    $stop;
    data_write_slave = 32'heeee; 
    apb_write(SPI_DR, data_write_slave, PSEL_SLAVE);
    
    apb_write(SPI_CR2, RXNE_IE, PSEL_MASTER);
    apb_write(SPI_CR1, MASTER_MODE | RX_ONLY | MSB_FIRST | FRAME_8 | SPI_ENABLE | CLK_DIV_2 | 32'h0, PSEL_MASTER);
    
    apb_write(SPI_CR1, SLAVE_MODE | BIDI_MODE | TX_ONLY_MODE | MSB_FIRST | FRAME_8 | SPI_ENABLE | CLK_DIV_2 | 32'h0, PSEL_SLAVE);
    
    repeat(2) @(posedge master_clk);
    data_write_slave = 32'hffff; 
    apb_write(SPI_DR, data_write_slave, PSEL_SLAVE);
    
    @(posedge int_rxne);
    apb_read(SPI_DRCRCR, data_read_master, PSEL_MASTER);
    
    repeat(2) @(posedge master_clk);
    data_write_slave = 32'h1111;
    //leitura de ee 
    apb_write(SPI_DRCRCR, data_write_slave, PSEL_SLAVE);
    
    
    @(posedge int_rxne);//espera recepção de ff
    @(posedge int_rxne);//espera recepção de 11
    
    //espera recepção do crc
    @(negedge tb_spi_ip.SPI_IP.CORE.CONTROL_UNT.cnt_data_ready_i);
    
    apb_read(SPI_DR, data_read_master, PSEL_MASTER);
    check_result(data_read_master, 32'hef, error_chk);
    error = error + error_chk;
    apb_read(SPI_SR, data_read_master, PSEL_MASTER);
    check_result(data_read_master, 32'h02, error_chk);
    error = error + error_chk;
    
    $stop;
    
    //LEMBRAR DE DECIDIR SE HAVERÀ OVR OU NÂO QND SPI È DESABILITADA
    //Há uma issue relacionada à flag rxne tb
    
    //LEMBRAR TB DE IMPLAMENTAR UMA FLAG PARA INDICAR QUE O SPI ESTÁ DE FATO DESABILITADO

  end
always #10
	PCLK = !PCLK;
	 
always #10
  clk = !clk;
  
always #60
  master_clk = !master_clk;
endmodule