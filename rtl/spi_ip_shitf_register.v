module spi_ip_shift_register
#(
  parameter PARAM_SR_WIDTH = 16 //must be a power of two
)(
  output [PARAM_SR_WIDTH - 1 : 0] sr_data_out_o,
  output reg sr_data_serial_o,
  output sr_data_ready_o,
  input [PARAM_SR_WIDTH - 1 : 0] sr_data_load_i,
  input sr_data_serial_i,
  input [1:0] sr_load_type_i,
  input sr_load_i,
  input sr_enable_launch_i,
  input sr_enable_capture_i,
  input sr_enable_launch_capture_i,
  input sr_rst_n_i,
  input sr_clk_i
);

function integer clogb2;
  input [31:0] value;
  reg div2;
  begin
 	  for (clogb2 = 0; value > 1; clogb2 = clogb2 + 1)
      value = value >> 1;
  end
endfunction

localparam LOAD_MSB_FIRST = 1'b0;
localparam LOAD_LSB_FIRST = 1'b1;
localparam LOAD_HALF_WORD = 1'b0;
localparam LOAD_WORD = 1'b1;

localparam SR_HIGH_FF_END   = PARAM_SR_WIDTH/2 - 1;
localparam SR_LOW_FF_END    = PARAM_SR_WIDTH/2 - 1;

localparam CNT_WIDTH = clogb2(PARAM_SR_WIDTH);

//Registers definition
reg [PARAM_SR_WIDTH/2 - 1 : 0] sr_high_ff;
reg [PARAM_SR_WIDTH/2 - 1 : 0] sr_low_ff;
reg [CNT_WIDTH        - 1 : 0] cnt_ff;

//Internal signals
wire [PARAM_SR_WIDTH - 1 : 0]data_load_reversed;
wire load_type_format;
wire load_type_size;
wire clear_cnt;

//Signals to select data format
assign load_type_size   = sr_load_type_i[0];
assign load_type_format = sr_load_type_i[1];

//Revert bus
generate
  genvar i;
  for(i = 0; i < PARAM_SR_WIDTH; i = i + 1)
    begin
      assign data_load_reversed[i] = sr_data_load_i[PARAM_SR_WIDTH - 1 - i];
    end
endgenerate

//Shift Register Definition 
always @(posedge sr_clk_i)
  begin
    if(sr_load_i)
      {sr_high_ff, sr_low_ff} <= (load_type_format == LOAD_MSB_FIRST) ? sr_data_load_i : data_load_reversed;
    else
      begin
        if(sr_enable_capture_i)
          begin
            sr_high_ff <= {sr_high_ff[SR_HIGH_FF_END - 1 : 0], sr_low_ff[SR_LOW_FF_END] & (load_type_size == LOAD_WORD)};
            sr_low_ff  <= {sr_low_ff[SR_LOW_FF_END - 1 : 0], sr_data_serial_i};
          end
      end
  end

//Launch Flip-flop
always @(posedge sr_clk_i)
  begin
    if(!sr_rst_n_i)
      sr_data_serial_o <= 1'b0;
    else
      begin
        if(!sr_enable_launch_capture_i)
          sr_data_serial_o <= 1'b0;
        else
          if(sr_enable_launch_i)
            sr_data_serial_o <= (load_type_size == LOAD_HALF_WORD && load_type_format == LOAD_MSB_FIRST) ? sr_low_ff[SR_LOW_FF_END] : sr_high_ff[SR_HIGH_FF_END];
      end
  end

//Clear counter when the HALF_WORD bits has arrived. When WORD bits has arrived the counter is "automatically cleared"
//assign clear_cnt = (cnt_ff == PARAM_SR_WIDTH/2 && load_type_size == LOAD_HALF_WORD);
assign clear_cnt = (cnt_ff == PARAM_SR_WIDTH/2 - 1 && load_type_size == LOAD_HALF_WORD && sr_enable_capture_i);

//Counter Definition
always @(posedge sr_clk_i)
  begin
    if(!sr_rst_n_i)
      cnt_ff <= {CNT_WIDTH{1'b0}};
    else
      if(clear_cnt)
        cnt_ff <= {CNT_WIDTH{1'b0}};
      else
        if(sr_enable_capture_i)
          cnt_ff <= cnt_ff + 1'b1;
  end
  
//Indicates reception is completed
assign sr_data_ready_o = (clear_cnt || (cnt_ff == PARAM_SR_WIDTH - 1 && sr_enable_capture_i));

//Output Bus
assign sr_data_out_o = {sr_high_ff, sr_low_ff};    

endmodule
