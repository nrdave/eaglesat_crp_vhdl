----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01/15/2020 03:02:12 PM
-- Design Name: 
-- Module Name: image_capture - Behavioral
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

entity image_capture is
  Port (i_clk : IN STD_LOGIC; -- logic clock
        o_cmd_ready : OUT STD_LOGIC;
        o_cmd : OUT STD_LOGIC_VECTOR(7 downto 0);
        i_cmd_ack : IN STD_LOGIC;
        i_capture1_done : IN STD_LOGIC;
        i_capture2_done : IN STD_LOGIC;
        i_is_jpeg : IN STD_LOGIC;
        i_camera_rst : IN STD_LOGIC;
        i_fifo_full : IN STD_LOGIC;
        o_reset_done : OUT STD_LOGIC;
        i_camera_ready : IN STD_LOGIC;
        o_data_packet_syn : OUT STD_LOGIC;
        o_camera_is_streaming : OUT STD_LOGIC
  );
end image_capture;

architecture Behavioral of image_capture is
type packet_format is array(0 to 5) of STD_LOGIC_VECTOR(7 downto 0);
-- Packet initialization
signal packet_to_send : packet_format;
signal byte_counter : integer range 0 to 5 := 0;
signal get_picture_packet : packet_format := (x"aa",x"04",x"02",x"00",x"00",x"00");
signal snapshot_packet : packet_format := (x"aa",x"05",x"01",x"00",x"00",x"00");
signal resp_packet : packet_format;
type state_type is (init, send_snapshot, wait_fifo, wait_send, wait_for_ack_2, wait_for_ack, send_get_picture, wait_for_picture, send_packet, wait_transmit, get_resp, wait_resp, interpet_resp, fail_state, fin);
signal current_state : state_type := init;
signal return_state : state_type := init;
constant WAIT_MAX : integer := 50000;
signal wait_counter : integer range 0 to WAIT_MAX := 0;
constant ACK : packet_format := (x"aa",x"0E",x"00",x"00",x"00",x"00");
constant NAK : packet_format := (x"aa",x"0F",x"00",x"00",x"00",x"00");
begin
o_reset_done <= '1' when current_state = init else '0';
main_proc : process(i_clk)
begin
    if(rising_edge(i_clk)) then
        case current_state is
            when init =>
                o_cmd_ready <= '0';
                o_cmd <= (others => '0');
                o_camera_is_streaming <= '0';
                byte_counter <= 0;
                
--                if(i_is_jpeg = '0') then
--                    get_picture_packet(2) <= x"05";
--                    snapshot_packet(2) <= x"00";
--                else
--                    get_picture_packet(2) <= x"02";
--                    snapshot_packet(2) <= x"01";
--                end if;
                if(i_camera_ready = '1') then
                    current_state <= send_get_picture;
                end if; 
            when send_snapshot =>
                packet_to_send <= snapshot_packet;
                current_state <= send_packet;
                return_state <= wait_for_picture;
            when send_get_picture =>
                packet_to_send <= get_picture_packet;
                return_state <= wait_for_picture;
                current_state <= send_packet;
            when wait_for_ack =>
                wait_counter <= wait_counter + 1;
                if(wait_counter = WAIT_MAX) then
                    wait_counter <= 0;
                    current_state <= send_snapshot;
                end if;
            when wait_for_picture =>
                o_camera_is_streaming <= '1';
                if(i_capture1_done = '1' and i_capture2_done = '1') then
                    packet_to_send <= ACK;
                    current_state <= send_packet;
                    return_state <= wait_fifo;
                    wait_counter <= 0;
                end if;
            when wait_fifo =>
                if(i_fifo_full = '0') then
                    wait_counter <= wait_counter + 1;
                    if(wait_counter = WAIT_MAX) then
                        wait_counter <= 0;
                        current_state <= init;
                    end if;

                end if;
            when send_packet =>
                o_cmd <= packet_to_send(byte_counter);
                o_cmd_ready <= '1';
                if(i_cmd_ack = '1') then
                    o_cmd_ready <= '0';
                    current_state <= wait_transmit;
                end if;
            when wait_send =>
                wait_counter <= wait_counter + 1;
                if(wait_counter = 10000) then
                    wait_counter <= 0;
                    if(i_camera_rst = '1') then
                        current_state <= init;
                    end if;
                    current_state <= return_state;
                end if;
                
            when wait_transmit =>
                if(i_cmd_ack = '0') then
                    byte_counter <= byte_counter + 1;
                    if(byte_counter = 5) then
                        current_state <= wait_send;
                        byte_counter <= 0;
                    else
                        current_state <= send_packet;
                    end if;
                end if; 
            when others =>
                current_state <= init;
        end case;
    end if; 
    
end process;
end Behavioral;
