----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/07/2020 10:51:29 AM
-- Design Name: 
-- Module Name: command_splitter - Behavioral
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

entity command_splitter is
  Port (clk : IN STD_LOGIC;
        i_rx_data_ready : IN STD_LOGIC;
        i_rx_data : IN STD_LOGIC_VECTOR(7 downto 0);
        o_cmd_data_ready_cam0 : OUT STD_LOGIC;
        o_cmd_data_cam0 : OUT STD_LOGIC_VECTOR(7 downto 0);
        
        o_cmd_data_ready_cam1 : OUT STD_LOGIC;
        o_cmd_data_cam1 : OUT STD_LOGIC_VECTOR(7 downto 0);
        
        o_cmd_data_ready_cam2 : OUT STD_LOGIC;
        o_cmd_data_cam2 : OUT STD_LOGIC_VECTOR(7 downto 0);
        
        o_cmd_data_ready_cam3 : OUT STD_LOGIC;
        o_cmd_data_cam3 : OUT STD_LOGIC_VECTOR(7 downto 0);
        
        o_cmd_data_ready_cam4 : OUT STD_LOGIC;
        o_cmd_data_cam4 : OUT STD_LOGIC_VECTOR(7 downto 0);
        
        o_cmd_data_ready_cam5 : OUT STD_LOGIC;
        o_cmd_data_cam5 : OUT STD_LOGIC_VECTOR(7 downto 0);
        
        o_cmd_data_ready_cam6 : OUT STD_LOGIC;
        o_cmd_data_cam6 : OUT STD_LOGIC_VECTOR(7 downto 0);
        
        o_cmd_data_ready_cam7 : OUT STD_LOGIC;
        o_cmd_data_cam7 : OUT STD_LOGIC_VECTOR(7 downto 0)
  );
end command_splitter;

architecture Behavioral of command_splitter is
constant cam0_suffix : STD_LOGIC_VECTOR(2 downto 0) := "000";
constant cam1_suffix : STD_LOGIC_VECTOR(2 downto 0) := "001";
constant cam2_suffix : STD_LOGIC_VECTOR(2 downto 0) := "010";
constant cam3_suffix : STD_LOGIC_VECTOR(2 downto 0) := "011";
constant cam4_suffix : STD_LOGIC_VECTOR(2 downto 0) := "100";
constant cam5_suffix : STD_LOGIC_VECTOR(2 downto 0) := "101";
constant cam6_suffix : STD_LOGIC_VECTOR(2 downto 0) := "110";
constant cam7_suffix : STD_LOGIC_VECTOR(2 downto 0) := "111";
signal received_data : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
signal output_channel : integer range 0 to 7 := 0;
signal out_data_readies : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
type state_type is (init, get_rx,send_rx);
signal current_state : state_type := init;
begin
process(clk)
begin
    if(rising_edge(clk)) then
        case current_state is
            when init=>
                o_cmd_data_ready_cam0 <= '0';
                o_cmd_data_cam0 <= (others => '0');
                o_cmd_data_ready_cam1 <= '0';
                o_cmd_data_cam1 <= (others => '0');
                o_cmd_data_ready_cam2 <= '0';
                o_cmd_data_cam2 <= (others => '0');
                o_cmd_data_ready_cam3 <= '0';
                o_cmd_data_cam3 <= (others => '0');
                o_cmd_data_ready_cam4 <= '0';
                o_cmd_data_cam4 <= (others => '0');
                o_cmd_data_ready_cam5 <= '0';
                o_cmd_data_cam5 <= (others => '0');
                o_cmd_data_ready_cam6 <= '0';
                o_cmd_data_cam6 <= (others => '0');
                o_cmd_data_ready_cam7 <= '0';
                o_cmd_data_cam7 <= (others => '0');
                if(i_rx_data_ready='1') then
                    current_state <= get_rx;
                    received_data <= i_rx_data;
                end if;
            when get_rx =>
                case received_data(7 downto 5) is
                    when cam0_suffix =>
                        o_cmd_data_ready_cam0 <= '1';
                        o_cmd_data_cam0(4 downto 0) <= received_data(4 downto 0);
                    when cam1_suffix =>
                        o_cmd_data_ready_cam1 <= '1';
                        o_cmd_data_cam1(4 downto 0) <= received_data(4 downto 0);
                    when cam2_suffix =>
                        o_cmd_data_ready_cam2 <= '1';
                        o_cmd_data_cam2(4 downto 0) <= received_data(4 downto 0);
                    when cam3_suffix =>
                        o_cmd_data_ready_cam3 <= '1';
                        o_cmd_data_cam3(4 downto 0) <= received_data(4 downto 0);
                    when cam4_suffix =>
                        o_cmd_data_ready_cam4 <= '1';
                        o_cmd_data_cam4(4 downto 0) <= received_data(4 downto 0);
                    when cam5_suffix =>
                        o_cmd_data_ready_cam5 <= '1';
                        o_cmd_data_cam5(4 downto 0) <= received_data(4 downto 0);
                    when cam6_suffix =>
                        o_cmd_data_ready_cam6 <= '1';
                        o_cmd_data_cam6(4 downto 0) <= received_data(4 downto 0);
                    when cam7_suffix =>
                        o_cmd_data_ready_cam7 <= '1';
                        o_cmd_data_cam7(4 downto 0) <= received_data(4 downto 0);
                    when others =>
                        current_state <= init;
                end case;
                current_state <= send_rx;
            when send_rx =>
                -- Pull data ready signals low so that data is only read once
                o_cmd_data_ready_cam0 <= '0';
                o_cmd_data_ready_cam1 <= '0';
                o_cmd_data_ready_cam2 <= '0';
                o_cmd_data_ready_cam3 <= '0';
                o_cmd_data_ready_cam4 <= '0';
                o_cmd_data_ready_cam5 <= '0';
                o_cmd_data_ready_cam6 <= '0';
                o_cmd_data_ready_cam7 <= '0';
                -- only get out of sending current data when UART input data changes
                -- Prevents commands from being sent multiple times
                if(i_rx_data_ready = '0') then
                    o_cmd_data_cam0 <= (others => '0');
                    o_cmd_data_cam1 <= (others => '0');
                    o_cmd_data_cam2 <= (others => '0');
                    o_cmd_data_cam3 <= (others => '0');
                    o_cmd_data_cam4 <= (others => '0');
                    o_cmd_data_cam5 <= (others => '0');
                    o_cmd_data_cam6 <= (others => '0');
                    o_cmd_data_cam7 <= (others => '0');
                    current_state <= init;
                end if;
            when others =>
                current_state <= init;
        end case;
    end if;
end process;

end Behavioral;
