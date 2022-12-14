----------------------------------------------------------------------------------
-- Company: EagleSat 2
-- Engineer: Trevor Butcher (CRP)
-- 
-- Create Date: 01/14/2020 02:52:26 PM
-- Design Name: 
-- Module Name: top - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity top is
  Port (board_clk : IN STD_LOGIC;
        camera_uart_tx : OUT STD_LOGIC := '1';
        camera_uart_rx : IN STD_LOGIC;
        camera2_uart_tx : OUT STD_LOGIC := '1';
        camera2_uart_rx : IN STD_LOGIC;
        uart_tx_obc : OUT STD_LOGIC := '1';
        uart_rx_obc : IN STD_LOGIC;
        test_pin : OUT STD_LOGIC;
        baud_out : OUT STD_LOGIC;
        gpio_camera_enable : IN STD_LOGIC
        
  );
end top;

architecture Behavioral of top is
signal sysclk : STD_LOGIC := '0';
signal baudclk : STD_LOGIC := '0';


constant BAUDCLK_CNT_MAX : integer := 620; -- should be 208 for 115200 at 24 MHz sysclk
signal baudclk_cnt : integer range 0 to BAUDCLK_CNT_MAX := 0;

-- uart
signal uart_tx : STD_LOGIC := '1';
signal uart_rx : STD_LOGIC := '1';
signal uartmgr_rx_data_ready : STD_LOGIC := '0';
signal uartmgr_rx_data : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
signal uartmgr_tx_data_ack : STD_LOGIC;

-- sync manager
signal syncmgr_cmd_ready : STD_LOGIC := '0';
signal syncmgr_cmd : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
signal syncmgr_cmd_ack : STD_LOGIC;
signal syncmgr_camera_is_init : STD_LOGIC := '0';
signal syncmgr_camera_err : STD_LOGIC := '0';
signal syncmgr_sync_num : STD_LOGIC_VECTOR(7 downto 0);
signal syncmgr_here : STD_LOGIC;
signal syncmgr_bytecnt : integer;
signal syncmgr_reset_done : STD_LOGIC;
-- Config manager
signal configmgr_cmd_ready : STD_LOGIC;
signal configmgr_cmd : STD_LOGIC_VECTOR(7 downto 0);
signal configmgr_cmd_ack : STD_LOGIC;
signal configmgr_camera_err : STD_LOGIC;
signal configmgr_uart_resp_syn : STD_LOGIC;
signal configmgr_uart_resp : STD_LOGIC_VECTOR(7 downto 0);
signal configmgr_camera_is_configured : STD_LOGIC;
signal configmgr_is_jpeg : STD_LOGIC;
signal configmgr_is_here : STD_LOGIC;
signal configmgr_reset_done : STD_LOGIC;
-- control signals
signal cont_camera_rst: STD_LOGIC := '0';
signal cont_img_format : STD_LOGIC_VECTOR(1 downto 0) := "01";
signal cont_resolution : STD_LOGIC := '0';
signal cont_light : STD_LOGIC := '0';
signal cont_brightness : STD_LOGIC_VECTOR(2 downto 0) := "011";
signal cont_exposure : STD_LOGIC_VECTOR(2 downto 0) := "011";
signal cont_contrast : STD_LOGIC_VECTOR(2 downto 0) := "011";
signal cont_camera_rst_done : STD_LOGIC := '1';
--- unknown
signal uart_tx_data_ready : STD_LOGIC := '0';
signal uart_tx_data : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
signal camera_enable : STD_LOGIC := '1';
-- image capture
signal img_cmd_ready : STD_LOGIC;
signal img_cmd : STD_LOGIC_VECTOR(7 downto 0);
signal img_reset_done : STD_LOGIC;
signal img_capture2_done : STD_LOGIC;
signal img_cmd_ack : STD_LOGIC;
signal img_fifo_packet_syn : STD_LOGIC;
signal img_fifo_packet : STD_LOGIC_VECTOR(47 downto 0);
signal img_streaming : STD_LOGIC;

-- FIFO
signal fifo_data_packet_ack : STD_LOGIC;
signal capture_done : STD_LOGIC;
signal fifo_full : STD_LOGIC;
signal fifo_empty : STD_LOGIC;
signal fifo_out_data_syn : STD_LOGIC;
signal fifo_out_data : STD_LOGIC_VECTOR(47 downto 0);
signal fifo_out_data_ack : STD_LOGIC;
signal fifo_index : INTEGER;
signal fifo_reset_done : STD_LOGIC;
-- image thresholding
signal thresh_capture_done : STD_LOGIC;
signal thresh_capture_out : STD_LOGIC_VECTOR(47 downto 0);
signal thresh_capture_out_syn : STD_LOGIC;
signal thresh_capture_out_ack : STD_LOGIC;
signal thresh_flux_cnt : INTEGER;
signal thresh_reset_done : STD_LOGIC;
-- command and data handling
signal cdh_out_data_req : STD_LOGIC;
signal cdh_uart_tx_data : STD_LOGIC_VECTOR(7 downto 0);
signal cdh_uart_tx_syn : STD_LOGIC;
 signal tx_stub : STD_LOGIC;
 signal echo_out : STD_LOGIC;
 signal echo_data_rx : STD_LOGIC_VECTOR(7 downto 0);
 signal echo_data_rx_syn : STD_LOGIC;
 signal echo_data_tx_ack : STD_LOGIC;
 signal reset_shunt : STD_LOGIC;
 signal cdh_here : STD_LOGIC;
 signal camsim_needs_ack : STD_LOGIC;
 
 -- uart (OBC)
 signal obc_uart_tx : STD_LOGIC := '1';
 signal obc_uart_rx : STD_LOGIC := '1';
 signal obc_uartmgr_rx_data_ready : STD_LOGIC := '0';
 signal obc_uartmgr_rx_data : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
 signal obc_uartmgr_tx_data_ack : STD_LOGIC;
 
 -- CAMERA 2 SIGNALS
 signal cam2_uart_tx : STD_LOGIC := '1';
 signal cam2_uart_rx : STD_LOGIC := '1';
 signal cam2_uartmgr_rx_data_ready : STD_LOGIC := '0';
 signal cam2_uartmgr_rx_data : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
 signal cam2_uartmgr_tx_data_ack : STD_LOGIC;
 
 -- sync manager
 signal cam2_syncmgr_cmd_ready : STD_LOGIC := '0';
 signal cam2_syncmgr_cmd : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
 signal cam2_syncmgr_cmd_ack : STD_LOGIC;
 signal cam2_syncmgr_camera_is_init : STD_LOGIC := '0';
 signal cam2_syncmgr_camera_err : STD_LOGIC := '0';
 signal cam2_syncmgr_sync_num : STD_LOGIC_VECTOR(7 downto 0);
 signal cam2_syncmgr_here : STD_LOGIC;
 signal cam2_syncmgr_bytecnt : integer;
 signal cam2_syncmgr_reset_done : STD_LOGIC;
 -- Config manager
 signal cam2_configmgr_cmd_ready : STD_LOGIC;
 signal cam2_configmgr_cmd : STD_LOGIC_VECTOR(7 downto 0);
 signal cam2_configmgr_cmd_ack : STD_LOGIC;
 signal cam2_configmgr_camera_err : STD_LOGIC;
 signal cam2_configmgr_uart_resp_syn : STD_LOGIC;
 signal cam2_configmgr_uart_resp : STD_LOGIC_VECTOR(7 downto 0);
 signal cam2_configmgr_camera_is_configured : STD_LOGIC;
 signal cam2_configmgr_is_jpeg : STD_LOGIC;
 signal cam2_configmgr_is_here : STD_LOGIC;
 signal cam2_configmgr_reset_done : STD_LOGIC;
 -- control signals
 signal cam2_cont_camera_rst: STD_LOGIC := '0';
 signal cam2_cont_camera_rst_done : STD_LOGIC := '1';
 --- unknown
 signal cam2_uart_tx_data_ready : STD_LOGIC := '0';
 signal cam2_uart_tx_data : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
 -- image capture
 signal cam2_img_cmd_ready : STD_LOGIC;
 signal cam2_img_cmd : STD_LOGIC_VECTOR(7 downto 0);
 signal cam2_img_reset_done : STD_LOGIC;
 signal cam2_img_capture2_done : STD_LOGIC;
 signal cam2_img_cmd_ack : STD_LOGIC;
 signal cam2_img_fifo_packet_syn : STD_LOGIC;
 signal cam2_img_fifo_packet : STD_LOGIC_VECTOR(47 downto 0);
 signal cam2_img_streaming : STD_LOGIC;
 
 -- FIFO
 signal cam2_fifo_data_packet_ack : STD_LOGIC;
 signal cam2_capture_done : STD_LOGIC;
 signal cam2_fifo_full : STD_LOGIC;
 signal cam2_fifo_empty : STD_LOGIC;
 signal cam2_fifo_out_data_syn : STD_LOGIC;
 signal cam2_fifo_out_data : STD_LOGIC_VECTOR(47 downto 0);
 signal cam2_fifo_out_data_ack : STD_LOGIC;
 signal cam2_fifo_index : INTEGER;
 signal cam2_fifo_reset_done : STD_LOGIC;
 -- image thresholding
 signal cam2_thresh_capture_done : STD_LOGIC;
 signal cam2_thresh_capture_out : STD_LOGIC_VECTOR(47 downto 0);
 signal cam2_thresh_capture_out_syn : STD_LOGIC;
 signal cam2_thresh_capture_out_ack : STD_LOGIC;
 signal cam2_thresh_flux_cnt : INTEGER;
 signal cam2_thresh_reset_done : STD_LOGIC;
begin
-- I/O signals
test_pin <= cdh_here;
sysclk <= board_clk;
camera2_uart_tx <= cam2_uart_tx;
cam2_uart_rx <= camera2_uart_rx;
camera_uart_tx <= uart_tx;
uart_rx <= camera_uart_rx;
uart_tx_obc <= obc_uart_tx;
obc_uart_rx <= uart_rx_obc;
--camera_enable <= not gpio_camera_enable;
baud_out <= obc_uart_tx;
---- clock gen
--process
--begin
--wait for 1 ns;
--sysclk <= '1';
--wait for 1 ns; 
--sysclk <= '0';
--end process;

process(sysclk)
begin
    if(rising_edge(sysclk)) then
        baudclk_cnt <= baudclk_cnt + 1;
        if(baudclk_cnt = BAUDCLK_CNT_MAX) then
            baudclk_cnt <= 0;
            baudclk <= not baudclk;
        end if;
    end if;
end process;

uartecho : entity work.uartmgr
    Port map ( i_baudclk => baudclk, -- UART logic clock
          o_uart_tx => echo_out, -- UART send
          i_uart_rx => tx_stub, -- UART recieve
          o_rx_data_ready => echo_data_rx_syn, -- Signal indicating that data has been received.
          o_rx_data => echo_data_rx, -- signal containing received UART data
          i_tx_data_ready => uartmgr_rx_data_ready, -- Signal indicating that data is ready to be read by this module
          i_tx_data => uartmgr_rx_data, -- Signal containing data to be sent over UART
          o_tx_data_ack => echo_data_tx_ack -- Signal indicating that the manager has acknowledged the incoming data. Is '0' when not busy.
    
    );
---- camera simulator
--camsim : entity work.camera_sim
--Port map (
--  clk => baudclk,
--  tx => uart_rx,
--  send_bytecnt => syncmgr_bytecnt,
--  waiting_to_send => camsim_waiting_to_send,
--  sending => camsim_sending,
--  needs_ack => camsim_needs_ack,
--  send_ack => camsim_send_ack
--);
-- sync manager
sync : entity work.sync_mgr
  Port map (i_clk => sysclk, -- Logic clock
        o_cmd_ready => syncmgr_cmd_ready,-- HIGH when a command is ready to be sent
        o_cmd => syncmgr_cmd, -- Command data out
        i_cmd_ack => syncmgr_cmd_ack,-- ACK from the uart manager indicating that transmission of a command is complete.
        o_camera_is_init => syncmgr_camera_is_init, -- Signal indicating camera initialization status
        o_camera_init_err => syncmgr_camera_err, -- Signal indicating initialization error, such as sync timeout
        i_camera_en => camera_enable, -- HIGH when camera is enabled. Will begin configuration when this is high.
        i_uart_resp => uartmgr_rx_data,
        i_camera_rst => cont_camera_rst,
        o_reset_done => syncmgr_reset_done,
        here => syncmgr_here,
        sync_num => syncmgr_sync_num,
        bytecnt => syncmgr_bytecnt,
        i_uart_resp_syn => uartmgr_rx_data_ready
        );
-- Uart manager
uart : entity work.uartmgr
  Port map ( i_baudclk => baudclk, -- UART logic clock
        o_uart_tx => uart_tx, -- UART send
        i_uart_rx => uart_rx, -- UART recieve
        o_rx_data_ready => uartmgr_rx_data_ready, -- Signal indicating that data has been received.
        o_rx_data => uartmgr_rx_data, -- signal containing received UART data
        i_tx_data_ready => uart_tx_data_ready, -- Signal indicating that data is ready to be read by this module
        i_tx_data => uart_tx_data, -- Signal containing data to be sent over UART
        o_tx_data_ack => uartmgr_tx_data_ack -- Signal indicating that the manager has acknowledged the incoming data. Is '0' when not busy.
  
  );

-- uart multiplexer
uart_mux : entity work.uart_multiplexer
Port map (i_clk => sysclk,
      o_uart_syn => uart_tx_data_ready,
      i_uart_ack => uartmgr_tx_data_ack,
      o_uart_data => uart_tx_data,
      i_sync_syn => syncmgr_cmd_ready,
      o_sync_ack => syncmgr_cmd_ack,
      i_sync_data => syncmgr_cmd,
      
      -- CONFIG
      i_config_syn => configmgr_cmd_ready,
      o_config_ack => configmgr_cmd_ack,
      i_config_data => configmgr_cmd,
      
      -- STREAMING
      i_stream_syn => img_cmd_ready,
      o_stream_ack => img_cmd_ack,
      i_stream_data => img_cmd,
      
      -- CONTROL SIGNALS
      i_camera_enable => camera_enable,
      i_sync_done => syncmgr_camera_is_init,
      i_config_done => configmgr_camera_is_configured 
);

-- Camera capture logic
img_cap : entity work.image_capture 
  Port map ( i_clk => sysclk, -- logic clock
        o_cmd_ready =>img_cmd_ready,
        o_cmd => img_cmd,
        i_cmd_ack => img_cmd_ack,
        i_fifo_full => fifo_full,
        i_capture1_done => thresh_capture_done,
        i_capture2_done => cam2_thresh_capture_done,
        i_is_jpeg =>configmgr_is_jpeg,
        i_camera_rst => cont_camera_rst,
        o_reset_done => img_reset_done,
        i_camera_ready => configmgr_camera_is_configured,
        o_data_packet_syn => img_fifo_packet_syn,
        o_camera_is_streaming => img_streaming
  );
-- Image thresholding logic
imgthresh : entity work.image_thresholding
  Port map (i_clk =>sysclk,
        i_camera_is_streaming => img_streaming,
        i_img_resolution => cont_resolution,
        i_is_jpeg => configmgr_is_jpeg,
        i_camera_en => camera_enable,
        i_fifo_full => fifo_full,
        i_camera_reset => cont_camera_rst,
        o_reset_done => thresh_reset_done,
        i_uart_data_syn => uartmgr_rx_data_ready,
        i_uart_data => uartmgr_rx_data,
        o_flux_count => thresh_flux_cnt,
        o_capture_done => thresh_capture_done,
        
        o_packet_out => thresh_capture_out,
        o_packet_out_syn => thresh_capture_out_syn,
        i_packet_out_ack => thresh_capture_out_ack
        
  );
-- FIFO
fifo_inst : entity work.fifo
    Port map(i_clk => sysclk,
          i_in_data_syn => thresh_capture_out_syn,
          i_in_data => thresh_capture_out,
          o_in_data_ack => thresh_capture_out_ack,
          i_out_data_req => cdh_out_data_req,
          o_fifo_full => fifo_full,
          i_camera_reset => cont_camera_rst,
          o_reset_done => fifo_reset_done,
          o_fifo_index_out => fifo_index,
          o_out_data_syn => fifo_out_data_syn,
          o_fifo_empty => fifo_empty,
          o_out_data => fifo_out_data,
          i_out_data_ack => fifo_out_data_ack
    );
cont_camera_rst_done <= configmgr_reset_done and thresh_reset_done and img_reset_done and syncmgr_reset_done;
-- Command and data handling
cdh : entity work.cAndDH
  Port map (i_clk => sysclk,
        
        -- uart
        i_uart_rx_syn => obc_uartmgr_rx_data_ready,
        i_uart_rx_data =>  obc_uartmgr_rx_data,
        o_uart_tx_data => cdh_uart_tx_data,
        o_uart_tx_syn => cdh_uart_tx_syn,
        i_uart_tx_ack =>  obc_uartmgr_tx_data_ack,
        i_fifo_index => fifo_index,
        here => cdh_here,
        i_flux_cnt => thresh_flux_cnt,
        -- data
         o_out_data_req => cdh_out_data_req,
         i_fifo_full => fifo_full,
         i_out_data_syn => fifo_out_data_syn,
         i_fifo_empty => fifo_empty,
         i_camera_in_error => syncmgr_camera_err,
         i_out_data => fifo_out_data,
         o_out_data_ack => fifo_out_data_ack,
        
         -- command registers
         i_rst_done => cont_camera_rst_done,
         o_camera_rst => cont_camera_rst, -- Indicates whether to send a soft reset
         o_image_format => cont_img_format, 
         o_resolution => cont_resolution
  );    
-- Uart manager (to OBC)
  uart_obc : entity work.uartmgr
    Port map ( i_baudclk => baudclk, -- UART logic clock
          o_uart_tx => obc_uart_tx, -- UART send
          i_uart_rx => obc_uart_rx, -- UART recieve
          o_rx_data_ready => obc_uartmgr_rx_data_ready, -- Signal indicating that data has been received.
          o_rx_data => obc_uartmgr_rx_data, -- signal containing received UART data
          i_tx_data_ready => cdh_uart_tx_syn, -- Signal indicating that data is ready to be read by this module
          i_tx_data => cdh_uart_tx_data, -- Signal containing data to be sent over UART
          o_tx_data_ack => obc_uartmgr_tx_data_ack -- Signal indicating that the manager has acknowledged the incoming data. Is '0' when not busy.
    
    );
-- Configuration manager
config_mgr: entity work.camera_config_mgr
  Port map(
        -- function ports
        i_clk => sysclk,-- Logic clock
        o_cmd_ready => configmgr_cmd_ready, -- HIGH when a command is ready to be sent
        o_cmd => configmgr_cmd, -- Command data out
        o_here => configmgr_is_here,
        i_cmd_ack => configmgr_cmd_ack,-- ACK from the uart manager indicating that transmission of a command is complete.
        i_camera_init =>syncmgr_camera_is_init, -- Signal indicating camera initialization status
        o_camera_init_err => configmgr_camera_err, -- Signal indicating initialization error, such as sync timeout
        i_camera_resp_syn => configmgr_uart_resp_syn,-- signal indicating that data has been read from the camera
        i_camera_resp => configmgr_uart_resp, -- Camera response
        o_camera_configured => configmgr_camera_is_configured,
        o_is_jpeg => configmgr_is_jpeg, -- Signal indicating if the camera is in a JPEG configuration.
        i_sync_num => syncmgr_sync_num,
        o_needs_ack => camsim_needs_ack,
        o_reset_done => configmgr_reset_done,
        -- Configuration ports
        i_camera_en => camera_enable,-- HIGH when camera is enabled. Will begin configuration when this is high.
        i_camera_rst => cont_camera_rst, -- Indicates whether to send a soft reset
        i_image_format => cont_img_format,
        
        i_resolution => cont_resolution,
        i_light => cont_light,
        i_contrast => cont_contrast,
        i_exposure => cont_exposure,
        i_brightness => cont_brightness
  );
-- CAMERA 2
-- sync manager
cam2_sync : entity work.sync_mgr
  Port map (i_clk => sysclk, -- Logic clock
        o_cmd_ready => cam2_syncmgr_cmd_ready,-- HIGH when a command is ready to be sent
        o_cmd => cam2_syncmgr_cmd, -- Command data out
        i_cmd_ack => cam2_syncmgr_cmd_ack,-- ACK from the uart manager indicating that transmission of a command is complete.
        o_camera_is_init => cam2_syncmgr_camera_is_init, -- Signal indicating camera initialization status
        o_camera_init_err => cam2_syncmgr_camera_err, -- Signal indicating initialization error, such as sync timeout
        i_camera_en => camera_enable, -- HIGH when camera is enabled. Will begin configuration when this is high.
        i_uart_resp => cam2_uartmgr_rx_data,
        i_camera_rst => cont_camera_rst,
        o_reset_done => cam2_syncmgr_reset_done,
        here => cam2_syncmgr_here,
        sync_num => cam2_syncmgr_sync_num,
        bytecnt => cam2_syncmgr_bytecnt,
        i_uart_resp_syn => cam2_uartmgr_rx_data_ready
        );
-- Uart manager
cam2_uart : entity work.uartmgr
  Port map ( i_baudclk => baudclk, -- UART logic clock
        o_uart_tx => cam2_uart_tx, -- UART send
        i_uart_rx => cam2_uart_rx, -- UART recieve
        o_rx_data_ready => cam2_uartmgr_rx_data_ready, -- Signal indicating that data has been received.
        o_rx_data => cam2_uartmgr_rx_data, -- signal containing received UART data
        i_tx_data_ready => cam2_uart_tx_data_ready, -- Signal indicating that data is ready to be read by this module
        i_tx_data => cam2_uart_tx_data, -- Signal containing data to be sent over UART
        o_tx_data_ack => cam2_uartmgr_tx_data_ack -- Signal indicating that the manager has acknowledged the incoming data. Is '0' when not busy.
  
  );

-- uart multiplexer
cam2_uart_mux : entity work.uart_multiplexer
Port map (i_clk => sysclk,
      o_uart_syn => cam2_uart_tx_data_ready,
      i_uart_ack => cam2_uartmgr_tx_data_ack,
      o_uart_data => cam2_uart_tx_data,
      i_sync_syn => cam2_syncmgr_cmd_ready,
      o_sync_ack => cam2_syncmgr_cmd_ack,
      i_sync_data => cam2_syncmgr_cmd,
      
      -- CONFIG
      i_config_syn => cam2_configmgr_cmd_ready,
      o_config_ack => cam2_configmgr_cmd_ack,
      i_config_data => cam2_configmgr_cmd,
      
      -- STREAMING
      i_stream_syn => cam2_img_cmd_ready,
      o_stream_ack => cam2_img_cmd_ack,
      i_stream_data => cam2_img_cmd,
      
      -- CONTROL SIGNALS
      i_camera_enable => camera_enable,
      i_sync_done => cam2_syncmgr_camera_is_init,
      i_config_done => cam2_configmgr_camera_is_configured 
);

-- Camera capture logic
cam2_img_cap : entity work.image_capture 
  Port map ( i_clk => sysclk, -- logic clock
        o_cmd_ready =>cam2_img_cmd_ready,
        o_cmd => cam2_img_cmd,
        i_cmd_ack => cam2_img_cmd_ack,
        i_fifo_full => cam2_fifo_full,
        i_capture1_done => cam2_thresh_capture_done,
        i_capture2_done => thresh_capture_done,
        i_is_jpeg =>cam2_configmgr_is_jpeg,
        i_camera_rst => cont_camera_rst,
        o_reset_done => cam2_img_reset_done,
        i_camera_ready => cam2_configmgr_camera_is_configured,
        o_data_packet_syn => cam2_img_fifo_packet_syn,
        o_camera_is_streaming => cam2_img_streaming
  );
-- Image thresholding logic
cam2_imgthresh : entity work.image_thresholding
  Port map (i_clk =>sysclk,
        i_camera_is_streaming => cam2_img_streaming,
        i_img_resolution => cont_resolution,
        i_is_jpeg => configmgr_is_jpeg,
        i_camera_en => camera_enable,
        i_fifo_full => cam2_fifo_full,
        i_camera_reset => cont_camera_rst,
        o_reset_done => cam2_thresh_reset_done,
        i_uart_data_syn => cam2_uartmgr_rx_data_ready,
        i_uart_data => cam2_uartmgr_rx_data,
        o_flux_count => cam2_thresh_flux_cnt,
        o_capture_done => cam2_thresh_capture_done,
        
        o_packet_out => cam2_thresh_capture_out,
        o_packet_out_syn => cam2_thresh_capture_out_syn,
        i_packet_out_ack => cam2_thresh_capture_out_ack
        
  );
-- FIFO
cam2_fifo_inst : entity work.fifo
    Port map(i_clk => sysclk,
          i_in_data_syn => cam2_thresh_capture_out_syn,
          i_in_data => cam2_thresh_capture_out,
          o_in_data_ack => cam2_thresh_capture_out_ack,
          i_out_data_req => cdh_out_data_req,
          o_fifo_full => cam2_fifo_full,
          i_camera_reset => cont_camera_rst,
          o_reset_done => cam2_fifo_reset_done,
          o_fifo_index_out => cam2_fifo_index,
          o_out_data_syn => cam2_fifo_out_data_syn,
          o_fifo_empty => cam2_fifo_empty,
          o_out_data => cam2_fifo_out_data,
          i_out_data_ack => cam2_fifo_out_data_ack
    );
end Behavioral;
