module spi_ip_crc_serial
#(
	parameter PARAM_CRC_INIT = 16'h0000   
)(
	//OUTPUTS
	output [15:0] cs_crc_out_o,   
	//INPUTS
	input cs_crc_in_i,
	input cs_crc_enable_i,
	input cs_crc_init_i,  
	input cs_crc_size_i,
	input [15:0] cs_crc_poly_i,    
	input cs_rst_n_i,                         
	input cs_clk_i                            
);

localparam CRC_8  = 1'b0;
localparam CRC_16 = 1'b1;

reg [15:0] crc_ff;

wire [15:0] crc_ff_in;
wire [7:0] feedback_crc16;
wire [7:0] feedback_crc8;
wire [7:0] feedback_high;
wire [7:0] feedback_low;

assign feedback_crc16 = {8{cs_crc_in_i ^ crc_ff[15]}};
assign feedback_crc8  = (cs_crc_size_i == CRC_8) ? {8{cs_crc_in_i ^ crc_ff[7]}} : feedback_crc16;

assign feedback_high = {crc_ff[14:8], crc_ff[7] & cs_crc_size_i} ^ (cs_crc_poly_i[15:8] & feedback_crc16);
assign feedback_low  = {crc_ff[6:0], 1'b0} ^ (cs_crc_poly_i[7:0] & feedback_crc8);
assign crc_ff_in = {feedback_high, feedback_low}; 

always @(posedge cs_clk_i)
  begin
    if(!cs_rst_n_i)
      crc_ff <= PARAM_CRC_INIT;
    else
      begin
        if(cs_crc_init_i)
          crc_ff <= PARAM_CRC_INIT;
        else
          if(cs_crc_enable_i)
            crc_ff <= crc_ff_in;
      end
        
  end
  
assign cs_crc_out_o = crc_ff;

endmodule
