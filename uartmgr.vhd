----------------------------------------------------------------------------------
-- Company: EagleSat 2
-- Engineer: Trevor Butcher - CRP
-- 
-- Create Date: 01/14/2020 09:08:56 AM
-- Design Name: 
-- Module Name: uartmgr - Behavioral
-- Project Name: Cosmic Ray payload
-- Target Devices: Cmod A7
-- Tool Versions: Vivado 2018.2
-- Description: 
-- This module manages UART transmissions to and from the ucam.
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

entity uartmgr is
  Port ( i_baudclk : IN STD_LOGIC; -- UART logic clock
        o_uart_tx : OUT STD_LOGIC := '1'; -- UART send
        i_uart_rx : IN STD_LOGIC; -- UART recieve
        o_rx_data_ready : OUT STD_LOGIC; -- Signal indicating that data has been received.
        o_rx_data : OUT STD_LOGIC_VECTOR(7 downto 0); -- signal containing received UART data
        i_tx_data_ready : IN STD_LOGIC; -- Signal indicating that data is ready to be read by this module
        i_tx_data : IN STD_LOGIC_VECTOR(7 downto 0); -- Signal containing data to be sent over UART
        o_tx_data_ack : OUT STD_LOGIC -- Signal indicating that the manager has acknowledged the incoming data. Is '0' when not busy.
  
  );
end uartmgr;

architecture Behavioral of uartmgr is

-- FSMs
type rx_state_type is (init, receive_data, send_data);
type tx_state_type is (init, send_data, transmit_wait);
signal rx_state : rx_state_type := init;
signal tx_state : tx_state_type := init;

-- Tx and Rx shift registers and counters
signal tx_shift_reg : STD_LOGIC_VECTOR(9 downto 0) := (others => '0');
signal rx_shift_reg : STD_LOGIC_VECTOR(9 downto 0) := (others => '0');
constant PACKET_SIZE :integer := 9;
constant WAIT_TIME : integer := 4;
signal tx_shift_cnt : integer range 0 to PACKET_SIZE := 0;
signal rx_shift_cnt : integer range 0 to PACKET_SIZE := 0;


begin

rx_proc: process(i_baudclk)
begin
    if(rising_edge(i_baudclk)) then
        rx_FSM : case rx_state is
            when init =>
                rx_shift_reg <= (others => '0');
                rx_shift_cnt <= 0;
                o_rx_data <= (others => '0');
                o_rx_data_ready <= '0';
                if(i_uart_rx = '0') then -- Falling edge trigger on start bit
                    rx_shift_cnt <= 1;
                    rx_state <= receive_data;
                end if;
            when receive_data =>
                rx_shift_reg(8) <= i_uart_rx;
                rx_shift_reg(7 downto 0) <= rx_shift_reg(8 downto 1);
                
                -- increment and check counter
                rx_shift_cnt <= rx_shift_cnt + 1;
                if(rx_shift_cnt = PACKET_SIZE) then
                    -- Transmission done
                    o_rx_data <= rx_shift_reg(8 downto 1);
                    o_rx_data_ready <= '1';
                    rx_state <= init;
                end if;
            when others =>
                rx_state <= init;
        end case rx_FSM;
    end if;
end process rx_proc;

-- TRANSMIT
tx_proc : process(i_baudclk)
begin
    if(rising_edge(i_baudclk)) then
        tx_FSM : case tx_state is
            when init =>
                o_uart_tx <= '1';
                o_tx_data_ack <= '0';
                tx_shift_reg <= (others => '0');
                tx_shift_cnt <= 0;
                if(i_tx_data_ready = '1') then
                    -- load shift registers
                    tx_shift_reg(0) <= '0';
                    tx_shift_reg(8 downto 1) <= i_tx_data;
                    tx_shift_reg(9) <= '1';
                    o_tx_data_ack <= '1';
                    tx_state <= send_data;
                end if;
            when send_data =>
                -- shift the register
                o_uart_tx <= tx_shift_reg(0);
                tx_shift_reg(8 downto 0) <= tx_shift_reg(9 downto 1);
                
                -- increment counter
                tx_shift_cnt <= tx_shift_cnt + 1;
                if(tx_shift_cnt = PACKET_SIZE) then
                    tx_state <= transmit_wait;
                    tx_shift_cnt <= 0;
                end if;
            when transmit_wait =>
                -- Wait 4 BAUD cycles, as per UART standard
                tx_shift_cnt <= tx_shift_cnt + 1;
                o_uart_tx <= '1';
                if(tx_shift_cnt = WAIT_TIME) then
                    tx_state <= init;
                end if;
            when others =>
            
                tx_state <= init;
        end case tx_FSM;
    end if;
end process tx_proc;
end Behavioral;
