----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01/15/2020 12:27:49 PM
-- Design Name: 
-- Module Name: uart_multiplexer - Behavioral
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

entity uart_multiplexer is
Port (i_clk : IN STD_LOGIC;

      -- out to UART
      o_uart_syn : OUT STD_LOGIC;
      i_uart_ack : IN STD_LOGIC;
      o_uart_data : OUT STD_LOGIC_VECTOR(7 downto 0);
      
      -- SYNC
      i_sync_syn : IN STD_LOGIC;
      o_sync_ack : OUT STD_LOGIC;
      i_sync_data : IN STD_LOGIC_VECTOR(7 downto 0);
      
      -- CONFIG
      i_config_syn : IN STD_LOGIC;
      o_config_ack : OUT STD_LOGIC;
      i_config_data : IN STD_LOGIC_VECTOR(7 downto 0);
      
      -- STREAMING
      i_stream_syn : IN STD_LOGIC;
      o_stream_ack : OUT STD_LOGIC;
      i_stream_data : IN STD_LOGIC_VECTOR(7 downto 0);
      
      -- CONTROL SIGNALS
      i_camera_enable : IN STD_LOGIC;
      i_sync_done : IN STD_LOGIC;
      i_config_done : IN STD_LOGIC
);
end uart_multiplexer;

architecture Behavioral of uart_multiplexer is

begin
main_proc : process(i_clk)
begin
    
        if(rising_edge(i_clk)) then
            if(i_camera_enable = '1' and i_sync_done = '0') then
                o_uart_syn <= i_sync_syn;
                o_uart_data <= i_sync_data;
                o_sync_ack <= i_uart_ack;
            
            elsif(i_camera_enable = '1' and i_sync_done = '1' and i_config_done = '0') then
                o_uart_syn <= i_config_syn;
                o_uart_data <= i_config_data;
                o_config_ack <= i_uart_ack;
            elsif(i_camera_enable = '1' and i_sync_done = '1' and i_config_done = '1') then
                o_uart_syn <= i_stream_syn;
                o_uart_data <= i_stream_data;
                o_stream_ack <= i_uart_ack;
            end if;
        end if;
end process main_proc;

end Behavioral;
