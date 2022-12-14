----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/07/2020 11:17:13 AM
-- Design Name: 
-- Module Name: candDH_tx_combiner - Behavioral
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

entity candDH_tx_combiner is
  Port (clk : IN STD_LOGIC;
        -- UART signals
        i_uart_tx_data_ack : IN STD_LOGIC;
        o_uart_tx_data_ready : OUT STD_LOGIC;
        tx_data : OUT STD_LOGIC_VECTOR(7 downto 0);
        
        -- Camera 0 signals
        o_cam0_tx_data_ack : OUT STD_LOGIC;
        i_cam0_tx_data_ready : IN STD_LOGIC;
        i_cam0_tx_data : IN STD_LOGIC_VECTOR(7 downto 0);
        
        -- Camera 1 signals
        o_cam1_tx_data_ack : OUT STD_LOGIC;
        i_cam1_tx_data_ready : IN STD_LOGIC;
        i_cam1_tx_data : IN STD_LOGIC_VECTOR(7 downto 0);
        
        -- Camera 2 signals
        o_cam2_tx_data_ack : OUT STD_LOGIC;
        i_cam2_tx_data_ready : IN STD_LOGIC;
        i_cam2_tx_data : IN STD_LOGIC_VECTOR(7 downto 0);
        
        -- Camera 3 signals
        o_cam3_tx_data_ack : OUT STD_LOGIC;
        i_cam3_tx_data_ready : IN STD_LOGIC;
        i_cam3_tx_data : IN STD_LOGIC_VECTOR(7 downto 0);
        
        -- Camera 4 signals
        o_cam4_tx_data_ack : OUT STD_LOGIC;
        i_cam4_tx_data_ready : IN STD_LOGIC;
        i_cam4_tx_data : IN STD_LOGIC_VECTOR(7 downto 0);
        
        -- Camera 5 signals
        o_cam5_tx_data_ack : OUT STD_LOGIC;
        i_cam5_tx_data_ready : IN STD_LOGIC;
        i_cam5_tx_data : IN STD_LOGIC_VECTOR(7 downto 0);
        
        -- Camera 6 signals
        o_cam6_tx_data_ack : OUT STD_LOGIC;
        i_cam6_tx_data_ready : IN STD_LOGIC;
        i_cam6_tx_data : IN STD_LOGIC_VECTOR(7 downto 0);
        
        -- Camera 7 signals
        o_cam7_tx_data_ack : OUT STD_LOGIC;
        i_cam7_tx_data_ready : IN STD_LOGIC;
        i_cam7_tx_data : IN STD_LOGIC_VECTOR(7 downto 0));
end candDH_tx_combiner;

architecture Behavioral of candDH_tx_combiner is
--signal tx_data : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
signal current_channel : integer range 0 to 7 := 0;
signal out_data_acks : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
constant WAIT_CNT_MAX : integer := 2;
signal wait_cnt : integer range 0 to WAIT_CNT_MAX := 0;
type state_type is (init, send_data,wait_ack, wait_cdh);
signal current_state : state_type := init;
begin
o_cam0_tx_data_ack <= out_data_acks(0);
o_cam1_tx_data_ack <= out_data_acks(1);
o_cam2_tx_data_ack <= out_data_acks(2);
o_cam3_tx_data_ack <= out_data_acks(3);
o_cam4_tx_data_ack <= out_data_acks(4);
o_cam5_tx_data_ack <= out_data_acks(5);
o_cam6_tx_data_ack <= out_data_acks(6);
o_cam7_tx_data_ack <= out_data_acks(7);
process(clk)
begin
    if(rising_edge(clk)) then
        case current_state is
            when init =>
                o_uart_tx_data_ready <= '0';
                tx_data <= (others => '0');
                out_data_acks<= (others => '0');
                if(i_cam0_tx_data_ready='1') then
                    current_channel <= 0;
                    tx_data <= i_cam0_tx_data;
                    current_state <= send_data;
                elsif(i_cam1_tx_data_ready='1') then
                    current_channel <= 1;
                    tx_data <= i_cam1_tx_data;
                    current_state <= send_data;
                elsif(i_cam2_tx_data_ready='1') then
                    current_channel <= 2;
                    tx_data <= i_cam2_tx_data;
                    current_state <= send_data;
                elsif(i_cam3_tx_data_ready='1') then
                    current_channel <= 3;
                    tx_data <= i_cam3_tx_data;
                    current_state <= send_data;
                elsif(i_cam4_tx_data_ready='1') then
                    current_channel <= 4;
                    tx_data <= i_cam4_tx_data;
                    current_state <= send_data;
                elsif(i_cam5_tx_data_ready='1') then
                    current_channel <= 5;
                    tx_data <= i_cam5_tx_data;
                    current_state <= send_data;
                elsif(i_cam6_tx_data_ready='1') then
                    current_channel <= 6;
                    tx_data <= i_cam6_tx_data;
                    current_state <= send_data;
                elsif(i_cam7_tx_data_ready='1') then
                    current_channel <= 7;
                    tx_data <= i_cam7_tx_data;
                    current_state <= send_data;
                end if;
            when send_data =>
                if(i_uart_tx_data_ack='0') then
                    o_uart_tx_data_ready <= '1';
                    current_state <= wait_ack;
                end if;
            when wait_ack =>
                if(i_uart_tx_data_ack='1') then
                    out_data_acks(current_channel) <= '1';
                    current_state <= wait_cdh;
                end if;
            -- cAndDH needs a few clock cycles to 
            -- process the data acknowledgement,
            -- so the combiner waits 2 cycles after a 
            -- transmission is acknowledged
            when wait_cdh =>
                wait_cnt <= wait_cnt + 1;
                if(wait_cnt = WAIT_CNT_MAX) then
                    wait_cnt <= 0;
                    current_state <= init;
                end if;
            when others =>
                current_state <= init;
        
        end case;
        
    end if;
end process;

end Behavioral;
