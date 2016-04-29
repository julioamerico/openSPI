module tb_spi_ip_shift_register();

localparam LOAD_HALF_WORD_MSB = 2'b00;
localparam LOAD_HALF_WORD_LSB = 2'b10;
localparam LOAD_WORD_MSB      = 2'b01;
localparam LOAD_WORD_LSB      = 2'b11;

reg [15:0] data_load;
reg [15:0] data_load_2;
reg data_serial_in;
reg [1:0] load_type;
reg load;
reg enable_lauch;
reg enable_capture;
reg clk;
reg rst;

wire [15:0] data_out;
wire [15:0] data_out_2;
wire data_serial_out;
wire data_serial_out2;
wire data_ready;

spi_ip_shift_register
#(
  .PARAM_SR_WIDTH (16)
) 
SR
(
  .sr_data_out_o              ( data_out        ),
  .sr_data_serial_o           ( data_serial_out ),
  .sr_data_ready_o            ( data_ready      ),
  .sr_data_load_i             ( data_load       ),
  .sr_data_serial_i           ( data_serial_out2), //( data_in ),
  .sr_load_type_i             ( load_type       ),
  .sr_load_i                  ( load            ),
  .sr_enable_launch_i         ( enable_lauch    ),
  .sr_enable_capture_i        ( enable_capture  ),
  .sr_enable_launch_capture_i ( 1'b1            ),
  .sr_rst_n_i                 ( rst             ),
  .sr_clk_i                   ( clk             )
);

spi_ip_shift_register
#(
  .PARAM_SR_WIDTH (16)
) 
SR_2
(
  .sr_data_out_o              ( data_out_2      ),
  .sr_data_serial_o           ( data_serial_out2),
  .sr_data_ready_o            ( data_ready      ),
  .sr_data_load_i             ( data_load_2     ),
  .sr_data_serial_i           ( data_serial_out ),
  .sr_load_type_i             ( load_type       ),
  .sr_load_i                  ( load            ),
  .sr_enable_launch_i         ( enable_lauch    ),
  .sr_enable_capture_i        ( enable_capture  ),
  .sr_enable_launch_capture_i ( 1'b1            ),
  .sr_rst_n_i                 ( rst             ),
  .sr_clk_i                   ( clk             )
);

task reset;
  begin
    clk = 0;
    rst = 0;
    data_load = 0;
    data_load_2 = 0;
    data_serial_in = 0;
    load_type = 0;
    load = 0;
    enable_lauch = 0;
    enable_capture = 0;
    @(posedge clk);
    @(posedge clk);
    rst = 1;   
  end
endtask

task load_data;
  input [15:0] data_in;
  input [15:0] data_in_2;
  input [1:0]type;
  begin
    load_type = type;
    data_load = data_in;
    data_load_2 = data_in_2;
    load = 1'b1;
    @(posedge clk);
    load = 0;
  end
endtask  

task send_data;
  input [15:0] data_to_tx;
  input integer length;
  integer i;
  begin
    for(i = length - 1; i >= 0; i = i - 1)
      begin
        enable_capture = 0;
        enable_lauch = 1;
        @(posedge clk);
        enable_capture = 1;
        enable_lauch = 0;
        data_serial_in = data_to_tx[i];
        @(posedge clk);
      end
    enable_capture = 0;
    enable_lauch = 0;
    @(posedge clk);  
  end
endtask

task chk_data_out;
  input [15:0] data_golden;
  begin
    if(data_golden != data_out)
      $display("Erro! Esperado %h, obtido %h", data_golden, data_out);
  end
endtask

reg [15:0] data_tx;

initial
  begin
    reset;
    
    load_data(16'h1234, 16'h5678,  LOAD_WORD_MSB);
    data_tx = 16'h1234;
    send_data(data_tx, 16);
    data_tx = 16'h4321;
    send_data(data_tx, 16);
    
    load_data(16'h1e6a, 16'ha6e1,  LOAD_WORD_LSB);
    data_tx = 16'h1234;
    send_data(data_tx, 16);
    data_tx = 16'h4321;
    send_data(data_tx, 16);
    
    load_data(16'hff12, 16'hbb34,  LOAD_HALF_WORD_MSB);
    send_data(data_tx, 8);
    send_data(data_tx, 8);
    
    load_data(16'hff1e, 16'hbb6a,  LOAD_HALF_WORD_LSB);
    send_data(data_tx, 8);
    send_data(data_tx, 8);
    
    $stop;
    
  end
  
  always @(posedge enable_lauch)
    begin
    end
always #10
  clk = ~clk;
endmodule
