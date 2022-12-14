----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/01/2020 12:43:02 PM
-- Design Name: 
-- Module Name: camera_uart_splitter - Behavioral
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity camera_uart_splitter is
  Port (clk : IN STD_LOGIC;
        i_splitter_en : IN STD_LOGIC;
        -- Configuration pass-through
        i_cam1_conf_tx : IN STD_LOGIC_VECTOR(7 downto 0);
        i_cam1_conf_tx_syn : IN STD_LOGIC;
        o_cam1_conf_tx_ack : OUT STD_LOGIC;
        i_cam2_conf_tx : IN STD_LOGIC_VECTOR(7 downto 0);
        i_cam2_conf_tx_syn : IN STD_LOGIC;
        o_cam2_conf_tx_ack : OUT STD_LOGIC;
        i_cam1_ready : IN STD_LOGIC;
        i_cam2_ready : IN STD_LOGIC;
        i_cam_tx : IN STD_LOGIC_VECTOR(7 downto 0);
        o_cameras_synced : OUT STD_LOGIC;
        i_cam_tx_syn : IN STD_LOGIC;
        o_cam_tx_ack : OUT STD_LOGIC;
        o_cam1_tx : OUT STD_LOGIC_VECTOR(7 downto 0);
        o_cam2_tx : OUT STD_LOGIC_VECTOR(7 downto 0);
        o_cam1_tx_syn : OUT STD_LOGIC;
        o_cam2_tx_syn : OUT STD_LOGIC;
        i_cam1_tx_ack : IN STD_LOGIC;
        i_cam2_tx_ack : IN STD_LOGIC
        
        );
end camera_uart_splitter;

architecture Behavioral of camera_uart_splitter is
type state_type is (configure, dataControl);
signal current_state : state_type := configure;
begin

process(clk)

begin
    if(rising_edge(clk)) then
        case current_state is
            when configure =>
                -- Pass the configuration signals through the crossbar
                o_cam1_tx <= i_cam1_conf_tx;
                o_cam1_tx_syn <= i_cam1_conf_tx_syn;
                o_cam1_conf_tx_ack <= i_cam1_tx_ack;
                o_cam2_tx <= i_cam2_conf_tx;
                o_cam2_tx_syn <= i_cam2_conf_tx_syn;
                o_cam2_conf_tx_ack <= i_cam2_tx_ack;
                o_cameras_synced <= '0';
                if(i_cam1_ready = '1' and i_cam2_ready = '1' and i_splitter_en = '1') then
                    current_state <= dataControl;
                end if;
            when dataControl =>
                o_cam1_tx_syn <= i_cam_tx_syn;
                o_cam1_tx <= i_cam_tx;
                o_cam2_tx_syn <= i_cam_tx_syn;
                o_cam2_tx <= i_cam_tx;
                o_cam_tx_ack <= i_cam1_tx_ack and i_cam2_tx_ack;
                o_cameras_synced <= '1';
                if(i_cam1_ready = '0' or i_cam2_ready = '0' or i_splitter_en = '0') then
                    current_state <= configure;
                end if;
            when others =>
                current_state <= configure;
        end case;
        
    end if;
end process;
--o_cam1_tx <= i_cam_tx when i_splitter_en = '1' else (others => '0');
--o_cam2_tx <= i_cam_tx when i_splitter_en = '1' else (others => '0');
--o_cam1_tx_syn <= i_cam_tx_syn when i_splitter_en = '1' else '0';
--o_cam2_tx_syn <= i_cam_tx_syn when i_splitter_en = '1' else '0';
--o_cam_tx_done <= i_cam1_tx_ack and i_cam2_tx_ack when i_splitter_en = '1' else '0';
end Behavioral;
