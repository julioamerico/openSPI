module spi_ip_flag_sync 
#(
  parameter PARAM_FLAG_RESET = 0,
  parameter PARAM_FLAG_VALID = "ENABLED",
  parameter PARAM_SYNC_STAGES = 2
)
(
  output fs_flag_out_clk_B_o,
  output fs_set_flag_out_clk_A_o,
  output fs_flag_valid_clk_B_o,
  input fs_flag_in_clk_A_i,
  input fs_set_flag_in_clk_B_i,
  input fs_clk_A_i,
  input fs_clk_B_i,
  input fs_rst_n_clk_A_i,
  input fs_rst_n_clk_B_i
);

reg [PARAM_SYNC_STAGES - 1 : 0] flag_out_sync_ff;
reg [PARAM_SYNC_STAGES - 1 : 0] set_flag_sync_ff;
reg [PARAM_SYNC_STAGES - 1 : 0] valid_flag_sync_ff;
reg set_flag_toggle_ff;
reg set_flag_out_ff;
reg flag_valid_ff;

wire teste;
assign teste = fs_set_flag_in_clk_B_i ^ set_flag_toggle_ff;
always @(posedge fs_clk_B_i)
  begin
    if(!fs_rst_n_clk_B_i)
      set_flag_toggle_ff <= 0;
    else
      set_flag_toggle_ff <= fs_set_flag_in_clk_B_i ^ set_flag_toggle_ff; 
  end
               
generate
  genvar i;
  
  for(i = 0 ; i < PARAM_SYNC_STAGES; i = i + 1)
    begin
      always @(posedge fs_clk_B_i)
        begin
          if(!fs_rst_n_clk_B_i)
            begin
              flag_out_sync_ff[i] <= PARAM_FLAG_RESET;
            end
          else
            begin
              if(i == 0)
                begin
                  flag_out_sync_ff[i] <= fs_flag_in_clk_A_i;
                end
              else
                begin
                  flag_out_sync_ff[i] <= flag_out_sync_ff[i - 1];
                end
            end
        end
        
      always @(posedge fs_clk_A_i)
        begin
          if(!fs_rst_n_clk_A_i)
            begin
              set_flag_sync_ff[i] <= 0;
            end
          else
            begin
              if(i == 0)
                begin
                  set_flag_sync_ff[i] <= set_flag_toggle_ff;
                end
              else
                begin
                  set_flag_sync_ff[i] <= set_flag_sync_ff[i - 1];
                end
            end
        end
      
      if(PARAM_FLAG_VALID == "ENABLED")
        begin  
          always @(posedge fs_clk_B_i)
            begin
              if(!fs_rst_n_clk_B_i)
                begin
                  valid_flag_sync_ff[i] <= 0;
                end
              else
                begin
                  if(i == 0)
                    begin
                      valid_flag_sync_ff[i] <= set_flag_out_ff;
                    end
                  else
                    begin
                      valid_flag_sync_ff[i] <= valid_flag_sync_ff[i - 1];
                    end
                end
            end
        end
    end   
endgenerate

always @(posedge fs_clk_A_i)
  begin
    if(!fs_rst_n_clk_A_i)
      set_flag_out_ff <= 0;
    else
      set_flag_out_ff <= set_flag_sync_ff[PARAM_SYNC_STAGES - 1]; 
  end

generate
if(PARAM_FLAG_VALID == "ENABLED")
  always @(posedge fs_clk_B_i)
    begin
      if(!fs_rst_n_clk_B_i)
        flag_valid_ff <= 0;
      else
        flag_valid_ff <= ~(valid_flag_sync_ff[PARAM_SYNC_STAGES - 1] ^ set_flag_toggle_ff); 
    end
endgenerate

assign fs_flag_out_clk_B_o = flag_out_sync_ff[PARAM_SYNC_STAGES - 1];  
assign fs_set_flag_out_clk_A_o = set_flag_out_ff ^ set_flag_sync_ff[PARAM_SYNC_STAGES - 1];

generate
  if(PARAM_FLAG_VALID == "ENABLED")
    assign fs_flag_valid_clk_B_o = flag_valid_ff;
  else
    assign fs_flag_valid_clk_B_o = 1'b0;
endgenerate

endmodule
