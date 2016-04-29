module tb_spi_ip_crc_serial;

localparam CRC_8  = 1'b0;
localparam CRC_16 = 1'b1;
  
reg crc_in;
reg crc_en;
reg crc_init;
reg crc_size;
reg [15:0] crc_poly;
reg rst_n;
reg clk;

wire [15:0] crc_out;

spi_ip_crc_serial CRC
(
  .cs_crc_out_o    ( crc_out  ),   
  .cs_crc_in_i     ( crc_in   ),
  .cs_crc_enable_i ( crc_en   ),
  .cs_crc_init_i   ( crc_init ),  
  .cs_crc_size_i   ( crc_size ),
  .cs_crc_poly_i   ( crc_poly ),    
  .cs_rst_n_i      ( rst_n    ),                         
  .cs_clk_i        ( clk      )                            
);

task reset;
  begin
    rst_n = 0;
    clk = 0;
    crc_in = 0;
    crc_en = 0;
    crc_init = 0;
    crc_size = 0;
    crc_poly = 0;
    @(posedge clk);
    @(posedge clk);
    rst_n = 1;
  end
endtask

task send_data;
  input [15:0] data_in;
  input size;
  integer i;
  begin
    crc_size = size;
    crc_en = 1;
    for(i = 0; i < 2**(3 + size); i = i + 1)
      begin
        crc_in = data_in[i];
        @(posedge clk);
      end
    crc_en = 0;
    @(posedge clk);
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

task reset_crc;
  begin
    crc_init = 1;
    @(posedge clk);
    crc_init = 0;
  end
endtask

integer error;
reg error_chk;

initial
  begin
    reset;
    crc_poly = 16'h0003;
    send_data(16'hffab, CRC_8);
    check_result(crc_out, 16'h007c, error_chk);
    error = error + error_chk;
    
    reset_crc;
    crc_poly = 16'h0083;
    send_data(16'h0077, CRC_8);
    check_result(crc_out, 16'h005f, error_chk);
    error = error + error_chk;
    
    reset_crc;
    crc_poly = 16'h00c3;
    send_data(16'h0077, CRC_8);
    check_result(crc_out, 16'h005b, error_chk);
    error = error + error_chk;
    
    reset_crc;
    crc_poly = 16'h0083;
    send_data(16'h7777, CRC_16);
    check_result(crc_out, 16'h7fa8, error_chk);
    error = error + error_chk;
    
    reset_crc;
    crc_poly = 16'hc083;
    send_data(16'h7777, CRC_16);
    check_result(crc_out, 16'h6826, error_chk);
    error = error + error_chk;
    
    reset_crc;
    crc_poly = 16'hffff;
    send_data(16'h7777, CRC_16);
    check_result(crc_out, 16'h7777, error_chk);
    error = error + error_chk;
    $stop;
  end
always #10
  clk = !clk;
endmodule
