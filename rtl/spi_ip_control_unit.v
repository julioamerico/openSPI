module spi_ip_control_unit
(
  output cnt_busy_o,
  output cnt_sr_src_sel_o,
  output cnt_load_sr_o,
  output cnt_set_txe_flag_o,
  output cnt_enable_tick_o,
  output cnt_ssin_o,
  output cnt_enable_lauch_capture_o,
  output cnt_enable_sck_o,
  output cnt_set_rxne_flag_o, 
  output cnt_clear_crc_tx_o,
  output cnt_clear_crc_rx_o,
  output cnt_crc_error_en_o, 
  output cnt_set_first_launch_o,
  output cnt_enable_crc_o,
  output cnt_crc_init_o,
  output reg cnt_slave_tick_en_i,
  input cnt_spi_en_i,
  input cnt_tx_mode_i,
  input cnt_master_mode_i,
  input cnt_slave_mode_i,
  input cnt_txe_flag_i,
  input cnt_txe_valid_i,
  input cnt_tick_i,
  input cnt_data_ready_i,
  input cnt_rx_mode_i,
  input cnt_crc_tx_flag_i,
  input cnt_tx_only_i,
  input cnt_crc_rx_flag_i,
  input cnt_ssin_i,
  input cnt_clk_i,
  input cnt_rst_n_i
);

//Master FSM STATES
localparam MASTER_IDLE           = 3'd0;
localparam MASTER_WAIT_TX_BUFFER = 3'd1;
localparam MASTER_SETUP          = 3'd2;
localparam MASTER_TX_RX          = 3'd3;
localparam MASTER_LSB            = 3'd4;
localparam MASTER_READ_BUFFER    = 3'd5;
localparam MASTER_CRC            = 3'd6;
localparam MASTER_END            = 3'd7;

//Slave FSM STATES
localparam SLAVE_IDLE          = 3'd0;
localparam SLAVE_WAIT_SSIN_ON  = 3'd1;
localparam SLAVE_SETUP         = 3'd2;
localparam SLAVE_ACTIVE        = 3'd3;
localparam SLAVE_READ_BUFFER   = 3'd4;
localparam SLAVE_WAIT_SSIN_OFF = 3'd5;

localparam ENABLE  = 1'b1;
localparam DISABLE = 1'b0;
localparam SSIN_ENABLE  = 1'b0;
localparam SSIN_DISABLE = 1'b1;

localparam SR_TX_BUFFER = 1'b1;
localparam SR_TX_CRC = 1'b0;

reg [2:0] master_state, master_next_state;
reg [2:0] slave_state, slave_next_state;

reg crc_phase;
reg crc_rx_last;

reg master_busy;
reg master_sr_src_sel;
reg master_load_sr;
reg master_set_txe_flag;
reg master_enable_tick; 
reg master_ssin;
reg master_enable_lauch_capture;
reg master_enable_sck;     
reg master_set_rxne_flag; 
reg master_set_crc_rx_last;  
reg master_set_crc_phase; 
reg master_clear_crc_tx;
reg master_clear_crc_rx;
reg master_clear_crc_phase;
reg master_clear_crc_rx_last;
reg master_crc_error_en; 
reg master_crc_init;
reg slave_set_crc_rx_last;  
reg slave_set_crc_phase; 
reg slave_clear_crc_tx;
reg slave_clear_crc_rx; 
reg slave_clear_crc_phase;
reg slave_clear_crc_rx_last;
reg slave_busy;
reg slave_load_sr;
reg slave_set_txe_flag;
reg slave_set_first_launch;
reg slave_set_rxne_flag;
reg slave_crc_error_en;
reg slave_sr_src_sel;
reg slave_crc_init;

//Master State Flop definition
always @(posedge cnt_clk_i)
  begin
    if(!cnt_rst_n_i)
      master_state <= MASTER_IDLE;
    else
      master_state <= master_next_state;
  end
  
//Next State Logic Definition
always @(*)
  begin
    master_next_state = master_state;
    case(master_state)
      MASTER_IDLE:
        begin
          if(cnt_spi_en_i && cnt_master_mode_i)
            master_next_state = ( cnt_tx_mode_i ) ? MASTER_WAIT_TX_BUFFER : MASTER_SETUP;
        end
      MASTER_WAIT_TX_BUFFER :
        begin
          if(!cnt_txe_flag_i)
            master_next_state = MASTER_SETUP;
          else
            if(cnt_txe_valid_i && !cnt_spi_en_i)
              master_next_state = MASTER_IDLE;
        end
      MASTER_SETUP :
        begin
          if(cnt_tick_i)
            master_next_state = MASTER_TX_RX;
        end
      MASTER_TX_RX:
        begin
          if(cnt_data_ready_i)
            master_next_state = MASTER_LSB;
        end
      MASTER_LSB:
        begin
          if(cnt_tick_i)
            master_next_state = MASTER_READ_BUFFER;          
        end
      MASTER_READ_BUFFER:
        begin
          if(cnt_tick_i)
            master_next_state = ( crc_phase ) ? MASTER_CRC : MASTER_END;             
        end
      MASTER_CRC:
        begin
          if(cnt_tick_i)
            begin
              if(cnt_tx_mode_i)
                master_next_state = MASTER_WAIT_TX_BUFFER;
              else
                if(cnt_rx_mode_i && !cnt_crc_rx_flag_i)
                  master_next_state = MASTER_SETUP;
            end
        end
      MASTER_END:
        begin
          if(cnt_tick_i)
            begin
              master_next_state = MASTER_IDLE;
              if((cnt_tx_mode_i && !cnt_txe_flag_i)                      ||
                 (cnt_tx_mode_i &&  cnt_txe_flag_i && cnt_crc_tx_flag_i) ||
                 (cnt_rx_mode_i && cnt_spi_en_i)                         ||
                 (cnt_rx_mode_i && cnt_crc_rx_flag_i)                    
                 )
                 master_next_state = MASTER_SETUP;
              if(cnt_tx_mode_i && cnt_txe_flag_i && !cnt_crc_tx_flag_i && cnt_tick_i)
                master_next_state = MASTER_WAIT_TX_BUFFER;
            end
        end
    endcase
  end
  
assign cnt_enable_crc_o = !crc_phase;

//Output Logic
always @(*)
  begin
    master_busy = ENABLE;
    master_sr_src_sel = SR_TX_BUFFER;
    master_load_sr = DISABLE;
    master_set_txe_flag = DISABLE;
    master_enable_tick = ENABLE; 
    master_ssin = SSIN_ENABLE;
    master_enable_lauch_capture = DISABLE;
    master_enable_sck = DISABLE;     
    master_set_rxne_flag = DISABLE; 
    master_set_crc_rx_last = DISABLE;  
    master_set_crc_phase = DISABLE; 
    master_clear_crc_tx = DISABLE;
    master_clear_crc_rx = DISABLE;
    master_clear_crc_phase = DISABLE;
    master_clear_crc_rx_last = DISABLE;
    master_crc_error_en = DISABLE;
    master_crc_init = DISABLE;     
    case(master_state)
      MASTER_IDLE:
        begin
          master_busy = DISABLE;
          master_ssin = SSIN_DISABLE;
          master_enable_tick = DISABLE;
          if(cnt_spi_en_i && cnt_master_mode_i)
            master_crc_init = ENABLE;
        end
      MASTER_WAIT_TX_BUFFER :
        begin
          master_busy = DISABLE;
          master_ssin = SSIN_DISABLE;
          master_enable_tick = DISABLE;
          if(!cnt_txe_flag_i)
            begin
              master_load_sr = ENABLE;
              master_set_txe_flag = ENABLE;
            end
        end
      MASTER_SETUP :
        begin
          master_enable_lauch_capture = ENABLE;
        end
      MASTER_TX_RX:
        begin
          master_enable_sck = ENABLE;
          master_enable_lauch_capture = ENABLE;
        end
      MASTER_LSB:
        begin
          master_enable_sck = ENABLE;
        end
      MASTER_READ_BUFFER:
        begin
          if(cnt_tick_i && !crc_phase && !cnt_tx_only_i)
            master_set_rxne_flag = ENABLE;
        end
      MASTER_CRC:
        begin
          master_ssin = SSIN_DISABLE;
          master_clear_crc_tx = ENABLE;
          master_clear_crc_rx = ENABLE;
          master_clear_crc_phase = ENABLE;
          master_clear_crc_rx_last = ENABLE;
          master_crc_error_en = ~cnt_tx_only_i;
        end
      MASTER_END:
        begin
          master_ssin = SSIN_DISABLE;
          master_sr_src_sel = SR_TX_CRC;
          if(cnt_tx_mode_i && cnt_txe_flag_i && cnt_crc_tx_flag_i && cnt_tick_i)
            begin
              master_set_crc_phase = ENABLE;
              master_load_sr = ENABLE;
              master_enable_tick = DISABLE;
            end
          if(cnt_tx_mode_i && !cnt_txe_flag_i)
            begin
              master_sr_src_sel = SR_TX_BUFFER;
              master_load_sr = ENABLE;
              if(cnt_tick_i)
                begin
                  master_set_txe_flag = ENABLE;
                  master_enable_tick = DISABLE;
                end
            end
          if(cnt_rx_mode_i && cnt_crc_rx_flag_i && !crc_rx_last)
            master_set_crc_rx_last = ENABLE;
          if(cnt_rx_mode_i && crc_rx_last)
            master_set_crc_phase = ENABLE;
        end
    endcase
  end

//Slave State Flop definition
always @(posedge cnt_clk_i)
  begin
    if(!cnt_rst_n_i)
      slave_state <= SLAVE_IDLE;
    else
      slave_state <= slave_next_state;
  end

always @(*)
  begin
    slave_next_state = slave_state;
    case(slave_state)
      SLAVE_IDLE:
        begin
          if(cnt_spi_en_i && cnt_slave_mode_i)
            slave_next_state = SLAVE_WAIT_SSIN_ON;
        end
      SLAVE_WAIT_SSIN_ON:
        begin
          if(!cnt_ssin_i)
            slave_next_state = SLAVE_SETUP;
          else
            if(!cnt_spi_en_i && !crc_phase)
              slave_next_state = SLAVE_IDLE;
        end 
      SLAVE_SETUP:
        begin
          slave_next_state = SLAVE_ACTIVE;
        end     
      SLAVE_ACTIVE:
        begin
          if(cnt_data_ready_i)
            slave_next_state = SLAVE_READ_BUFFER;
        end      
      SLAVE_READ_BUFFER:
        begin
          slave_next_state = SLAVE_WAIT_SSIN_OFF;
        end      
      SLAVE_WAIT_SSIN_OFF:
        begin
          if(cnt_ssin_i)
            slave_next_state = SLAVE_WAIT_SSIN_ON;
        end      
    endcase
  end
  
always @(*)
  begin
    slave_busy = ENABLE;
    slave_load_sr = DISABLE;
    slave_set_txe_flag = DISABLE;
    slave_set_first_launch = DISABLE;
    slave_set_rxne_flag = DISABLE;
    slave_set_crc_phase = DISABLE;
    slave_set_crc_rx_last = DISABLE;
    slave_clear_crc_phase = DISABLE;
    slave_clear_crc_rx = DISABLE;
    slave_clear_crc_tx = DISABLE;
    slave_clear_crc_rx_last = DISABLE;
    slave_crc_error_en = DISABLE;
    slave_sr_src_sel = SR_TX_BUFFER;
    cnt_slave_tick_en_i = DISABLE;
    slave_crc_init = DISABLE;
    case(slave_state)
      SLAVE_IDLE:
        begin
          slave_busy = DISABLE;
          if(cnt_spi_en_i && cnt_slave_mode_i)
            slave_crc_init = ENABLE;
          //slave_sr_src_sel = SR_TX_BUFFER;
          //if(cnt_spi_en_i && cnt_slave_mode_i && cnt_tx_mode_i)
          //  begin
          //    slave_set_txe_flag = ENABLE;
          //    slave_load_sr = ENABLE;
          //  end
        end
      SLAVE_WAIT_SSIN_ON:
        begin
          slave_busy = DISABLE;
          //if(!cnt_ssin_i)
          //  slave_set_first_launch = ENABLE;
          slave_sr_src_sel = SR_TX_BUFFER;
          if(!cnt_ssin_i && cnt_tx_mode_i && !crc_phase)
            begin
              slave_set_txe_flag = ENABLE;
              slave_load_sr = ENABLE;
            end
        end      
      SLAVE_SETUP:
        begin
          slave_set_first_launch = ENABLE;
        end
      SLAVE_ACTIVE:
        begin
          cnt_slave_tick_en_i = ENABLE;
        end      
      SLAVE_READ_BUFFER:
        begin
          if(!cnt_tx_only_i && !crc_phase)
            slave_set_rxne_flag = ENABLE;
        end      
      SLAVE_WAIT_SSIN_OFF:
        begin
          slave_sr_src_sel = SR_TX_CRC;
          if(cnt_tx_mode_i && cnt_txe_flag_i && cnt_crc_tx_flag_i && cnt_ssin_i && !crc_phase)
            begin
              slave_set_crc_phase = ENABLE;
              slave_load_sr = ENABLE;
            end
          if(!cnt_tx_mode_i && cnt_rx_mode_i && cnt_crc_rx_flag_i && !crc_rx_last && !crc_phase && cnt_ssin_i)
            slave_set_crc_rx_last = ENABLE;
          if(!cnt_tx_mode_i && cnt_rx_mode_i && crc_rx_last && !crc_phase && cnt_ssin_i)
            slave_set_crc_phase = ENABLE;
          if(crc_phase)
            begin
              slave_clear_crc_phase = ENABLE;
              slave_clear_crc_rx = ENABLE;
              slave_clear_crc_tx = ENABLE;
              slave_clear_crc_rx_last = ENABLE;
              slave_crc_error_en = ~cnt_tx_only_i;
            end
        end 
    endcase
  end
  
assign set_crc_phase = (cnt_master_mode_i) ? master_set_crc_phase : slave_set_crc_phase;
assign clear_crc_phase = (cnt_master_mode_i) ? master_clear_crc_phase : slave_clear_crc_phase;

assign set_crc_rx_last = (cnt_master_mode_i) ? master_set_crc_rx_last : slave_set_crc_rx_last;
assign clear_crc_rx_last = (cnt_master_mode_i) ? master_clear_crc_rx_last : slave_clear_crc_rx_last;

always @(posedge cnt_clk_i)
  begin
    if(!cnt_rst_n_i)
      crc_phase <= 1'b0;
    else
      if(set_crc_phase)
        crc_phase <= 1'b1;
      else
        if(clear_crc_phase)
          crc_phase <= 1'b0;
  end
  
always @(posedge cnt_clk_i)
  begin
    if(!cnt_rst_n_i)
      crc_rx_last <= 1'b0;
    else
      if(set_crc_rx_last)
        crc_rx_last <= 1'b1;
      else
        if(clear_crc_rx_last)
          crc_rx_last <= 1'b0;
  end
  
assign cnt_busy_o = (cnt_master_mode_i) ? master_busy : slave_busy;
assign cnt_sr_src_sel_o = (cnt_master_mode_i) ? master_sr_src_sel : slave_sr_src_sel;
assign cnt_load_sr_o = (cnt_master_mode_i) ? master_load_sr : slave_load_sr;
assign cnt_set_txe_flag_o = (cnt_master_mode_i) ? master_set_txe_flag : slave_set_txe_flag;
assign cnt_enable_tick_o = master_enable_tick; 
assign cnt_ssin_o = master_ssin;
assign cnt_enable_lauch_capture_o = master_enable_lauch_capture | cnt_slave_mode_i;
assign cnt_set_first_launch_o = slave_set_first_launch;
assign cnt_enable_sck_o = master_enable_sck;     
assign cnt_set_rxne_flag_o = (cnt_master_mode_i) ? master_set_rxne_flag : slave_set_rxne_flag;
assign cnt_clear_crc_tx_o = (cnt_master_mode_i) ? master_clear_crc_tx : slave_clear_crc_tx;
assign cnt_clear_crc_rx_o = (cnt_master_mode_i) ? master_clear_crc_rx : slave_clear_crc_rx;
assign cnt_crc_error_en_o = (cnt_master_mode_i) ? master_crc_error_en : slave_crc_error_en;
assign cnt_crc_init_o = (cnt_master_mode_i) ? master_crc_init : slave_crc_init;

endmodule
