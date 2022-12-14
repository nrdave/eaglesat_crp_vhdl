----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Trevor Butcher (CRP)
-- 
-- Create Date: 01/14/2020 09:34:21 AM
-- Design Name: 
-- Module Name: camera_config_mgr - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- This module handles timing of camera configuration commands.
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity camera_config_mgr is
  Port (
        -- function ports
        i_clk : IN STD_LOGIC; -- Logic clock
        o_cmd_ready : OUT STD_LOGIC := '0'; -- HIGH when a command is ready to be sent
        o_cmd : OUT STD_LOGIC_VECTOR(7 downto 0); -- Command data out
        i_cmd_ack : IN STD_LOGIC; -- ACK from the uart manager indicating that transmission of a command is complete.
        i_camera_init : IN STD_LOGIC; -- Signal indicating camera initialization status
        o_camera_init_err : OUT STD_LOGIC; -- Signal indicating initialization error, such as sync timeout
        i_camera_resp_syn : IN STD_LOGIC; -- signal indicating that data has been read from the camera
        i_camera_resp : IN STD_LOGIC_VECTOR(7 downto 0); -- Camera response
        o_camera_configured : OUT STD_LOGIC;
        i_sync_num : IN STD_LOGIC_VECTOR(7 downto 0);
        o_is_jpeg : OUT STD_LOGIC; -- Signal indicating if the camera is in a JPEG configuration.
        o_here : OUT STD_LOGIC;
        o_needs_ack : OUT STD_LOGIC;
        o_reset_done : OUT STD_LOGIC;
        -- Configuration ports
        i_camera_en : IN STD_LOGIC; -- HIGH when camera is enabled. Will begin configuration when this is high.
        i_camera_rst : IN STD_LOGIC; -- Indicates whether to send a soft reset
        -- Image format: Indicates the desired format of the image
        -- Possible values:
        -- 00 - 8-bit grayscale (RAW)
        -- 01 - 16-bit RGB color (RAW)
        -- 10 - JPEG
        i_image_format : IN STD_LOGIC_VECTOR(1 downto 0); 
        
        -- Resolution:
        -- Possible values:
        -- 0 - 160x120 (raw mode) 640x480 (JPEG)
        -- 1 - 128x128 (raw mode)
        i_resolution : IN STD_LOGIC;
        
        --Light
        -- Possible values:
        -- 0 - 50 Hz
        -- 1 - 60 Hz
        i_light : IN STD_LOGIC;
        
        -- Contrast
        -- Possible values:
        -- 001 - Min
        -- 010 - Low
        -- 011 - Normal
        -- 100 - High
        -- 111 - Max
        i_contrast : IN STD_LOGIC_VECTOR(2 downto 0);
        -- Exposure
        -- Possible values:
        -- 001 - Min
        -- 010 - Low
        -- 011 - Normal
        -- 100 - High
        -- 111 - Max
        i_exposure : IN STD_LOGIC_VECTOR(2 downto 0);
        -- Contrast
        -- Possible values:
        -- 001 - Min
        -- 010 - Low
        -- 011 - Normal
        -- 100 - High
        -- 111 - Max
        i_brightness : IN STD_LOGIC_VECTOR(2 downto 0)
  );
end camera_config_mgr;

architecture Behavioral of camera_config_mgr is
type packet_format is array(0 to 5) of STD_LOGIC_VECTOR(7 downto 0);
-- Packet initialization
signal packet_to_send : packet_format;
signal get_picture_packet : packet_format := (x"aa",x"04",x"00",x"00",x"00",x"00");
signal snapshot_packet : packet_format := (x"aa",x"05",x"00",x"00",x"00",x"00");
signal set_baud_packet : packet_format := (x"aa",x"07",x"00",x"00",x"00",x"00");
constant reset_packet : packet_format := (x"aa",x"08",x"00",x"00",x"00",x"00");
constant sleep_packet : packet_format := (x"aa",x"15",x"00",x"00",x"00",x"00");

signal resp_packet : packet_format;
signal has_ack : STD_LOGIC := '0';
signal ACK : packet_format := (x"aa",x"0E",x"00",x"00",x"00",x"00");
constant NAK : packet_format := (x"aa",x"0F",x"00",x"00",x"00",x"00");
-- FSM initialization
type state_type is (init, init_camera, wait_init, send_ack, set_reset, set_package, wait_state, set_snapshot, set_light,set_sleep, set_contrast, send_packet, wait_transmit, get_resp, wait_resp, interpet_resp, fail_state, fin);
signal current_state : state_type := init;
signal return_state : state_type := init;
signal wait_cnt : integer := 0;
-- receive and transmit vectors
signal rx_data : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
signal tx_data : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');

signal reset_loop : STD_LOGIC := '0';

signal byte_counter : integer range 0 to 5 := 0;
signal sync_counter : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
constant SYNC_WAIT_CNT : integer := 1000;
signal wait_counter : integer := 0;
begin
o_needs_ack <= has_ack when (current_state = get_resp) else '0';
o_here <= '1' when current_state = wait_state else '0';
o_reset_done <= '1' when current_state = init else '0';
main_proc : process(i_clk)
variable init_packet : packet_format := (x"aa",x"01",x"00",x"03",x"03",x"07");
variable v_contrast_packet : packet_format := (x"aa",x"14",x"00",x"00",x"00",x"00");
variable v_light_packet : packet_format := (x"aa",x"13",x"00",x"00",x"00",x"00");
variable v_package_size_packet : packet_format := (x"aa",x"05",x"01",x"00",x"00",x"00");
begin
    if(rising_edge(i_clk)) then
     FSM : case current_state is
        when init =>
            -- Reset all signals
            byte_counter <= 0;
            o_is_jpeg <= '0';
            o_camera_init_err <= '0';
            o_cmd <= (others => '0');
            o_cmd_ready <= '0';
            wait_counter <= 0;
            o_camera_configured <= '0';
            sync_counter <= (others => '0');
            if(i_camera_rst = '1' and reset_loop = '0') then
                current_state <= set_reset;
            end if;
            if(i_camera_en = '1' and i_camera_init = '1') then
                current_state <= send_ack;
                reset_loop <= '0';
                ACK(3) <= i_sync_num;
            end if;
        when send_ack =>
            packet_to_send <= ACK;
            if(i_cmd_ack = '0') then
                current_state <= send_packet;
                return_state <= wait_init;
            end if;
        when wait_init => 
            wait_counter <= wait_counter + 1;
            if(wait_counter >=100000) then
                wait_counter <= 0;
                current_state <= init_camera;
            end if;
        when init_camera =>
--            case i_image_format is
--                when "00" =>
--                    init_packet(3) := x"03";
--                when "01" =>
--                    init_packet(3) := x"08";
--                when "10" =>
--                    init_packet(3) := x"07";
--                    o_is_jpeg <= '1';
--                when others =>
--                    init_packet(3) := x"08";
--            end case;
--            if(i_resolution = '1') then
--                init_packet(4) := x"09";
--            elsif(i_resolution = '0' and i_image_format = "10") then
--                init_packet(5) := x"07";
--            else
--                init_packet(4) := x"03";
--            end if;
            -- send the packet
            has_ack <= '1';
            packet_to_send <= init_packet;
            if(i_cmd_ack = '0') then
                current_state <= send_packet;
                return_state <= set_sleep;
            end if;
        when set_contrast =>
            case i_contrast is
                when "001" =>
                    v_contrast_packet(2) := x"00";
                when "010" =>
                    v_contrast_packet(2) := x"01";
                when "011" =>
                    v_contrast_packet(2) := x"02";
                when "100" =>
                    v_contrast_packet(2) := x"03";
                when "111" =>
                    v_contrast_packet(2) := x"04";
                when others =>
                    v_contrast_packet(2) := x"02";
            end case;
            case i_brightness is
                when "001" =>
                    v_contrast_packet(3) := x"00";
                when "010" =>
                    v_contrast_packet(3) := x"01";
                when "011" =>
                    v_contrast_packet(3) := x"02";
                when "100" =>
                    v_contrast_packet(3) := x"03";
                when "111" =>
                    v_contrast_packet(3) := x"04";
                when others =>
                    v_contrast_packet(3) := x"02";
            end case;
            case i_exposure is
                when "001" =>
                    v_contrast_packet(4) := x"00";
                when "010" =>
                    v_contrast_packet(4) := x"01";
                when "011" =>
                    v_contrast_packet(4) := x"02";
                when "100" =>
                    v_contrast_packet(4) := x"03";
                when "111" =>
                    v_contrast_packet(4) := x"04";
                when others =>
                    v_contrast_packet(4) := x"02";
            end case;
            -- send the packet
            byte_counter <= 0;
            has_ack <= '0';
            packet_to_send <= v_contrast_packet;
            if(i_cmd_ack = '0') then
                current_state <= send_packet;
                return_state <= set_light;
            end if;
        when set_light =>
            if(i_light = '0') then
                v_light_packet(2) := x"00";
            else
                v_light_packet(2) := x"01";
            end if;
            -- send the packet
            byte_counter <= 0;
            has_ack <= '0';
            packet_to_send <= v_light_packet;
            if(i_cmd_ack = '0') then
                current_state <= send_packet;
                return_state <= set_package;
            end if;
        when set_package =>
--            has_ack <= '1';
--            if(i_image_format = "10") then
--                v_package_size_packet(2) := x"08";
--                v_package_size_packet(4) := x"02";
--                byte_counter <= 0;
--                packet_to_send <= v_package_size_packet;
--                if(i_cmd_ack = '0') then
--                    current_state <= send_packet;
--                    return_state <= set_sleep;
--                end if;
--            else
--                current_state <= set_sleep;
--            end if;
            packet_to_send <= v_package_size_packet;
                if(i_cmd_ack = '0') then
                    current_state <= send_packet;
                    return_state <= set_sleep;
                end if;
        when set_sleep =>
            byte_counter <= 0;
            has_ack <= '0';
            packet_to_send <= sleep_packet;
            if(i_cmd_ack = '0') then
                current_state <= send_packet;
                return_state <= fin;
            end if;
        when send_packet =>
            o_cmd <= packet_to_send(byte_counter);
            o_cmd_ready <= '1';
            if(i_cmd_ack = '1') then
                o_cmd_ready <= '0';
                current_state <= wait_transmit;
            end if;
        when wait_transmit =>
            if(i_cmd_ack = '0') then
                byte_counter <= byte_counter + 1;
                if(byte_counter = 5) then
                        current_state <= wait_state;
                        wait_cnt <= 0;
                    byte_counter <= 0;
                else
                    current_state <= send_packet;
                end if;
            end if;
        when wait_state =>
            wait_cnt <= wait_cnt + 1;
            if(wait_cnt >= 10000000) then
                wait_cnt <= 0;
                current_state <= return_state;
                if(i_camera_rst = '1' and reset_loop = '0') then
                    current_state <= set_reset;
                end if;
            end if;
        when set_reset =>
            reset_loop <= '1';
            byte_counter <= 0;
            has_ack <= '0';
            packet_to_send <= reset_packet;
            if(i_cmd_ack = '0') then
                current_state <= send_packet;
                return_state <= init;
            end if;
        when get_resp =>
            if(i_camera_resp_syn = '1') then
                byte_counter <= byte_counter + 1;
                resp_packet(byte_counter) <= i_camera_resp;
                if(byte_counter = 5) then
                    byte_counter <= 0;
                    current_state <= interpet_resp;
                else
                    current_state <= wait_resp;
                end if;
            end if;
        when wait_resp =>
            if(i_camera_resp_syn = '0') then
                current_state <= get_resp;
            end if;
        when interpet_resp =>
            if(resp_packet(1) = ACK(1)) then
                -- ACK recieved. return to the next packet state.
                current_state <= return_state;
            else
                current_state <= fail_state;
            end if;
        when fail_state =>
            o_camera_init_err <= '1';
            if(i_camera_en = '0') then
                current_state <= init;
            end if;
        when fin =>
            o_camera_configured <= '1';
            if(i_camera_rst = '1') then
                current_state <= set_reset;
            end if;
            if(i_camera_en = '0') then
                current_state <= init;
            end if;
        when others =>
            current_state <= init;
            return_state <= init;
     end case FSM;
    end if;
end process main_proc;

end Behavioral;
