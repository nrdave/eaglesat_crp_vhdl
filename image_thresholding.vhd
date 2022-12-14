----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01/16/2020 10:37:08 AM
-- Design Name: 
-- Module Name: image_thresholding - Behavioral
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

entity image_thresholding is
  Port (i_clk : IN STD_LOGIC;
        i_camera_is_streaming : IN STD_LOGIC;
        i_img_resolution : IN STD_LOGIC;
        i_is_jpeg : IN STD_LOGIC;
        i_camera_en  : IN STD_LOGIC;
        i_uart_data_syn : IN STD_LOGIC;
        i_uart_data : IN STD_LOGIC_VECTOR(7 downto 0);
        i_fifo_full : IN STD_LOGIC;
        o_flux_count : OUT UNSIGNED(31 downto 0);
        o_capture_done : OUT STD_LOGIC;
        i_camera_reset : IN STD_LOGIC;
        o_reset_done : OUT STD_LOGIC;
        i_threshold_value : IN STD_LOGIC_VECTOR(7 downto 0);
        i_camera_id : IN STD_LOGIC_VECTOR(2 downto 0);
        o_packet_out : OUT STD_LOGIC_VECTOR(39 downto 0);
        o_packet_out_syn : OUT STD_LOGIC;
        i_packet_out_ack : IN STD_LOGIC
        
  );
end image_thresholding;

architecture Behavioral of image_thresholding is

constant BYTES_TO_SKIP : integer := 11;
signal byte_skip_cnt : integer range 0 to BYTES_TO_SKIP := 0;
signal flux_reset : STD_LOGIC := '0';
signal flux_count : INTEGER := 0;
signal flux_clk_count : INTEGER range 0 to 1000 := 0;
type state_type is (init, increment_skip, skip_wait_syn, data_wait_syn, get_data_byte, threshold_data, build_packet, send_packet,frame_done, ready);
signal current_state : state_type := init;
signal data_cnt_max : integer := 0;
signal data_cnt : integer := 0;
signal flux_reset_ack : STD_LOGIC := '0';
signal pixel_data : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
signal pixel_SB : STD_LOGIC := '1'; --1 for high, 0 for low
--constant threshold_value : STD_LOGIC_VECTOR(7 downto 0) := "00010000";
--constant camera_id : STD_LOGIC_VECTOR(2 downto 0) := "111";
signal frame_number : integer range 0 to 1023 := 0;
begin
o_flux_count <= to_unsigned(flux_count,32);
o_reset_done <= '1' when current_state = init else '0';
flux_proc : process(i_clk)
begin
    if(rising_edge(i_clk)) then
        
        if(flux_clk_count = 1000) then
            flux_reset <= '1';
            
            if(flux_reset_ack = '1') then
                flux_clk_count <= 0;
                flux_reset <= '0';
            end if;
            
        else 
            flux_clk_count <= flux_clk_count + 1;
        end if;
    end if;
    
end process flux_proc;

main_proc : process(i_clk)
begin
    if(rising_edge(i_clk)) then
        FSM : case current_state is
            when init =>
                byte_skip_cnt <= 0;
                pixel_SB <= '1';
                o_capture_done <= '0';
                data_cnt <= 0;
                frame_number <= 0;
                o_packet_out <= (others => '0');
                o_packet_out_syn <= '0';
                if(i_img_resolution = '1') then
                    -- 128x128
                    data_cnt_max <= 16383;
                else
                    if(i_is_jpeg = '0') then
                        -- 160x120
                        data_cnt_max <= 19199;
                    else
                        data_cnt_max <= 307199;
                    end if;
                end if;
                if(i_camera_is_streaming = '1') then
                    current_state <= increment_skip;
                end if;
            when increment_skip =>
                if(i_uart_data_syn = '1') then
                    current_state <= skip_wait_syn;
                end if;
            when skip_wait_syn =>
                if(i_uart_data_syn = '0') then
                    byte_skip_cnt <= byte_skip_cnt + 1;
                    if(byte_skip_cnt = BYTES_TO_SKIP) then
                        current_state <= get_data_byte;
                    else
                        current_state <= increment_skip;
                    end if;
                end if;
            when get_data_byte =>
                if(i_uart_data_syn = '1') then
--                    if(pixel_SB = '1') then
--                        pixel_data(15 downto 8) <= i_uart_data;
--                        pixel_SB <= '0';
--                        current_state <= data_wait_syn;
--                    else
                        pixel_data(7 downto 0) <= i_uart_data;
                        pixel_SB <= '1';
                        data_cnt <= data_cnt + 1;
                        current_state <= threshold_data;
                   -- end if;
                end if;
            when threshold_data =>
                if(i_camera_reset = '1') then
                    current_state <= init;
                end if;
                -- flux measurement
                if(pixel_data >= "00000000") then
                    if(flux_count < 255) then
                        flux_count <= flux_count + 1;
                    end if;
                    if(flux_reset = '1') then
                        flux_count <= 0;
                        flux_reset_ack <= '1';
                    else
                        flux_reset_ack <= '0';
                    end if;
                end if;
                if(pixel_data >= i_threshold_value) then
                    o_packet_out(2 downto 0) <= i_camera_id;
                    o_packet_out(10 downto 3) <= pixel_data;
                    o_packet_out(29 downto 11) <= std_logic_vector(to_unsigned(data_cnt,19));
                    o_packet_out(39 downto 30) <= std_logic_vector(to_unsigned(frame_number, 10));
                    o_packet_out_syn <= '1';
                    if(i_fifo_full = '0') then
                        current_state <= send_packet;
                    else
                        current_state <= data_wait_syn;
                    end if;
                else
                    if(data_cnt = 19199) then
                        current_state <= frame_done;
                        frame_number <= frame_number + 1;
                    else
                        current_state <= data_wait_syn;
                    end if;
                end if;
            when send_packet =>
                if(i_packet_out_ack = '1') then
                    o_packet_out_syn <= '0';
                    current_state <= data_wait_syn;
                end if;
            when data_wait_syn=>
                if(i_uart_data_syn = '0') then
                    current_state <= get_data_byte;
                end if;
            when frame_done =>
                o_capture_done <= '1';
                if(i_camera_en = '1') then
                    current_state <= ready;
                else 
                    current_state <= init;
                end if;
            when ready =>
                byte_skip_cnt <= 0;
                pixel_SB <= '1';
                o_capture_done <= '0';
                data_cnt <= 0;
                if(i_camera_reset = '1') then
                    current_state <= init;
                end if;
                o_packet_out <= (others => '0');
                o_packet_out_syn <= '0';
                if(i_camera_is_streaming = '1') then
                    current_state <= increment_skip;
                end if;
            when others =>
                current_state <= init;
        end case FSM;
    end if;
end process main_proc;
end Behavioral;
