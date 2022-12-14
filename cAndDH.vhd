----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01/16/2020 11:46:51 AM
-- Design Name: 
-- Module Name: cAndDH - Behavioral
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

entity cAndDH is
  Port (i_clk : IN STD_LOGIC;
        
        -- uart
        i_uart_rx_syn : IN STD_LOGIC;
        i_uart_rx_data : IN STD_LOGIC_VECTOR(7 downto 0);
        o_uart_tx_data : OUT STD_LOGIC_VECTOR(7 downto 0);
        o_uart_tx_syn : OUT STD_LOGIC;
        i_uart_tx_ack : IN STD_LOGIC;
         i_camera_in_error : IN STD_LOGIC;
        -- data
         o_out_data_req : OUT STD_LOGIC;
         i_fifo_full : IN STD_LOGIC;
         i_out_data_syn : IN STD_LOGIC;
         i_fifo_empty : IN STD_LOGIC;
         i_fifo_index : IN UNSIGNED(31 downto 0);
         i_flux_cnt : IN UNSIGNED(31 downto 0);
         i_out_data : IN STD_LOGIC_VECTOR(39 downto 0);
         o_out_data_ack : OUT STD_LOGIC;
         here : OUT STD_LOGIC;
         o_camera_enable : OUT STD_LOGIC := '1';
         o_contrast : OUT STD_LOGIC_VECTOR(2 downto 0) := "010";
         o_brightness : OUT STD_LOGIC_VECTOR(2 downto 0):= "010";
         o_exposure : OUT STD_LOGIC_VECTOR(2 downto 0) := "010";
         o_light : OUT STD_LOGIC;
         -- command registers
         o_threshold_value : OUT STD_LOGIC_VECTOR(7 downto 0) := x"50";
         i_rst_done : IN STD_LOGIC;
         o_camera_rst : OUT STD_LOGIC := '1'; -- Indicates whether to send a soft reset
         o_cut_power_camera : OUT STD_LOGIC := '1';
         o_image_format : OUT STD_LOGIC_VECTOR(1 downto 0); 
         o_resolution : OUT STD_LOGIC
  );
end cAndDH;

architecture Behavioral of cAndDH is
type data_byte_type is array (4 downto 0) of STD_LOGIC_VECTOR(7 downto 0);
signal data_byte : data_byte_type;
constant DATA_LENGTH_BYTES : integer := 5;
signal data_byte_counter : integer range 0 to DATA_LENGTH_BYTES := 0;
signal resolution_toggle : STD_LOGIC := '0';
signal camera_enable_toggle : STD_LOGIC := '1';

constant WAIT_MAX : integer := 1000000;
signal wait_counter : integer range 0 to WAIT_MAX := 0;
-- Incoming commands
constant get_health : STD_LOGIC_VECTOR(7 downto 0) := x"00";
constant get_fifo_index : STD_LOGIC_VECTOR(7 downto 0) := x"04";
constant get_flux : STD_LOGIC_VECTOR(7 downto 0) := x"05";
constant start_readout : STD_LOGIC_VECTOR(7 downto 0) := x"16";
constant set_threshold : STD_LOGIC_VECTOR(7 downto 0) := x"01";
constant ready_to_send : STD_LOGIC_VECTOR(7 downto 0) := x"1F";
constant camera_enable_packet: STD_LOGIC_VECTOR(7 downto 0) := x"15";
-- camera configuration settings
constant toggle_jpeg : STD_LOGIC_VECTOR(7 downto 0) := x"1e";
constant soft_reset : STD_LOGIC_VECTOR(7 downto 0) := x"0F";
constant cam_power_off : STD_LOGIC_VECTOR(7 downto 0) := x"0E";
constant cam_power_on : STD_LOGIC_VECTOR(7 downto 0) := x"0D";
constant toggle_light : STD_LOGIC_VECTOR(7 downto 0) := x"06";
signal config_setting : STD_LOGIC_VECTOR(2 downto 0) := "000";

constant fifo_empty_packet : STD_LOGIC_VECTOR(7 downto 0) := x"12";
constant fifo_has_data_packet : STD_LOGIC_VECTOR(7 downto 0) := x"13";
-- Packets to send to OBC to designate camera health
constant cam_broke : STD_LOGIC_VECTOR(7 downto 0) := x"1A";
constant cam_healthy : STD_LOGIC_VECTOR(7 downto 0) := x"1B";
-- Signal tracking if the camera is healthy 1 if yes, 0 if no
signal cam_health : std_logic := '1';

signal already_sent : STD_LOGIC := '0';
signal threshold_val : STD_LOGIC_VECTOR(7 downto 0) := x"50";
type state_type is (init, interpet_cmd,send_getdata, send_isempty, wait_isempty, send_ff, send_health, wait_send_health, 
                    wait_send_ff, send_final_fd, wait_final_fd, wait_getdata, send_cmd, wait_send, get_data,
                    send_uart_data, wait_uart_data, stream_data, reset_cam, send_number_data, wait_number_data,
                    set_threshold_high, set_threshold_low, power_on, power_off, wait_power);
signal current_state : state_type := init;
signal ff_cnt : integer := 0;
signal camera_rst : STD_LOGIC := '0';
signal light_toggle: STD_LOGIC := '0';
signal data_counter : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
begin
here <= '1' when current_state = init else '0';
o_resolution <= resolution_toggle;
o_light <= light_toggle;
o_camera_rst <= not camera_rst; -- The Camera reset pin is active low
                                -- So, we have to invert the internal reset tracker
o_threshold_value <= threshold_val;
o_camera_enable <= camera_enable_toggle;
o_image_format <= "10" when resolution_toggle = '0' else "01";
process(i_clk)
begin
    if(rising_edge(i_clk)) then
        case current_state is
            when init =>
                wait_counter <= wait_counter + 1;
                ff_cnt <= 0;
                if(wait_counter = WAIT_MAX) then
                    wait_counter <= 0;
                    already_sent <= '0';
                end if;
                o_uart_tx_data <= (others => '0');
                o_uart_tx_syn <= '0';
                o_out_data_req <= '0';
               -- here <= '1';
                o_out_data_ack <= '0';
                if(i_uart_rx_syn = '1') then
                    current_state <= interpet_cmd;
                end if;
                if(i_fifo_full = '1' and already_sent = '0') then
                    current_state <= send_getdata;
                end if;
            when send_isempty =>
                o_uart_tx_syn <= '1';
                if(i_fifo_empty = '1') then
                    o_uart_tx_data <= fifo_empty_packet;
                else 
                    o_uart_tx_data <= fifo_has_data_packet;
                end if;
                if(i_uart_tx_ack = '1') then
                    current_state <= wait_isempty;
                end if;
            when wait_isempty =>
                o_uart_tx_syn <= '0';
                if(i_uart_tx_ack = '0') then
                    already_sent <= '1';
                    current_state <= init;
                end if;
            when send_health =>
                o_uart_tx_syn <= '1';
                if(cam_health = '0') then
                    o_uart_tx_data <= cam_broke;
                    camera_rst <= '1';
                else
                    o_uart_tx_data <= cam_healthy;
                end if;
                if(i_uart_tx_ack = '1') then
                    current_state <= wait_send_health;
                end if;
            when wait_send_health =>
                o_uart_tx_syn <= '0';
                if(i_uart_tx_ack = '0') then
                    already_sent <= '1';
                    camera_rst <= '0';
                    current_state <= init;
                end if;
            when power_on =>
                o_cut_power_camera <= '0';
                current_state <= init;
            when power_off =>
                o_cut_power_camera <= '1';
                current_state <= init;                
            when send_number_data =>
                o_uart_tx_syn <= '1';
                o_uart_tx_data <= data_counter;
                if(i_uart_tx_ack = '1') then
                    current_state <= wait_number_data;
                end if;
            when wait_number_data =>
                o_uart_tx_syn <= '0';
                if(i_uart_tx_ack = '0') then
                    current_state <= init;
                end if;
            when send_getdata =>
                o_uart_tx_syn <= '1';
                o_uart_tx_data <= x"AF";
                if(i_uart_tx_ack = '1') then
                current_state <= wait_getdata;
                end if;
            when wait_getdata =>
                o_uart_tx_syn <= '0';
                if(i_uart_tx_ack = '0') then
                    already_sent <= '1';
                    current_state <= init;
                end if;
            when interpet_cmd =>
                case i_uart_rx_data is
                    when cam_power_on =>
                        current_state <= power_on;
                    when cam_power_off =>
                        current_state <= power_off;
                    when get_health => 
                        if(i_camera_in_error = '1') then
                            cam_health <= '0';
                        else
                            cam_health <= '1';
                        end if;
                        current_state <= send_health;
                    when set_threshold =>
                        current_state <= set_threshold_high;
                    when get_fifo_index =>
                        current_state <= send_isempty;
                        data_counter <= std_logic_vector(i_fifo_index(7 downto 0));
                    when get_flux =>
                        current_state <= send_number_data;
                        data_counter <= std_logic_vector(i_flux_cnt(7 downto 0));
                    when start_readout =>
                        current_state <= send_ff;
                        already_sent <= '0';
                    when toggle_jpeg =>
                        resolution_toggle <= not resolution_toggle;
                        current_state <= init;
                    when toggle_light =>
                        light_toggle <= not light_toggle;
                        current_state <= init;
                    when camera_enable_packet =>
                        camera_enable_toggle <= not camera_enable_toggle;
                        current_state <= init;
                    when "00001000" => -- Contrast 1
                        o_contrast <= "001";
                        current_state <= init;
                    when "00001001" => -- Contrast 2
                        o_contrast <= "010";
                        current_state <= init;
                    when "00001010" => -- Contrast 3
                        o_contrast <= "011";
                        current_state <= init;
                    when "00001011" => -- Contrast 4
                        o_contrast <= "100";
                        current_state <= init;
                    when "00001100" => -- Contrast 5
                        o_contrast <= "111";
                        current_state <= init;
                        
                    when "00010000" => -- Brightness 1
                        o_brightness <= "001";
                        current_state <= init;
                    when "00010001" => -- Brightness 2
                        o_brightness <= "010";
                        current_state <= init;
                    when "00010010" => -- Brightness 3
                        o_brightness <= "011";
                        current_state <= init;
                    when "00010011" => -- Brightness 4
                        o_brightness <= "100";
                        current_state <= init;
                    when "00100100" => -- Brightness 5
                        o_brightness <= "111";
                        current_state <= init;
                    
                    when "00011000" => -- Exposure 1
                        o_exposure <= "001";
                        current_state <= init;
                    when "00011001" => -- Exposure 2
                        o_exposure <= "010";
                        current_state <= init;
                    when "00011010" => -- Exposure 3
                        o_exposure <= "011";
                        current_state <= init;
                    when "00011011" => -- Exposure 4
                        o_exposure <= "100";
                        current_state <= init;
                    when "00011100" => -- Exposure 5
                        o_exposure <= "111";
                        current_state <= init;

                    when soft_reset =>
                        camera_rst <= '1';
                        current_state <= reset_cam;
                    
                    when others =>
                        current_state <= init; -- catchall
                end case;
            when send_ff =>
            
                o_uart_tx_syn <= '1';
                o_uart_tx_data <= x"FF";
                if(i_uart_tx_ack = '1') then
                ff_cnt <= ff_cnt + 1;
                current_state <= wait_send_ff;
                end if;
            when wait_send_ff =>
                o_uart_tx_syn <= '0';
                if(i_uart_tx_ack = '0') then
                    already_sent <= '1';
                    if(ff_cnt = 6) then
                    current_state <= stream_data;
                    ff_cnt <= 0;
                    else
                        current_state <= send_ff;
                    end if;
                end if;
            when reset_cam =>
                if(i_rst_done = '1') then
                    camera_rst <= '0';
                    current_state <= init;
                end if;
            when stream_data =>
                data_byte_counter <= 0;
                
                if(i_fifo_empty = '1') then
                    current_state <= send_final_fd;
                else
                    o_out_data_req <= '1';
                    current_state <= get_data;
                 --   here <= '1';
                end if;
            when send_final_fd =>
               o_uart_tx_syn <= '1';
               o_uart_tx_data <= x"FD";
               if(i_uart_tx_ack = '1') then
               ff_cnt <= ff_cnt + 1;
               current_state <= wait_final_fd;
               end if;
           when wait_final_fd =>
               o_uart_tx_syn <= '0';
               if(i_uart_tx_ack = '0') then
                   if(ff_cnt = 6) then
                   current_state <= init;
                   ff_cnt <= 0;
                   else
                       current_state <= send_final_fd;
                   end if;
               end if;
            when get_data =>
                if(i_out_data_syn = '1') then
                    data_byte_counter <= 0;
                    data_byte(0) <= i_out_data(7 downto 0);
                    data_byte(1) <= i_out_data(15 downto 8);
                    data_byte(2) <= i_out_data(23 downto 16);
                    data_byte(3) <= i_out_data(31 downto 24);
                    data_byte(4) <= i_out_data(39 downto 32);
                    o_out_data_ack <= '1';
                    current_state <= send_uart_data;
                end if;
            when send_uart_data =>
                o_out_data_ack <= '0';
                if(i_uart_tx_ack = '0') then
                    o_uart_tx_data <= data_byte(0);
                    
                    current_state <= wait_uart_data;
                    o_uart_tx_syn <= '1';
                end if;
            when wait_uart_data =>
                if(i_uart_tx_ack = '1') then
                    o_uart_tx_syn <= '0';
                    data_byte(3 downto 0) <= data_byte(4 downto 1);
                    data_byte_counter <= data_byte_counter + 1;
                    if(data_byte_counter = DATA_LENGTH_BYTES) then
                        current_state <= stream_data;
                    else
                        current_state <= wait_send;
                    end if;
                end if;
            when wait_send =>
                wait_counter <= wait_counter + 1;
                if(wait_counter = WAIT_MAX) then
                    wait_counter <= 0;
                    current_state <= send_uart_data;
                end if;
            when set_threshold_high =>
                if(i_uart_rx_syn = '1') then
                    threshold_val(7 downto 4) <= i_uart_rx_data(3 downto 0);
                    current_state <= set_threshold_low;
                end if;
            when set_threshold_low =>
                if(i_uart_rx_syn = '1') then
                    threshold_val(3 downto 0) <= i_uart_rx_data(3 downto 0);
                    current_state <= init;
                end if;
            when others =>
                current_state <= init;
        end case;
    end if;
end process;

end Behavioral;
